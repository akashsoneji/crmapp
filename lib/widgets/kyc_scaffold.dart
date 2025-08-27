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
          centerTitle: true,
          actions: [
            IconButton(
              icon: Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                ),
                child: Icon(Icons.close, size: 20.w, color: Colors.black87),
              ),
              onPressed: onClose ?? _showExitConfirmation,
            ),
          ],
        ),
        body: body,
      ),
    );
  }

  void _showExitConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Exit Verification',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to exit the verification process? Your progress will be saved.',
          style: TextStyle(fontSize: 14.sp, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Continue',
              style: TextStyle(
                color: const Color(0xFF5A2DD8),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.offAllNamed('/more'); // Navigate to more screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A2DD8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              'Exit',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
