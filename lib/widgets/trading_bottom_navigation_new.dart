import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/services/language_service.dart';

class _NavTab {
  final String iconAsset;
  final String labelKey;
  final String fallbackLabel;

  const _NavTab(this.iconAsset, this.labelKey, this.fallbackLabel);
}

/// Docked bottom tab bar: full width, rounded top corners, sits on the
/// bottom safe-area inset. Icons are the two-tone `new_svg` set, tinted
/// active / inactive (their 40% layer is kept).
class TradingBottomNavigationNew extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const TradingBottomNavigationNew({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const String _iconDir = 'assets/svg/new_svg';

  static const List<_NavTab> _tabs = [
    _NavTab('$_iconDir/home-trend-up.svg', 'nav_home', 'Home'),
    _NavTab('$_iconDir/chart.svg', 'nav_markets', 'Markets'),
    _NavTab('$_iconDir/candle.svg', 'nav_positions', 'Positions'),
    _NavTab('$_iconDir/moneys.svg', 'dashboard_title', 'Dashboard'),
    _NavTab('$_iconDir/empty-wallet.svg', 'setting_title', 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    // Obx: labels follow a language switch.
    return Obx(() {
      languageService.currentLanguage.value;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.homeNavBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      iconAsset: _tabs[i].iconAsset,
                      label: languageService.trf(
                        _tabs[i].labelKey,
                        _tabs[i].fallbackLabel,
                      ),
                      isSelected: currentIndex == i,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconAsset,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.homeNavActive
        : AppColors.homeNavInactive;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconAsset,
                  width: 24.r,
                  height: 24.r,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                SizedBox(height: 4.h),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 11.sp,
                    color: color,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
