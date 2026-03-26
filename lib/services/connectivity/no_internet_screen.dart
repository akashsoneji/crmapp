import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/services/connectivity/connectivity_controller.dart';

/// Full-screen "No Internet" overlay shown when device loses connectivity.
/// Auto-dismisses when internet connection is restored.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConnectivityController>();

    return Container(
      color: AppColors.whiteColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // No Internet Icon
              Container(
                width: 280.w,
                height: 280.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // color: AppColors.primary.withOpacity(0.1),
                ),
                child: SvgPicture.asset(
                  'assets/svg/no-internet.svg',
                  fit: BoxFit.cover,
                ),
                
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                'No Internet!',
                style: AppTextStyles.headingblack,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),

              // Message
              Text(
                'Please check your connection and try again',
                style: TextStyle(
                  fontSize: 11.45.sp,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.h),

            
              const Spacer(flex: 3),

               // Refresh / Retry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.refresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 0.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: AppColors.whiteColor,
                        size: 22.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
