import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/core/config/flavor_config.dart';

import 'package:crm_app/core/services/app_status/app_status_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Force update dialog widget
/// Shows when app version doesn't match API version
class ForceUpdateDialog extends StatelessWidget {
  final bool isForceUpdate;

  const ForceUpdateDialog({super.key, required this.isForceUpdate});

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

    // Full screen dialog
    return WillPopScope(
      onWillPop: () async {
        // For force update, prevent closing
        return !isForceUpdate;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              _buildAppLogo(),
              SizedBox(height: 32.h),

              // Title
              Text(
                'Update Required',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),

              // Message
              Text(
                "You're going to have to update app",
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.h),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.openAppStore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
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

              // Skip for now button (only show if not force update)
              if (!isForceUpdate) ...[
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Save skip timestamp and close dialog
                      controller.skipUpdateFor24Hours();
                      Get.back();
                      controller.resetForceUpdateDialogFlag();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
