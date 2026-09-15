import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/services/language_service.dart';

import '../routes/app_pages.dart';

class KycScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final VoidCallback? onClose;

  const KycScaffold({Key? key, required this.body, this.title, this.onClose})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable back navigation
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
          scrolledUnderElevation: 0,
          elevation: 0,
          automaticallyImplyLeading: false, // No back arrow
          title: Text(
            title ?? Get.find<LanguageService>().tr('verify_your_account'),
            style: AppTextStyles.heading,
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Container(
                width: 28.w,
                height: 28.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textGrey.withAlpha(30),
                ),
                child: Icon(
                  Icons.close,
                  size: 18.w,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: onClose ?? _showExitConfirmation,
            ),
          ],
          shape: Border(bottom: BorderSide(color: AppColors.textGrey)),
        ),
        body: body,
      ),
    );
  }

  void _showExitConfirmation() {
    Get.dialog(
      ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(Get.context!).size.width * 0.9,
          maxHeight: MediaQuery.of(Get.context!).size.height * 0.6,
        ),
        child: AlertDialog(
          backgroundColor: AppColors.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: GestureDetector(
                  onTap: () => Get.back(closeOverlays: true),
                  child: Container(
                    width: 28.w,
                    height: 28.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textGrey.withAlpha(30),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18.w,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              SvgPicture.asset(
                'assets/svg/kyc/personalcard.svg',
                height: 60.h,
                width: 60.w,
                color: AppColors.primary,
              ),
              SizedBox(height: 20.h, width: 20.w),
              Text(
                Get.find<LanguageService>().tr('navigation_skip'),
                style: AppTextStyles.black16600,
              ),
            ],
          ),
          content: Text(
            Get.find<LanguageService>().tr('common_skip_for_now'),
            style: AppTextStyles.grey14400h57,
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              // Removed mainAxisAlignment: MainAxisAlignment.spaceBetween to avoid overflow
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Get.back(closeOverlays: true); // Close dialog
                      // Get.offAllNamed('/more'); // Navigate to more screen
                      Get.offAllNamed(Routes.TRADING);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary.withAlpha(
                        20,
                      ), // Light purple
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      Get.find<LanguageService>().tr('navigation_skip'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(closeOverlays: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, // Light purple
                      foregroundColor: AppColors.whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      elevation: 0,
                    ),
                    child: Text(
                      textAlign: TextAlign.center,
                      Get.find<LanguageService>().tr('navigation_continue'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Exit button (left) - light purple background, dark purple text
          ],
        ),
      ),
    );
  }
}
