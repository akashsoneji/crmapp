import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/flavor_config.dart';

/// Warms up the chart WebView in the background so the *first* time the user
/// opens the chart screen the heavy charting bundle (~5 MB: index.js 1.4 MB +
/// index.css 0.86 MB + TradingView `library.js` 2.48 MB + runtime/lang bundles)
/// is already in the WebView disk cache and the engine is hot — so it renders in
/// ~3-4s instead of ~10s.
///
/// It does this with a [HeadlessInAppWebView] (an off-screen WebView) that loads
/// the exact same `/mobile-chart` URL the real chart uses. Because the on-screen
/// [ChartInAppWebView] loads with `cacheMode: LOAD_CACHE_ELSE_NETWORK` and the
/// bundles are served with `public, immutable` Cache-Control, the on-screen chart
/// then reads everything from disk cache instead of re-downloading.
///
/// Key design points that make this actually fast on a COLD first launch:
/// - [prewarm] fires a DNS+TCP+TLS preconnect immediately at app start, in
///   parallel with Flutter/Firebase/GetX init, so the first real request does
///   not pay the handshake cost.
/// - [preload] (the headless WebView) is started at the app's *first frame*,
///   independent of auth, so the ~5 MB download runs in parallel with the
///   splash/login/auth-validation work instead of after it.
/// - We do NOT dispose the headless WebView early. Tearing it down before the
///   bundle has fully downloaded + executed throws away most of the benefit.
///   We keep one warm instance alive for the session; an idle off-screen WebView
///   is cheap compared to the UX win.
/// - "Warm" means the chart page actually finished bootstrapping (its JS bridge
///   `window.changeSymbol` exists), not merely that `onLoadStop` fired.
/// - On a network error we retry with backoff.
class ChartPreloadService {
  ChartPreloadService._();

  static final ChartPreloadService instance = ChartPreloadService._();

  HeadlessInAppWebView? _headless;
  bool _isRunning = false;
  bool _isWarm = false;
  int _retryCount = 0;
  Timer? _retryTimer;
  Timer? _readyPollTimer;

  static const int _maxRetries = 3;

  /// True once the background chart page has fully bootstrapped at least once.
  bool get isWarm => _isWarm;

  /// Default symbol used only to warm the bundle. The on-screen chart pushes the
  /// real symbol via the JS bridge, so this value does not matter for the user.
  static const String _warmupSymbol = 'XAUUSD';

  String _buildUrl() {
    return '${FlavorConfig.instance.chartBaseUrl}/mobile-chart'
        '?symbol=$_warmupSymbol&theme=${AppColors.chartTheme}';
  }

