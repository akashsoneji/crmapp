import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/auth_controller.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/widgets/dashBorder.dart';

class AccountCreatedScreen extends StatelessWidget {
  AccountCreatedScreen({super.key});
  final AuthController authController = Get.find<AuthController>();
  final LanguageService languageService = Get.find<LanguageService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 40.h),
                    _buildSuccessIcon(),
                    SizedBox(height: 24.h),
                    _buildWelcomeMessage(),
                    SizedBox(height: 32.h),
                    _buildAccountDetails(),
                    SizedBox(height: 32.h),
                    _buildCallToAction(context),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    ;
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: [
          // Back button container
          Container(
            height: 40.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              iconSize: 17.h,
              padding: EdgeInsets.only(left: 5.w),
            ),
          ),

          SizedBox(width: 16.w),

          // Progress bar row
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _progressBar(active: true),
                SizedBox(width: 8.w),
                _progressBar(active: true),
                SizedBox(width: 8.w),
                _progressBar(active: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar({bool active = false}) {
    return Container(
      width: 60.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        // borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Center(
      child: SvgPicture.asset(
        'assets/svg/welcom_withstr_icon.svg',
        height: 130.h,
        width: 130.w,
        semanticsLabel: 'Pipze Logo',
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Column(
      children: [
        Text(
          languageService.tr("onboarding_welcome"),
          style: AppTextStyles.heading.copyWith(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        Text(
          languageService.tr("onboarding_slide3_subtitle"),

          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textGrey,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          languageService.tr("onboarding_slide3_subtitle2"),

          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textGrey,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAccountDetails() {
    return Container(
      // padding: EdgeInsets.all(20.w),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(16),
      //   border: Border.all(color: AppColors.border),
      // ),
      child: Column(
        children: [
          _buildDetailRow(
            languageService.tr("common_type"),
            languageService.tr("common_real"),
          ),
          _buildDivider(),
          _buildDetailRow(languageService.tr("common_number"), "12384965"),
          _buildDivider(),
          _buildDetailRow(
            languageService.tr("common_platform"),
            languageService.tr("Pipze Trader"),
          ),
          _buildDivider(),
          _buildDetailRow(
            languageService.tr("common_currency"),
            languageService.tr("common_currency_usd"),
          ),
          _buildDivider(),
          _buildDetailRow(languageService.tr("common_leverage"), "1:5000"),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 0, right: 0),
      child: DashedUnderline(color: AppColors.textGreyLight.withAlpha(100)),
    );
  }

  Widget _buildCallToAction(BuildContext context) {
    return Column(
      children: [
        Text(
          languageService.tr("common_to_start_trading"),
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to trading screen (simulating deposit completion)
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/trading',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              languageService.tr("common_deposit"),
              style: AppTextStyles.button,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // Navigate to trading screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/trading',
                (route) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              languageService.tr("common_skip_for_now"),
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
