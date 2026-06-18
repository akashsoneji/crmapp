import 'dart:async';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChartInAppWebView extends StatefulWidget {
  /// Stable base URL — does NOT include ?symbol= so it never changes per symbol
  /// switch. Symbol is updated via JavaScript to avoid full page reloads.
  final String url;

  /// The symbol to display. Updated via JS (updateSymbol) — no page reload.
  final String symbol;

  const ChartInAppWebView({super.key, required this.url, required this.symbol});

  @override
  State<ChartInAppWebView> createState() => ChartInAppWebViewState();
}

class ChartInAppWebViewState extends State<ChartInAppWebView> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isReady = false;
  Timer? _loadingTimeout;

  /// Symbol requested while the WebView wasn't ready yet.
  /// Applied immediately after onLoadStop fires.
  String? _pendingSymbol;

  @override
  void initState() {
    super.initState();
    _startLoadingTimeout();
  }

  @override
  void didUpdateWidget(covariant ChartInAppWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // URL changed (e.g. broker switch) → full reload required
    if (oldWidget.url != widget.url) {
      _isReady = false;
      _hasError = false;
      _isLoading = true;
      _pendingSymbol = widget.symbol;
      _startLoadingTimeout();
      _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
      return;
    }

    // Symbol changed — NEVER reload the page.
    // ✅ If chart is ready → instant JS update (zero blink).
    // ✅ If chart is still loading → queue it; applied in onLoadStop.
    if (oldWidget.symbol != widget.symbol) {
      if (_isReady) {
        unawaited(updateSymbol(widget.symbol));
      } else {
        // Queue — will be applied as soon as onLoadStop fires
        _pendingSymbol = widget.symbol;
      }
    }
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    super.dispose();
  }

  void _startLoadingTimeout() {
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      if (_isReady) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    });
  }

  /// Update chart symbol via JavaScript — no page reload, no blink.
  Future<void> updateSymbol(String symbol) async {
    if (_controller == null) return;
    if (!_isReady) {
      _pendingSymbol = symbol;
      return;
    }

    final String chartSymbol =
        symbol.contains('.') ? symbol.substring(0, symbol.lastIndexOf('.')) : symbol;

    if (chartSymbol.isEmpty) return;

    try {
      await _controller!.evaluateJavascript(source: '''
        (function() {
          try {
            if (typeof selectedSymbol !== 'undefined') {
              selectedSymbol = "$chartSymbol";
            }
            if (typeof updateSymbol === 'function') {
              updateSymbol("$chartSymbol");
              return true;
            }
            if (typeof createTradingViewChart === 'function') {
              createTradingViewChart("$chartSymbol");
              return true;
            }
          } catch (e) {}
          return false;
        })();
      ''');
    } catch (_) {
      // JS bridge error is non-fatal — chart still shows previous symbol
    }
  }

  Future<void> updateNativeTrades(String tradesJson) async {
    if (_controller == null) return;
    if (!_isReady) return;

    try {
      await _controller!.evaluateJavascript(source: '''
        (function() {
          try {
            if (typeof updateNativeTrades === 'function') {
              updateNativeTrades($tradesJson);
              return true;
            }
          } catch (e) {}
          return false;
        })();
      ''');
    } catch (_) {
      // ignore – chart still usable
    }
  }

  Future<void> _retry() async {
    if (_controller == null) return;
    setState(() {
      _hasError = false;
      _isLoading = true;
      _isReady = false;
    });
    _startLoadingTimeout();
    await _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // ✅ WebView always rendered — never hidden via opacity/offstage.
          // Loading overlay sits on top; Android renderer starts immediately.
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              transparentBackground: true,
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              cacheEnabled: true,
              cacheMode: CacheMode.LOAD_DEFAULT,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            shouldOverrideUrlLoading: (controller, action) async {
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStart: (controller, url) {
              if (!mounted) return;
              setState(() {
                _isLoading = true;
                _hasError = false;
                _isReady = false;
              });
            },
            onLoadStop: (controller, url) async {
              if (!mounted) return;
              _loadingTimeout?.cancel();
              setState(() {
                _isLoading = false;
                _hasError = false;
                _isReady = true;
              });

              // Apply any symbol that was set before/during page load.
              // Use _pendingSymbol if queued, else current widget symbol.
              final symbolToApply = _pendingSymbol ?? widget.symbol;
              _pendingSymbol = null;
              unawaited(updateSymbol(symbolToApply));
            },
            onReceivedError: (controller, request, error) {
              if (!mounted) return;
              if (request.isForMainFrame == true) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                  _isReady = false;
                });
              }
            },
            onRenderProcessGone: (controller, detail) async {
              if (!mounted) return;
              if (kDebugMode) debugPrint('Chart WebView renderer died: $detail');
              setState(() {
                _hasError = true;
                _isLoading = false;
                _isReady = false;
              });
            },
          ),

          // Loading overlay — shown only during initial load or broker URL change.
          // Symbol switches do NOT trigger this (JS update, no reload).
          if (_isLoading && !_hasError)
            Container(
              color: AppColors.tradeBackgroundCenterColor,
              child: Center(
                child: CommonLoadingWidget(
                  size: 40.0,
                  color: AppColors.primary,
                ),
              ),
            ),

          // Error state
          if (_hasError)
            Container(
              color: AppColors.tradeBackgroundCenterColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.signal_wifi_off_rounded,
                      size: 48.h,
                      color: AppColors.textGrey,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Chart unavailable',
                      style: AppTextStyles.subheading
                          .copyWith(color: AppColors.textGrey),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 42.h,
                      width: 140.w,
                      child: OutlinedButton(
                        onPressed: _retry,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.whiteColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