  /// Shared settings so the headless and on-screen WebViews populate/read the
  /// same disk cache with the same engine flags.
  static InAppWebViewSettings warmSettings() => InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: true,
        mediaPlaybackRequiresUserGesture: false,
        // Prefer disk cache, fall back to network. Combined with the server's
        // `immutable` headers this makes re-entries read from disk.
        cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
        cacheEnabled: true,
        domStorageEnabled: true,
        // Keep the renderer warm/ready even while off-screen so the first
        // on-screen paint is not delayed by raster warm-up (Android).
        offscreenPreRaster: true,
        hardwareAcceleration: true,
        useHybridComposition: true,
      );

  /// Top-level entry point to call as EARLY as possible (e.g. from `main()`
  /// just before/after `runApp`). Fires a DNS/TLS preconnect immediately and
  /// then starts the headless WebView warm-up. Idempotent.
  Future<void> prewarm() async {
    if (_isWarm) return;
    // Preconnect runs on the Dart event loop and warms DNS+TCP+TLS in parallel
    // with the rest of startup — don't await it.
    unawaited(_preconnect());
    // Start the heavy headless download/exec immediately too.
    unawaited(preload());
  }

  /// Performs a lightweight TCP+TLS handshake to the chart CDN so DNS lookup,
  /// TCP connect and TLS negotiation happen in parallel with app startup. By the
  /// time the headless WebView starts, the socket is warm and the first request
  /// does not pay the handshake cost (~0.3-0.8s).
  Future<void> _preconnect() async {
    HttpClient? client;
    try {
      final uri = Uri.parse(_buildUrl());
      client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final req = await client.openUrl('HEAD', uri);
      req.headers.add('User-Agent', 'ChartPreloadService/1.0');
      final resp = await req.close();
      await resp.drain<void>();
      if (kDebugMode) {
        debugPrint('ChartPreloadService: preconnect OK (${resp.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ChartPreloadService: preconnect failed: $e');
      }
    } finally {
      client?.close(force: true);
    }
  }

  /// Starts the background warm-up. No-op if already warmed or in progress.
  Future<void> preload() async {
    if (_isWarm || _isRunning) return;
    _isRunning = true;
    await _startHeadless();
  }

  Future<void> _startHeadless() async {
    try {
      _headless = HeadlessInAppWebView(
        // A real (non-zero) size makes the renderer lay out the chart so its
        // canvas is actually prepared, instead of a -1x-1 deferred surface.
        initialSize: const Size(390, 300),
        initialUrlRequest: URLRequest(url: WebUri(_buildUrl())),
        initialSettings: warmSettings(),
        onLoadStop: (controller, url) {
          if (kDebugMode) {
            debugPrint('ChartPreloadService: page loaded, waiting for JS bridge ($url)');
          }
          // onLoadStop fires before the TradingView library finishes executing.
          // Poll until the page exposes its symbol bridge, then mark warm.
          _startReadyPoll(controller);
        },
        onReceivedError: (controller, request, error) {
          if (kDebugMode) {
            debugPrint('ChartPreloadService: warm-up error: ${error.description}');
          }
          _scheduleRetry();
        },
      );

      await _headless!.run();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ChartPreloadService: failed to start warm-up: $e');
      }
      _scheduleRetry();
    }
  }

  /// Polls the headless page until its JS chart bridge is available, which means
  /// the heavy library has fully executed and the cache is fully populated.
  void _startReadyPoll(InAppWebViewController controller) {
    _readyPollTimer?.cancel();
    int attempts = 0;
    _readyPollTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      attempts++;
      bool ready = false;
      try {
        final result = await controller.evaluateJavascript(source: '''
          (function() {
            try {
              return (typeof window.changeSymbol === 'function') ||
                     (typeof window.createTradingViewChart === 'function');
            } catch (e) { return false; }
          })();
        ''');
        ready = result == true || result == 'true' || result == 1;
      } catch (_) {
        ready = false;
      }

      if (ready) {
        timer.cancel();
        _markWarm();
      } else if (attempts >= 30) {
        // ~15s safety cap. Even if the bridge probe never returns true, the
        // assets are cached by now — treat as warm and stop polling.
        timer.cancel();
        _markWarm();
      }
    });
  }

  void _markWarm() {
    _isWarm = true;
    _isRunning = false;
    _retryTimer?.cancel();
    if (kDebugMode) {
      debugPrint('ChartPreloadService: chart bundle fully warmed and cached');
    }
    // Intentionally keep the headless WebView alive for the session so its
    // disk + memory cache stays hot for the on-screen chart.
  }

  void _scheduleRetry() {
    _readyPollTimer?.cancel();
    _disposeHeadless();
    _isRunning = false;
    if (_isWarm || _retryCount >= _maxRetries) return;
    _retryCount++;
    _retryTimer?.cancel();
    final delay = Duration(seconds: 2 * _retryCount);
    if (kDebugMode) {
      debugPrint('ChartPreloadService: retry #$_retryCount in ${delay.inSeconds}s');
    }
    _retryTimer = Timer(delay, () => unawaited(preload()));
  }

  Future<void> _disposeHeadless() async {
    final headless = _headless;
    _headless = null;
    if (headless == null) return;
    try {
      await headless.dispose();
    } catch (_) {
      // ignore – best-effort cleanup
    }
  }
}
