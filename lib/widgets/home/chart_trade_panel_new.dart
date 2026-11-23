import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/widgets/home/instrument_trade_card.dart';

/// SELL / BUY tile of the chart tab in the new design. Purely visual: the
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
    final accent = isSell ? AppColors.error : AppColors.success;
    final (body, highlight) = homeSplitPrice(price);
    final alignment =
        isSell ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    return Semantics(
      button: true,
      label: '${isSell ? 'SELL' : 'BUY'} $price',
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: isBusy ? 0.5 : 1.0,
        child: Container(
          // Grows with large text instead of clipping the price.
          constraints: BoxConstraints(minHeight: 60.h),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: 14.w,
            vertical: 6.h,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isSell
                    ? AppColors.homeSellBoxBackground
                    : AppColors.homeBuyBoxBackground,
                AppColors.homeCardBackground,
              ],
            ),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color:
                  isSell
                      ? AppColors.homeSellBoxBorder
                      : AppColors.homeBuyBoxBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: alignment,
            children: [
              Text(
                isSell ? 'SELL' : 'BUY',
                style: AppTextStyles.label.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White spread chip that sits between the SELL and BUY tiles.
class ChartSpreadChipNew extends StatelessWidget {
  final String spread;

  const ChartSpreadChipNew({super.key, required this.spread});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(minWidth: 52.w),
      height: 28.h,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(6.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(spread, style: AppTextStyles.labelOnTradeDifference),
    );
  }
}

/// Grey round −/+ button of the quantity card in the new design.
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
                color: AppColors.homeQuantityButtonBackground,
                shape: BoxShape.circle,
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

/// "Pending order • SL • TP" bar with the price-alert bell on its end side.
class ChartPendingBarNew extends StatelessWidget {
  final String label;
  final VoidCallback onPendingTap;
  final VoidCallback onAlertsTap;

  const ChartPendingBarNew({
    super.key,
    required this.label,
    required this.onPendingTap,
    required this.onAlertsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      padding: EdgeInsetsDirectional.only(start: 16.w, end: 6.w),
      decoration: BoxDecoration(
        color: AppColors.homePendingBarBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: label,
              excludeSemantics: true,
              child: InkWell(
                onTap: onPendingTap,
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  height: 56.h,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _AlertButton(onTap: onAlertsTap),
        ],
      ),
    );
  }
}

class _AlertButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AlertButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Price alerts',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                AppColors.homeHeaderGradientStart,
                AppColors.homeHeaderGradientEnd,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications,
                size: 24.r,
                color: AppColors.onColoredBackground,
              ),
              PositionedDirectional(
                top: 8.r,
                end: 9.r,
                child: Container(
                  width: 9.r,
                  height: 9.r,
                  decoration: const BoxDecoration(
                    color: AppColors.homeAlertDot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
