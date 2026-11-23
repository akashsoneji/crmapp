import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/widgets/home/instrument_trade_card.dart';

/// Card under the chart in the new design that groups the quantity row
/// (stepper + action buttons) and the SELL/BUY tiles.
class ChartTradeDockNew extends StatelessWidget {
  final List<Widget> children;

  const ChartTradeDockNew({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsetsDirectional.only(start: 8.w, end: 8.w, top: 6.h),
      padding: EdgeInsetsDirectional.only(top: 6.h, bottom: 10.h),
      decoration: BoxDecoration(
        color: AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.chartDockShadow,
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// SELL / BUY tile: tinted fill with a gradient border that is solid accent
/// on the outer edge and fades towards the spread chip. Purely visual: the
/// chart screen keeps the tap handler, so order placement is unchanged.
class ChartTradeTileNew extends StatelessWidget {
  final bool isSell;
  final String price;
  final bool isBusy;

  const ChartTradeTileNew({
    super.key,
    required this.isSell,
    required this.price,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSell ? AppColors.chartSellAccent : AppColors.chartBuyAccent;
    final tint = isSell ? AppColors.chartSellTint : AppColors.chartBuyTint;
    final (body, highlight) = homeSplitPrice(price);
    const borderWidth = 1.5;
    // The outer bottom corner is the strongest point of the border.
    final outerCorner =
        isSell ? AlignmentDirectional.bottomStart : AlignmentDirectional.bottomEnd;
    final innerCorner =
        isSell ? AlignmentDirectional.topEnd : AlignmentDirectional.topStart;

    return Semantics(
      button: true,
      label: '${isSell ? 'SELL' : 'BUY'} $price',
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: isBusy ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(borderWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: LinearGradient(
              begin: outerCorner,
              end: innerCorner,
              colors: [accent, accent.withValues(alpha: 0.2)],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            // Grows with large text instead of clipping the price.
            constraints: BoxConstraints(minHeight: 48.h),
            // The inner side leaves room for the spread chip on the gap.
            padding: EdgeInsetsDirectional.only(
              start: isSell ? 12.w : 22.w,
              end: isSell ? 22.w : 12.w,
              top: 4.h,
              bottom: 4.h,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r - borderWidth),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tint, AppColors.chartTileFillEnd],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  isSell ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(
                  isSell ? 'SELL' : 'BUY',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGrey,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: body),
                      TextSpan(
                        text: highlight,
                        style: TextStyle(
                          color: accent,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Spread chip that sits on the gap between the SELL and BUY tiles.
class ChartSpreadChipNew extends StatelessWidget {
  final String spread;

  const ChartSpreadChipNew({super.key, required this.spread});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Spread $spread',
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minWidth: 40.w),
        padding: EdgeInsetsDirectional.symmetric(horizontal: 6.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.chartSpreadChipBackground,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.chartDockShadow,
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          spread,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Round −/+ button inside the quantity pill.
class ChartQuantityButtonNew extends StatelessWidget {
  final bool isIncrement;
  final VoidCallback onPressed;

  const ChartQuantityButtonNew({
    super.key,
    required this.isIncrement,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isIncrement ? 'Increase quantity' : 'Decrease quantity',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 22.r,
        child: SizedBox(
          width: 44.r,
          height: 44.r,
          child: Center(
            child: Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                color: AppColors.chartPillButtonBackground,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.chartDockShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                isIncrement ? Icons.add : Icons.remove,
                size: 18.r,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three compact buttons next to the quantity pill: pending order (SL/TP),
/// price alerts and fullscreen chart. Each shows an icon over a short label.
class ChartTradeActionsNew extends StatelessWidget {
  final String pendingLabel;
  final VoidCallback onPendingTap;
  final VoidCallback onAlertsTap;
  final VoidCallback onFullscreenTap;

  const ChartTradeActionsNew({
    super.key,
    this.pendingLabel = 'Pending',
    required this.onPendingTap,
    required this.onAlertsTap,
    required this.onFullscreenTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          label: pendingLabel,
          semanticsLabel: 'Pending order, stop loss and take profit',
          icon: Icons.schedule_rounded,
          onTap: onPendingTap,
          isPrimary: true,
        ),
        SizedBox(width: 6.w),
        _ActionButton(
          label: 'Alerts',
          semanticsLabel: 'Price alerts',
          icon: Icons.notifications_rounded,
          onTap: onAlertsTap,
          showDot: true,
        ),
        SizedBox(width: 6.w),
        _ActionButton(
          label: 'Expand',
          semanticsLabel: 'Full screen chart',
          icon: Icons.fullscreen_rounded,
          onTap: onFullscreenTap,
        ),
      ],
    );
  }
}

/// Icon-over-label button. The primary one is filled with the brand
/// gradient; the others use the quantity pill's background.
class _ActionButton extends StatelessWidget {
  final String label;
  final String semanticsLabel;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool showDot;

  const _ActionButton({
    required this.label,
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        isPrimary ? AppColors.onColoredBackground : AppColors.homeIconTint;
    final radius = BorderRadius.circular(12.r);
    // At large accessibility text sizes three captions no longer fit beside
    // the quantity pill; fall back to icons (the semantics label stays).
    final showCaption = MediaQuery.textScalerOf(context).scale(1) <= 1.3;

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: isPrimary ? null : AppColors.chartPillBackground,
            gradient:
                isPrimary
                    ? LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [
                        AppColors.homeHeaderGradientStart,
                        AppColors.homeHeaderGradientEnd,
                      ],
                    )
                    : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              constraints: BoxConstraints(minWidth: 48.w, minHeight: 44.h),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: 4.w,
                vertical: 4.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: 18.r, color: foreground),
                      if (showDot)
                        PositionedDirectional(
                          top: 0,
                          end: 0,
                          child: Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: const BoxDecoration(
                              color: AppColors.homeAlertDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (showCaption) ...[
                    SizedBox(height: 2.h),
                    Text(
                      label,
                      maxLines: 1,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
