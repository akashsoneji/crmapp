import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';

class KycScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final VoidCallback? onClose;

  const KycScaffold({Key? key, required this.body, this.title, this.onClose})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back navigation
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          automaticallyImplyLeading: false, // No back arrow
          title: Text(
            title ?? 'Verify your account',
            style: AppTextStyles.heading,
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Container(
                width: 24.w,
                height: 24.h,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textPrimary),
                ),
                child: Icon(
                  Icons.close,
                  size: 20.w,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: onClose ?? _showExitConfirmation,
            ),
          ],
          shape: Border(bottom: BorderSide(color: AppColors.grey)),
        ),
        body: body,
      ),
    );
  }

  void _showExitConfirmation() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.icongrey),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16.w,
                    color: AppColors.icongrey,
                  ),
                ),
              ),
            ),
            SizedBox(height: 80.h, width: 80.w),
            Text('Exit Verification', style: AppTextStyles.black16600),

            // Close icon (X) in top-right corner
          ],
        ),
        content: Text(
          'You continue later, but you won\'t get all benefits until verification is complete',
          style: AppTextStyles.grey14400h57,
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(Get.context!).size.width * 0.3,
                child: TextButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.offAllNamed('/more'); // Navigate to more screen
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
                    'Exit',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Continue button (right) - solid dark purple background, white text
              SizedBox(
                width: MediaQuery.of(Get.context!).size.width * 0.3,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
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
                    'Continue',
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
    );
  }
}
