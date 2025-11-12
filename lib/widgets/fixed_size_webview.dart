// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:pipze/constants/color.dart';
// import 'package:pipze/constants/text_styles.dart';
// import 'package:pipze/widgets/common_loading_widget.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class FixedSizeWebView extends StatefulWidget {
//   final String url;

//   const FixedSizeWebView({required this.url, super.key});

//   @override
//   State<FixedSizeWebView> createState() => _FixedSizeWebViewState();
// }

// class _FixedSizeWebViewState extends State<FixedSizeWebView> {
//   late final WebViewController _controller;
//   bool _isLoading = true;
//   bool _hasError = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeWebView();
//   }

//   void _initializeWebView() {
//     final navigationDelegate = WebViewUtils.getOptimizedNavigationDelegate(
//       onPageStarted: () {
//         setState(() {
//           _isLoading = true;
//           _hasError = false;
//         });
//       },
//       onPageFinished: () {
//         setState(() {
//           _isLoading = false;
//         });
//       },
//       onError: () {
//         setState(() {
//           _hasError = true;
//           _isLoading = false;
//         });
//       },
//     );

//     _controller = WebViewUtils.createOptimizedController(
//       url: widget.url,
//       navigationDelegate: navigationDelegate,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.maxFinite,
//       height: 490.h,
//       child: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (_isLoading)
//             Container(
//               width: double.maxFinite,
//               height: 490.h,
//               color: Colors.white,
//               child: const Center(child: OverlayLoadingWidget()),
//             ),
//           if (_hasError)
//             Container(
//               width: double.maxFinite,
//               height: 490.h,
//               color: Colors.white,
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.error_outline, size: 48.h, color: Colors.grey),
//                     SizedBox(height: 16.h),
//                     Text(
//                       'Failed to load chart',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     SizedBox(height: 8.h),
//                     SizedBox(
//                       height: 42.h,
//                       width: 120.w,
//                       child: OutlinedButton(
//                         onPressed: () {
//                           setState(() {
//                             _hasError = false;
//                             _isLoading = true;
//                           });
//                           _initializeWebView();
//                         },
//                         style: OutlinedButton.styleFrom(
//                           // padding: EdgeInsets.symmetric(vertical: 16.h),
//                           backgroundColor: AppColors.primary,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8.r),
//                           ),
//                         ),
//                         child: Text(
//                           'Retry',
//                           style: AppTextStyles.label.copyWith(
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.whiteColor,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class WebViewUtils {
//   /// Creates optimized NavigationDelegate with error handling
//   static NavigationDelegate getOptimizedNavigationDelegate({
//     required VoidCallback onPageStarted,
//     required VoidCallback onPageFinished,
//     required VoidCallback onError,
//   }) {
//     return NavigationDelegate(
//       onPageStarted: (String url) {
//         onPageStarted();
//       },
//       onPageFinished: (String url) {
//         onPageFinished();
//       },
//       onWebResourceError: (WebResourceError error) {
//         onError();
//       },
//       // Prevent navigation to external URLs
//       onNavigationRequest: (NavigationRequest request) {
//         // Only allow navigation to the original URL or relative paths
//         if (request.url.startsWith('http') &&
//             !request.url.contains('my.pipze.com')) {
//           return NavigationDecision.prevent;
//         }
//         return NavigationDecision.navigate;
//       },
//     );
//   }

//   /// Creates a WebViewController with optimized settings
//   static WebViewController createOptimizedController({
//     required String url,
//     required NavigationDelegate navigationDelegate,
//   }) {
//     return WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(Colors.white)
//       ..enableZoom(false)
//       ..setNavigationDelegate(navigationDelegate)
//       ..loadRequest(Uri.parse(url));
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/widgets/common_loading_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // For rootBundle


class FixedSizeWebView extends StatefulWidget {
  final String url;
  final String symbol;

  const FixedSizeWebView({required this.url, required this.symbol, super.key});

  @override
  State<FixedSizeWebView> createState() => _FixedSizeWebViewState();
}

class FallbackChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.grey[200]!.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw grid lines
    for (int i = 0; i <= 10; i++) {
      final y = (size.height / 10) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (int i = 0; i <= 8; i++) {
      final x = (size.width / 8) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw a simple candlestick pattern
    final candleWidth = size.width * 0.08;
    final candleSpacing = size.width * 0.1;

    for (int i = 0; i < 6; i++) {
      final x = candleSpacing + (i * candleSpacing);
      final open = size.height * 0.3 + (i * 20);
      final close = size.height * 0.4 + (i * 15);
      final high = size.height * 0.2 + (i * 10);
      final low = size.height * 0.5 + (i * 25);

      final bodyHeight = (close - open).abs();
      final bodyTop = open < close ? open : close;

      canvas.drawRect(
        Rect.fromLTWH(x - candleWidth / 2, bodyTop, candleWidth, bodyHeight),
        fillPaint,
      );

      canvas.drawLine(Offset(x, high), Offset(x, low), paint);
    }

    final trendPaint = Paint()
      ..color = Colors.blue[300]!.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.3),
      trendPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _FixedSizeWebViewState extends State<FixedSizeWebView>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isWebViewReady = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _timeoutTimer;
  Timer? _healthCheckTimer;
  bool _wasVisible = true;
  String? _cachedUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebView();
  }

  @override
  void didUpdateWidget(FixedSizeWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      // URL changed, reinitialize WebView
      _retryCount = 0; // Reset retry count for new URL
      _initializeWebView();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeoutTimer?.cancel();
    _healthCheckTimer?.cancel();
    _controller?.clearCache();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed - checking WebView state');
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        print('App paused - saving WebView state');
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        break;
      case AppLifecycleState.detached:
        print('App detached');
        break;
      case AppLifecycleState.hidden:
        print('App hidden');
        break;
    }
  }

  void _handleAppPaused() {
    _wasVisible = false;
    _cachedUrl = widget.url; // Cache current URL for faster recovery
    print('App paused - caching URL: $_cachedUrl');
    // Don't clear the WebView when app goes to background
    // Just mark that it was paused
  }

  void _handleAppResumed() {
    if (!_wasVisible && mounted) {
      print('App resumed from background - fast recovery');
      _wasVisible = true;

      // Show loading immediately for better UX
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Immediate check without delay for faster recovery
      if (_controller != null && _isWebViewReady) {
        // Try instant refresh first (fastest option)
        _instantRefresh();
      } else {
        // If WebView is not ready, reinitialize quickly
        print('WebView not ready, quick reinitializing...');
        _retryCount = 0;
        _quickInitializeWebView();
      }
    }
  }

  void _instantRefresh() async {
    try {
      if (_controller != null) {
        print('Instant WebView refresh');
        // Use JavaScript to refresh only the chart content without full page reload
        await _controller!.runJavaScript('''
          if (typeof window.location !== 'undefined') {
            // Try to refresh chart data without full reload
            if (typeof refreshChart === 'function') {
              refreshChart();
            } else if (typeof window.chart !== 'undefined' && window.chart.refresh) {
              window.chart.refresh();
            } else {
              // Fallback to location reload
              window.location.reload();
            }
          }
        ''');

        // Hide loading after successful refresh
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isWebViewReady = true;
          });
        }
      }
    } catch (e) {
      print('Instant refresh failed, using fallback: $e');
      _refreshWebView();
    }
  }

  void _refreshWebView() async {
    try {
      if (_controller != null) {
        print('Refreshing WebView content');
        await _controller!.reload();
      }
    } catch (e) {
      print('Error refreshing WebView: $e');
      // If refresh fails, reinitialize
      _retryCount = 0;
      _initializeWebView();
    }
  }

  // Add a method to check WebView health
  void _checkWebViewHealth() async {
    if (_controller != null && _isWebViewReady) {
      try {
        // Try to evaluate a simple JavaScript to check if WebView is responsive
        final result = await _controller!.runJavaScriptReturningResult(
          'document.readyState',
        );
        print('WebView health check result: $result');

        // If the result indicates an error, refresh the WebView
        if (result.toString().contains('error') || result.toString().isEmpty) {
          print('WebView appears unhealthy, refreshing...');
          _refreshWebView();
        }
      } catch (e) {
        print('WebView health check failed: $e');
        // If health check fails, reinitialize
        _retryCount = 0;
        _initializeWebView();
      }
    }
  }

  void _quickInitializeWebView() async {
    try {
      print('Quick WebView initialization');
      _timeoutTimer?.cancel();

      // Skip connectivity checks for faster initialization
      // Platform-specific WebView initialization
      if (Platform.isAndroid) {
        await WebViewPlatform.instance;
      }

      final navigationDelegate = WebViewUtils.getOptimizedNavigationDelegate(
        onPageStarted: () {
          if (mounted) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            // Shorter timeout for quick init
            _startQuickTimeoutTimer();
          }
        },
        onPageFinished: () {
          if (mounted) {
            _timeoutTimer?.cancel();
            setState(() {
              _isLoading = false;
              _isWebViewReady = true;
              _retryCount = 0;
            });
            _startHealthCheckTimer();
          }
        },
        onError: () {
          if (mounted) {
            _timeoutTimer?.cancel();
            _handleWebViewError();
          }
        },
      );

      _controller = WebViewUtils.createFastRecoveryController(
        url: widget.url,
        navigationDelegate: navigationDelegate,
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Quick WebView initialization error: $e');
      _timeoutTimer?.cancel();
      if (mounted) {
        _handleWebViewError();
      }
    }
  }

  void _initializeWebView() async {
    try {
      // Cancel any existing timeout timer
      _timeoutTimer?.cancel();

      // Platform-specific WebView initialization
      if (Platform.isAndroid) {
        await WebViewPlatform.instance;
      }

      final navigationDelegate = WebViewUtils.getOptimizedNavigationDelegate(
        onPageStarted: () {
          if (mounted) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            // Start timeout timer (15 seconds)
            _startTimeoutTimer();
          }
        },
        onPageFinished: () async {
          if (mounted) {
            _timeoutTimer?.cancel();
            setState(() {
              _isLoading = false;
              _isWebViewReady = true;
              _retryCount = 0; // Reset retry count on success
            });
            // Start periodic health check
            _startHealthCheckTimer();
          }
        },
        onError: () {
          if (mounted) {
            _timeoutTimer?.cancel();
            _handleWebViewError();
          }
        },
      );

      // Load the local HTML asset as a string and inject the symbol
      final rawHtml = await rootBundle.loadString('assets/chart/index.html');
      // Replace the placeholder with the dynamic symbol
      final modifiedHtml = rawHtml.replaceFirst(
        RegExp(r'let selectedSymbol\s*=\s*".*?";'),
        'let selectedSymbol = "${widget.symbol}";',
      );

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..enableZoom(false)
        ..setNavigationDelegate(navigationDelegate)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
        )
        ..setBackgroundColor(Colors.transparent);

      if (Platform.isAndroid) {
        controller
          ..enableZoom(false)
          ..setBackgroundColor(Colors.transparent);
      }

      await controller.loadHtmlString(modifiedHtml);

      _controller = controller;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('WebView initialization error: $e');
      _timeoutTimer?.cancel();
      if (mounted) {
        _handleWebViewError();
      }
    }
  }

  /// Public method to update the symbol dynamically at runtime.
  void updateSymbol(String newSymbol) async {
    print('updateSymbol called with: $newSymbol');
    try {
      await _controller?.runJavaScript('updateSymbol("$newSymbol");');
      print('updateSymbol JavaScript command sent successfully.');

      // Verify that the value is updated in HTML
      final result = await _controller?.runJavaScriptReturningResult('selectedSymbol');
      print('HTML verification - selectedSymbol = $result');
    } catch (e) {
      print('Error while sending or verifying symbol in HTML: $e');
    }
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        print('WebView loading timeout');
        _handleWebViewError();
      }
    });
  }

  void _startQuickTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        print('Quick WebView loading timeout');
        _handleWebViewError();
      }
    });
  }

  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _isWebViewReady && _wasVisible) {
        _checkWebViewHealth();
      }
    });
  }

  void _handleWebViewError() {
    if (mounted) {
      _healthCheckTimer?.cancel();
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isWebViewReady = false;
      });
    }
  }

  void _retryLoading() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      print('Retrying WebView load (attempt $_retryCount/$_maxRetries)');

      if (mounted) {
        setState(() {
          _hasError = false;
          _isLoading = true;
          _isWebViewReady = false;
        });

        // Clear cache and retry
        _controller?.clearCache();
        _initializeWebView();
      }
    } else {
      print('Max retry attempts reached');
    }
  }

  Widget _buildFallbackChart() {
    return Container(
      width: double.maxFinite,
      height: 490.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.grey[100]!],
        ),
      ),
      child: CustomPaint(
        painter: FallbackChartPainter(),
        size: Size(double.maxFinite, 490.h),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: 490.h,
      child: Stack(
        children: [
          if (_controller != null && _isWebViewReady)
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // This helps detect if the widget is still visible
                return false;
              },
              child: WebViewWidget(controller: _controller!),
            ),
          if (_isLoading)
            Container(
              width: double.maxFinite,
              height: 490.h,
              color: Colors.white,
              child: const Center(child: OverlayLoadingWidget()),
            ),
          if (_hasError)
            Container(
              width: double.maxFinite,
              height: 490.h,
              color: Colors.white,
              child: Stack(
                children: [
                  // Fallback chart background
                  _buildFallbackChart(),
                  // Error overlay
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48.h,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _retryCount == 0
                                ? 'Failed to load chart'
                                : 'Chart loading failed',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Check your internet connection',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (_retryCount > 0) ...[
                            SizedBox(height: 8.h),
                            Text(
                              'Attempt $_retryCount/$_maxRetries',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                          SizedBox(height: 16.h),
                          SizedBox(
                            height: 42.h,
                            width: 120.w,
                            child: OutlinedButton(
                              onPressed:
                                  _retryCount < _maxRetries
                                      ? _retryLoading
                                      : null,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                _retryCount < _maxRetries
                                    ? 'Retry'
                                    : 'Max Retries Reached',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _retryCount < _maxRetries
                                          ? AppColors.whiteColor
                                          : Colors.grey,
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
            ),
        ],
      ),
    );
  }
}

class WebViewUtils {
  /// Creates optimized NavigationDelegate with error handling
  static NavigationDelegate getOptimizedNavigationDelegate({
    required VoidCallback onPageStarted,
    required VoidCallback onPageFinished,
    required VoidCallback onError,
  }) {
    return NavigationDelegate(
      onPageStarted: (String url) {
        print('WebView page started loading: $url');
        onPageStarted();
      },
      onPageFinished: (String url) {
        print('WebView page finished loading: $url');
        onPageFinished();
      },
      onWebResourceError: (WebResourceError error) {
        print(
          'WebView resource error: ${error.description} (Code: ${error.errorCode})',
        );
        print('Error URL: ${error.url}');
        onError();
      },
      onNavigationRequest: (NavigationRequest request) {
        print('WebView navigation request: ${request.url}');
        // Only allow navigation to the original URL or relative paths
        if (request.url.startsWith('http') &&
            !request.url.contains('my.pipze.com')) {
          print('Blocking external navigation to: ${request.url}');
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      onUrlChange: (UrlChange change) {
        print('WebView URL changed: ${change.url}');
      },
    );
  }

  /// Creates a WebViewController with optimized settings
  static WebViewController createOptimizedController({
    required String url,
    required NavigationDelegate navigationDelegate,
  }) {
    final controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..enableZoom(false)
          ..setNavigationDelegate(navigationDelegate)
          ..setUserAgent(
            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          )
          ..setBackgroundColor(Colors.transparent);

    // Add platform-specific optimizations
    if (Platform.isAndroid) {
      controller
        ..enableZoom(false)
        ..setBackgroundColor(Colors.transparent);
    }

    // Load the URL
    try {
      controller.loadRequest(Uri.parse(url));
    } catch (e) {
      print('Error parsing URL: $url - $e');
      throw Exception('Invalid URL: $url');
    }

    return controller;
  }

  /// Creates a WebViewController with fast recovery settings
  static WebViewController createFastRecoveryController({
    required String url,
    required NavigationDelegate navigationDelegate,
  }) {
    final controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent)
          ..enableZoom(false)
          ..setNavigationDelegate(navigationDelegate)
          ..setUserAgent(
            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          );

    // Load the URL immediately without additional checks
    try {
      controller.loadRequest(Uri.parse(url));
    } catch (e) {
      print('Error parsing URL for fast recovery: $url - $e');
      throw Exception('Invalid URL: $url');
    }

    return controller;
  }

  /// Creates a WebViewController that loads a local HTML asset
  static WebViewController createOptimizedControllerFromAsset({
    required String assetPath,
    required NavigationDelegate navigationDelegate,
  }) {
    final controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..enableZoom(false)
          ..setNavigationDelegate(navigationDelegate)
          ..setUserAgent(
            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          )
          ..setBackgroundColor(Colors.transparent);

    if (Platform.isAndroid) {
      controller
        ..enableZoom(false)
        ..setBackgroundColor(Colors.transparent);
    }

    // Load the local HTML asset
    try {
      controller.loadFlutterAsset(assetPath);
    } catch (e) {
      print('Error loading local asset: $assetPath - $e');
      throw Exception('Invalid asset: $assetPath');
    }

    return controller;
  }

  /// Check network connectivity by making a simple HTTP request
  static Future<bool> checkConnectivity() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://www.google.com'),
            headers: {'Connection': 'close'},
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Connectivity check failed: $e');
      return false;
    }
  }

  /// Check if the specific URL is reachable
  static Future<bool> checkUrlReachability(String url) async {
    try {
      final response = await http
          .head(Uri.parse(url), headers: {'Connection': 'close'})
          .timeout(const Duration(seconds: 10));
      return response.statusCode < 400;
    } catch (e) {
      print('URL reachability check failed for $url: $e');
      return false;
    }
  }
}
