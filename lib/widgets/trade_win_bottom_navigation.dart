import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/screens/trade_win/trade_win_theme.dart';
import 'package:crm_app/services/language_service.dart';

class TradeWinBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TradeWinBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(
                  color: AppColors.icongrey.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _item(0, Icons.home_outlined, Icons.home, languageService.tr('tw_nav_home')),
                  _item(1, Icons.emoji_events_outlined, Icons.emoji_events, languageService.tr('tw_nav_leaderboard')),
                  _item(2, Icons.military_tech_outlined, Icons.military_tech, languageService.tr('tw_nav_my_wins')),
                  _item(3, Icons.person_outline, Icons.person, languageService.tr('tw_nav_profile')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, IconData activeIcon, String label) {
    final selected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color: selected ? TradeWinTheme.accentFill : Colors.transparent,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                size: 22.sp,
                color: selected
                    ? TradeWinTheme.onAccentFill
                    : AppColors.textGrey,
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subheading.copyWith(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? TradeWinTheme.onAccentFill
                      : AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
