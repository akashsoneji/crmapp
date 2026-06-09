import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/services/language_service.dart';

class TradeWinBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TradeWinBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(
      inactiveAsset: 'assets/svg/more/home.svg',
      activeAsset: 'assets/svg/more/home_selected.svg',
      labelKey: 'tw_nav_home',
    ),
    _NavItem(
      inactiveAsset: 'assets/svg/more/leaderboard.svg',
      activeAsset: 'assets/svg/more/leaderboard_selected.svg',
      labelKey: 'tw_nav_leaderboard',
    ),
    _NavItem(
      inactiveAsset: 'assets/svg/more/my_wins.svg',
      activeAsset: 'assets/svg/more/my_wins_selected.svg',
      labelKey: 'tw_nav_my_wins',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: AppColors.isDarkMode ? 0.22 : 0.15),
                blurRadius: 22,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
                ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  _items.length,
                  (index) => _buildItem(
                    index: index,
                    item: _items[index],
                    label: languageService.tr(_items[index].labelKey),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildItem({
    required int index,
    required _NavItem item,
    required String label,
  }) {
    final selected = currentIndex == index;
    final inactiveColor = AppColors.textGrey;
    final activeColor =
        AppColors.isDarkMode ? AppColors.textPrimary : AppColors.primary;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.primary.withValues(
                      alpha: AppColors.isDarkMode ? 0.15 : 0.12,
                    )
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                selected ? item.activeAsset : item.inactiveAsset,
                height: 22.h,
                width: 22.w,
                colorFilter: ColorFilter.mode(
                  selected ? activeColor : inactiveColor,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subheading.copyWith(
                  fontSize: 10.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String inactiveAsset;
  final String activeAsset;
  final String labelKey;

  const _NavItem({
    required this.inactiveAsset,
    required this.activeAsset,
    required this.labelKey,
  });
}
