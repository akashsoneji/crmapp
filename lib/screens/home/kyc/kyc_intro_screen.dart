import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/routes/app_pages.dart';

class KycIntroScreen extends StatelessWidget {
  const KycIntroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: AppColors.grey)),
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(
          color: AppColors.backgroundLight,
          onPressed: () => Get.back(),
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
        ),
      ),
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
                      "Verify your account",
                      style: AppTextStyles.black24600h1_42,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'To open your trading account, we first need to verify your identity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.icongrey,
                        height: 1.36,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Step 1 Card
              _buildStepCard(
                stepNumber: 1,
                title: 'Personal Details',
                status: 'Incomplete',
                backgroundColor: const Color(0xFFF8F3FF), // Light purple
                iconColor: AppColors.primary, // Primary purple
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
                height: 46.h,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed(AppPages.KYC_DETAILS),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.zero,
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
        border:
            isActive
                ? Border.all(color: AppColors.primary, width: 1)
                : Border.all(color: const Color(0xFFE3E7EF), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            stepNumber == 1
                ? "assets/svg/kyc/profile-circle.svg"
                : "assets/svg/kyc/personalcard.svg",
            height: 24.h,
            width: 24.w,
            color: AppColors.primary,
          ),
          SizedBox(width: 10.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title + status on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with white outline
                    // SizedBox(width: 16.w),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step $stepNumber',
                            style: AppTextStyles.black16600,
                          ),
                          Text('$title', style: AppTextStyles.black16600),
                        ],
                      ),
                    ),
                    // Status on the right
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color:
                            isActive ? AppColors.primary : AppColors.icongrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                // Features list
                ...features.map(
                  (feature) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/kyc/tick-circle.svg',
                          height: 16.h,
                          width: 16.w,
                          color: AppColors.icongrey,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTextStyles.black11400.copyWith(
                              height: 1.29,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
