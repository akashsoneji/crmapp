import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/screens/trade_win/trade_win_theme.dart';

class TradeWinRedeemStepper extends StatelessWidget {
  final int currentStep;

  const TradeWinRedeemStepper({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final step = index + 1;
        final isActive = step == currentStep;
        final isDone = step < currentStep;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isDone
                      ? TradeWinTheme.accentFillStrong
                      : AppColors.icongrey.withValues(alpha: 0.25),
                  border: (isActive || isDone) && AppColors.isDarkMode
                      ? Border.all(color: Colors.white.withValues(alpha: 0.25))
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$step',
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isActive || isDone
                        ? TradeWinTheme.onAccentFill
                        : AppColors.textGrey,
                  ),
                ),
              ),
              if (index < 2)
                Expanded(
                  child: Container(
                    height: 2.h,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    color: step < currentStep
                        ? TradeWinTheme.onAccentFill.withValues(alpha: 0.5)
                        : AppColors.icongrey.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
