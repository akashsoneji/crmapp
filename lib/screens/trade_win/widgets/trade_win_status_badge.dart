import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/screens/trade_win/trade_win_theme.dart';

class TradeWinStatusBadge extends StatelessWidget {
  final String status;

  const TradeWinStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: TradeWinTheme.accentFill,
        borderRadius: BorderRadius.circular(20.r),
        border: AppColors.isDarkMode
            ? Border.all(color: Colors.white.withValues(alpha: 0.15))
            : null,
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.subheading.copyWith(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: TradeWinTheme.onAccentFill,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
