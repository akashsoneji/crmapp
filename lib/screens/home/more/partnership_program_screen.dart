import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/more/more_controller.dart';
import 'package:pipze/services/language_service.dart';

class PartnershipProgramScreen extends StatelessWidget {
  const PartnershipProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final moreController = Get.find<MoreController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: Text(
          languageService.tr('partnership_program'),
          style: AppTextStyles.screenTitle,
        ),
        leading: IconButton(
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Obx(() {
          final stageCompletion =
              moreController.dashboardModel.value?.data?.stageCompletion;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verification Cards Grid
              _buildVerificationCards(languageService, stageCompletion),

              SizedBox(height: 32.h),

              // Submit IB Application Button
              _buildSubmitButton(languageService, stageCompletion),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildVerificationCards(
    LanguageService languageService,
    dynamic stageCompletion,
  ) {
    // Check verification status from API data
    final isEmailVerified = stageCompletion?.emailVerified != null;
    final isMobileVerified = stageCompletion?.mobileVerified != null;
    final isPersonalInfoVerified = stageCompletion?.personalDetails == true;
    final isIbRequestCompleted =
        stageCompletion?.identityVerified == true &&
        stageCompletion?.addressProofVerified == true;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _buildVerificationCard(
          icon: 'email',
          title: languageService.tr('email_verification'),
          isCompleted: isEmailVerified,
          isPending: !isEmailVerified,
          onTap: () {
            // Handle email verification
          },
        ),
        _buildVerificationCard(
          icon: 'mobile',
          title: languageService.tr('mobile_verification'),
          isCompleted: isMobileVerified,
          isPending: !isMobileVerified,
          onTap: () {
            // Handle mobile verification
          },
        ),
        _buildVerificationCard(
          icon: 'personal_info',
          title: languageService.tr('personal_information'),
          isCompleted: isPersonalInfoVerified,
          isPending: !isPersonalInfoVerified,
          onTap: () {
            // Handle personal information
          },
        ),
        _buildVerificationCard(
          icon: 'ib_request',
          title: languageService.tr('ib_request'),
          isCompleted: isIbRequestCompleted,
          isPending: !isIbRequestCompleted,
          onTap: () {
            // Handle IB request
          },
        ),
      ],
    );
  }

  Widget _buildVerificationCard({
    required String icon,
    required String title,
    required bool isCompleted,
    bool isPending = false,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(0.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with status indicator
              Stack(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/svg/more/$icon.svg',
                        width: 24.w,
                        height: 24.w,
                        colorFilter: ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  // Status indicator
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? Colors.green
                                : isPending
                                ? Colors.orange
                                : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : isPending
                              ? Icons.priority_high
                              : Icons.close,
                          size: 12.w,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Title
              Text(
                title,
                style: AppTextStyles.labelOnChartPendingOrder.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    LanguageService languageService,
    dynamic stageCompletion,
  ) {
    // Check if all verifications are completed
    final isEmailVerified = stageCompletion?.emailVerified != null;
    final isMobileVerified = stageCompletion?.mobileVerified != null;
    final isPersonalInfoVerified = stageCompletion?.personalDetails == true;
    final isIbRequestCompleted =
        stageCompletion?.identityVerified == true &&
        stageCompletion?.addressProofVerified == true;

    final canSubmit =
        isEmailVerified &&
        isMobileVerified &&
        isPersonalInfoVerified &&
        isIbRequestCompleted;

    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed:
            canSubmit
                ? () {
                  // Handle submit IB application
                  Get.snackbar(
                    languageService.tr('success'),
                    languageService.tr('ib_application_submitted'),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.primary,
                    colorText: Colors.white,
                  );
                }
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? AppColors.primary : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: Text(
          languageService.tr('submit_ib_application'),
          style: AppTextStyles.button.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
