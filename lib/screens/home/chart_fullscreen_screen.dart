import 'package:crm_app/constants/color.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/widgets/app_svg_back_button.dart';
import 'package:crm_app/widgets/chart_inapp_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Fullscreen chart route that loads the existing remote TradingView
/// widget (`/mobile-chart`) via [ChartInAppWebView].
///
/// Reached from the chart screen's "Full chart" floating action button when
/// the user wants the paid TradingView experience (every indicator, drawing
/// tool, depth-of-market widget) instead of the default native chart.
///
/// The back button returns the user to the previous screen, at which point
/// the [LiveCandleAggregator] resumes ticking (handled by the caller).
class ChartFullscreenScreen extends StatelessWidget {
  /// The datafeed symbol passed in by the chart screen (with `.c`/`.r`
  /// suffix already resolved). Falls back to XAUUSD if missing.
  final String symbol;

  /// Optional pre-resolved theme override (dark/light).
  final String? theme;

  const ChartFullscreenScreen({
    super.key,
    this.symbol = 'XAUUSD',
    this.theme,
  });

  /// Helper for the caller to build the chart URL the same way the existing
  /// chart screen does (so we never diverge).
  static String buildUrl(String datafeedSymbol, String chartTheme) {
    return '${FlavorConfig.instance.chartBaseUrl}/mobile-chart?symbol=$datafeedSymbol&theme=$chartTheme';
  }

  @override
  Widget build(BuildContext context) {
    // Read arguments passed via Get.toNamed. The constructor defaults are
    // only used if the screen is opened without arguments (e.g. via deep link
    // or test harness).
    final args = (Get.arguments is Map) ? Get.arguments as Map : const {};
    final resolvedSymbol = (args['symbol'] as String?) ?? symbol;
    final resolvedTheme = (args['theme'] as String?) ?? theme ?? AppColors.chartTheme;
    final url = buildUrl(resolvedSymbol, resolvedTheme);

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.cardBackGround,
        elevation: 0,
        title: Text(
          resolvedSymbol,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: AppSvgBackButton(
          onPressed: () => Get.back(closeOverlays: true),
          iconWidth: 30.w,
          iconHeight: 30.h,
        ),
      ),
      body: SafeArea(
        child: ChartInAppWebView(
          key: ValueKey('fullscreen_$resolvedSymbol'),
          symbol: resolvedSymbol,
          url: url,
        ),
      ),
    );
  }
}