import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';

class IbBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const IbBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    0,
                    "assets/svg/ib_dashboard/dashboard.svg",
                    "assets/svg/ib_dashboard/dashboard_bold.svg",
                    "Dashboard",
                  ),
                  _buildNavItem(
                    1,
                    "assets/svg/ib_dashboard/myclient.svg",
                    "assets/svg/ib_dashboard/myclient_bold.svg",
                    "My Clients",
                  ),
                  _buildNavItem(
                    2,
                    "assets/svg/ib_dashboard/coin.svg",
                    "assets/svg/ib_dashboard/coin_bold.svg",
                    "Commission",
                  ),
                  _buildNavItem(
                    3,
                    "assets/svg/ib_dashboard/marketing.svg",
                    "assets/svg/ib_dashboard/marketing_bold.svg",
                    "Marketing",
                  ),
                  _buildNavItem(
                    4,
                    "assets/svg/bottom_navigation/setting.svg",
                    "assets/svg/bottom_navigation/setting_bold.svg",
                    "More",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String icon, String iconbold, String label) {
    final isSelected = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(50.r),
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 26.w : 10.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              isSelected ? iconbold : icon,
              height: isSelected ? 22.h : 18.h,
              width: isSelected ? 22.w : 18.w,
              color: isSelected ? AppColors.primary : AppColors.textGrey,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.subheading.copyWith(
                fontSize: 11.sp,
                color: isSelected ? AppColors.primary : AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
