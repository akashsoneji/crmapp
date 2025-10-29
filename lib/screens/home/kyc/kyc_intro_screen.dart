import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/controllers/more/more_controller.dart';

class KycIntroScreen extends StatelessWidget {
  final StageCompletion? stageCompletion;

  const KycIntroScreen({Key? key, this.stageCompletion}) : super(key: key);

  int _calculateCompletion() {
    if (stageCompletion == null) return 0;

    int completion = 0;

    // Step 1: Check mobile verification
    if (stageCompletion!.mobileVerified != null) {
      completion += 20;
    }

    // Step 2: Check email verification
    if (stageCompletion!.emailVerified != null) {
      completion += 20;
    }

    // Step 3: Check personal details
    if (stageCompletion!.personalDetails == true) {
      completion += 20;
    }

    // Step 4: Check identity verification
    if (stageCompletion!.identityVerified == true) {
      completion += 20;
    }

    // Step 5: Check address proof verification
    if (stageCompletion!.addressProofVerified == true) {
      completion += 20;
    }

    return completion;
  }

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
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: SingleChildScrollView(
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

                    // Step 1 Card - Personal Details
                    _buildStepCard(
                      stepNumber: 1,
                      title: 'Personal Details',
                      status:
                          stageCompletion?.mobileVerified != null &&
                                  stageCompletion?.emailVerified != null &&
                                  stageCompletion?.personalDetails == true
                              ? 'Completed'
                              : 'Incomplete',
                      backgroundColor:
                          stageCompletion?.mobileVerified != null &&
                                  stageCompletion?.emailVerified != null &&
                                  stageCompletion?.personalDetails == true
                              ? const Color(0xFFE8F5E8) // Light green
                              : AppColors.primary.withOpacity(0.1), // Light purple
                      iconColor:
                          stageCompletion?.mobileVerified != null &&
                                  stageCompletion?.emailVerified != null &&
                                  stageCompletion?.personalDetails == true
                              ? Colors.green
                              : AppColors.primary,
                      textColor:
                          stageCompletion?.mobileVerified != null &&
                                  stageCompletion?.emailVerified != null &&
                                  stageCompletion?.personalDetails == true
                              ? Colors.green
                              : AppColors.primary,
                      features: [
                        'Deposit up to \$2000 within 14 days',
                        'Limited deposit methods',
                        'Live & demo trading',
                      ],
                      isActive:
                          stageCompletion?.mobileVerified != null &&
                                  stageCompletion?.emailVerified != null &&
                                  stageCompletion?.personalDetails == true
                              ? false
                              : true,
                    ),

                    SizedBox(height: 24.h),

                    // Step 2 Card - ID Verification
                    _buildStepCard(
                      stepNumber: 2,
                      title: 'ID Verification',
                      status:
                          stageCompletion?.identityVerified == true &&
                                  stageCompletion?.addressProofVerified == true
                              ? 'Completed'
                              : 'Incomplete',
                      backgroundColor:
                          stageCompletion?.identityVerified == true &&
                                  stageCompletion?.addressProofVerified == true
                              ? const Color(0xFFE8F5E8) // Light green
                              : (stageCompletion?.mobileVerified != null &&
                                  stageCompletion?.emailVerified != null &&
                                  stageCompletion?.personalDetails == true)
                              ? AppColors.primary.withAlpha(20)
                              : Colors.white,
                      iconColor:
                          stageCompletion?.identityVerified == true &&
                                  stageCompletion?.addressProofVerified == true
                              ? Colors.green
                              : Colors.grey[400]!,
                      textColor:
                          stageCompletion?.identityVerified == true &&
                                  stageCompletion?.addressProofVerified == true
                              ? Colors.green
                              : (stageCompletion?.mobileVerified != null &&
                                  stageCompletion?.emailVerified != null &&
                                  stageCompletion?.personalDetails == true)
                              ? AppColors.primary.withAlpha(1000)
                              : Colors.grey[400]!,
                      features: [
                        'Unlimited deposits',
                        'Global and local payments',
                        'Withdrawals',
                      ],
                      isActive: stageCompletion?.identityVerified == true,
                    ),

                    SizedBox(height: 24.h),

                    // Step 3 Card - Address Verification
                    _buildStepCard(
                      stepNumber: 3,
                      title: 'Address Verification',
                      status:
                          stageCompletion?.addressProofVerified == true
                              ? 'Completed'
                              : stageCompletion?.identityVerified == true
                              ? 'Available'
                              : 'Locked',
                      textColor:
                          stageCompletion?.addressProofVerified == true
                              ? Colors.green
                              : stageCompletion?.identityVerified == true
                              ? AppColors.primary
                              : Colors.grey[400]!,
                      backgroundColor:
                          stageCompletion?.addressProofVerified == true
                              ? const Color(0xFFE8F5E8) // Light green
                              : stageCompletion?.identityVerified == true
                              ? const Color(0xFFF8F3FF) // Light purple
                              : Colors.white,
                      iconColor:
                          stageCompletion?.addressProofVerified == true
                              ? Colors.green
                              : stageCompletion?.identityVerified == true
                              ? AppColors.primary
                              : Colors.grey[400]!,
                      features: [
                        'Unlimited deposits',
                        'Global and local payments',
                        'Withdrawals',
                      ],
                      isActive: stageCompletion?.identityVerified == true,
                    ),

                    SizedBox(height: 90.h),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: 80.h, color: Colors.white),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (stageCompletion?.mobileVerified == null ||
                          stageCompletion?.emailVerified == null ||
                          stageCompletion?.personalDetails == false) {
                        Get.toNamed(AppPages.KYC_DETAILS);
                      } else if (stageCompletion?.identityVerified == false ||
                          stageCompletion?.addressProofVerified == false) {
                        Get.toNamed(AppPages.KYC_DOCS);
                      } else {
                        Get.toNamed(AppPages.KYC_BANK);
                      }
                    },
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
              ),
            ),
          ],
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
    required Color textColor,
    required List<String> features,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        if (stageCompletion?.mobileVerified == null ||
            stageCompletion?.emailVerified == null ||
            stageCompletion?.personalDetails == false) {
          Get.toNamed(AppPages.KYC_DETAILS);
        } else if (stageCompletion?.identityVerified == false ||
            stageCompletion?.addressProofVerified == false) {
          Get.toNamed(AppPages.KYC_DOCS);
        } else {
          Get.toNamed(AppPages.KYC_BANK);
        }
      },
      child: Container(
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
                          color: textColor,
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
      ),
    );
  }
}
