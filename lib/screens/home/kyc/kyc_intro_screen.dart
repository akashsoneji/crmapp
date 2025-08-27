import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/widgets/kyc_scaffold.dart';
import 'package:pipze/routes/app_pages.dart';

class KycIntroScreen extends StatelessWidget {
  const KycIntroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KycScaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),

              // Header Section
              Center(
                child: Column(
                  children: [
                    Text(
                      'To open your trading account, we first need to verify your identity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 48.h),

              // Step 1 Card
              _buildStepCard(
                stepNumber: 1,
                title: 'Personal Details',
                status: 'Incomplete',
                backgroundColor: const Color(0xFFF8F3FF), // Light purple
                iconColor: const Color(0xFF5A2DD8), // Primary purple
                features: [
                  'Deposit up to \$2000 within 14 days',
                  'Limited deposit methods',
                  'Live & demo trading',
                ],
                isActive: true,
              ),

              SizedBox(height: 24.h),

              // Step 2 Card
              _buildStepCard(
                stepNumber: 2,
                title: 'ID Verification',
                status: 'Locked',
                backgroundColor: Colors.white,
                iconColor: Colors.grey[400]!,
                features: [
                  'Unlimited deposits',
                  'Global and local payments',
                  'Withdrawals',
                ],
                isActive: false,
              ),

              const Spacer(),

              // Start Verification Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed(AppPages.KYC_DETAILS),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A2DD8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Start Verification',
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

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String status,
    required Color backgroundColor,
    required Color iconColor,
    required List<String> features,
    required bool isActive,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(color: const Color(0xFF5A2DD8), width: 1)
            : Border.all(color: const Color(0xFFE3E7EF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Icon
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stepNumber == 1 ? Icons.person : Icons.verified_user,
                  color: Colors.white,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              // Title and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step $stepNumber $title',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isActive ? const Color(0xFF5A2DD8) : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Features list
          ...features.map((feature) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isActive ? const Color(0xFF5A2DD8) : Colors.grey[400],
                      size: 16.w,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
