import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/services/language_service.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    );
  }

  Widget _buildNavItem(int index, String icon, String iconbold, String label) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: SizedBox(
        height: 45.h,
        width: 60.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              isSelected ? iconbold : icon,
              height: 24.h,
              width: 24.w,
              color: isSelected ? AppColors.primary : AppColors.textGrey,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.subheading.copyWith(
                fontSize: 10.sp,
                color: isSelected ? AppColors.primary : AppColors.textGrey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
