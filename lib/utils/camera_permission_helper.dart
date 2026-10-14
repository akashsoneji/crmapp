import 'package:crm_app/constants/color.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionHelper {
  /// Returns true when camera access is granted/limited. Otherwise shows a
  /// dialog offering to open device settings and returns false.
  static Future<bool> checkAndRequestCameraPermission({
    String? customMessage,
  }) async {
    PermissionStatus status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) {
      return true;
    }

    await showPermissionSettingsDialog(message: customMessage);
    return false;
  }

  static Future<bool> showPermissionSettingsDialog({
    String? title,
    String? message,
  }) async {
    final String resolvedTitle =
        title ??
        TranslationUtils.trf(
          'camera_permission_required',
          'Camera Permission Required',
        );
    final String resolvedMessage =
        message ??
        TranslationUtils.trf(
          'camera_permission_denied_message',
          'Camera access is required to take photos. Please allow camera access in device settings.',
        );
    final String confirmText = TranslationUtils.trf(
      'open_settings',
      'Open Settings',
    );
    final String cancelText = TranslationUtils.trf(
      'account_management_cancel',
      'Cancel',
    );

    final result = await Get.dialog<bool>(
      Dialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primary,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      resolvedTitle,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text(
                resolvedMessage,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.45,
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () {
                      Get.back(result: true);
                      openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );

    return result ?? false;
  }
}
