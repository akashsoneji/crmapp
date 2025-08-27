import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/widgets/kyc_scaffold.dart';
import 'package:pipze/routes/app_pages.dart';

class KycSuccessScreen extends StatelessWidget {
  const KycSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KycScaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(),

              // Success Icon
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A2DD8).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80.w,
                  color: const Color(0xFF5A2DD8),
                ),
              ),

              SizedBox(height: 32.h),

              // Success Title
              Text(
                'Verification Complete!',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16.h),

              // Success Message
              Text(
                'Your account has been successfully verified. You can now access all trading features.',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 48.h),

              // Features List
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F3FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF5A2DD8).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'What you can do now:',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5A2DD8),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildFeatureItem('Unlimited deposits and withdrawals'),
                    _buildFeatureItem('Global and local payment methods'),
                    _buildFeatureItem('Access to all trading instruments'),
                    _buildFeatureItem('Priority customer support'),
                  ],
                ),
              ),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.until((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A2DD8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue to App',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: const Color(0xFF5A2DD8), size: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
