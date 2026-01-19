import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/services/app_status/app_status_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Force update dialog widget
/// Shows when app version doesn't match API version
class ForceUpdateDialog extends StatelessWidget {
  const ForceUpdateDialog({super.key});

  /// Build app logo widget - uses logo.svg
  Widget _buildAppLogo() {
    final logoPath = FlavorConfig.instance.svgLogoPath;

    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Center(
        child: SvgPicture.asset(
          logoPath,
          width: 100.w,
          height: 100.w,
          fit: BoxFit.contain,
          placeholderBuilder:
              (context) =>
                  Icon(Icons.apps, size: 100.w, color: AppColors.primary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppStatusController>();

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      contentPadding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
      content: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Logo
              _buildAppLogo(),
              SizedBox(height: 24.h),

              // Title
              Text(
                'Update Required',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Message
              Text(
                "You're going to have to update app",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.openAppStore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Update Now',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Close button (X icon) in top right corner
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              onPressed: () {
                // Close the dialog (it will reappear on next check if update still required)
                Get.back();
              },
              icon: Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 24.w,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
