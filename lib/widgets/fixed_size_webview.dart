import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/widgets/common_loading_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FixedSizeWebView extends StatefulWidget {
  final String url;

  const FixedSizeWebView({required this.url, super.key});

  @override
  State<FixedSizeWebView> createState() => _FixedSizeWebViewState();
}

class _FixedSizeWebViewState extends State<FixedSizeWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final navigationDelegate = WebViewUtils.getOptimizedNavigationDelegate(
      onPageStarted: () {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      },
      onPageFinished: () {
        setState(() {
          _isLoading = false;
        });
      },
      onError: () {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      },
    );

    _controller = WebViewUtils.createOptimizedController(
      url: widget.url,
      navigationDelegate: navigationDelegate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: 490.h,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.h, color: Colors.grey),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load chart',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 42.h,
                      width: 120.w,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _isLoading = true;
                          });
                          _initializeWebView();
                        },
                        style: OutlinedButton.styleFrom(
                          // padding: EdgeInsets.symmetric(vertical: 16.h),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
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

class WebViewUtils {
  /// Creates optimized NavigationDelegate with error handling
  static NavigationDelegate getOptimizedNavigationDelegate({
    required VoidCallback onPageStarted,
    required VoidCallback onPageFinished,
    required VoidCallback onError,
  }) {
    return NavigationDelegate(
      onPageStarted: (String url) {
        onPageStarted();
      },
      onPageFinished: (String url) {
        onPageFinished();
      },
      onWebResourceError: (WebResourceError error) {
        onError();
      },
      // Prevent navigation to external URLs
      onNavigationRequest: (NavigationRequest request) {
        // Only allow navigation to the original URL or relative paths
        if (request.url.startsWith('http') &&
            !request.url.contains('my.pipze.com')) {
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    );
  }

  /// Creates a WebViewController with optimized settings
  static WebViewController createOptimizedController({
    required String url,
    required NavigationDelegate navigationDelegate,
  }) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setNavigationDelegate(navigationDelegate)
      ..loadRequest(Uri.parse(url));
  }
}
