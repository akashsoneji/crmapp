import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/controllers/auth_controller.dart';
import 'package:pipze/routes/app_pages.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final languageService = Get.find<LanguageService>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar:
      AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: Text(
          languageService.tr('setting_title'),
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/svg/edit_profile.svg',
              height: 24.h,
              width: 24.w,
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32.r,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(Icons.person, size: 40.r, color: AppColors.primary),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Brooklyn Simmons',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18.sp,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(Icons.verified, color: AppColors.primary, size: 20.r),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'brooklynsimmons@gmail.com',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              // Stepper
              _VerificationStepper(),
              SizedBox(height: 24.h),
              // Fund Management
              _SectionTitle(languageService.tr('fund_management')),
              _MenuItem(
                icon: 'deposit',
                label: languageService.tr('deposit'),
                onTap: () {},
              ),
              _MenuItem(
                icon: 'withdrawal',
                label: languageService.tr('withdrawal'),
                onTap: () {},
              ),
              _MenuItem(
                icon: 'wallet',
                label: languageService.tr('wallet'),
                onTap: () {},
              ),
              _MenuItem(
                icon: 'transaction_history',
                label: languageService.tr('transaction_history'),
                onTap: () {},
              ),
              _MenuItem(
                icon: 'your_earning',
                label: languageService.tr('your_earning'),
                onTap: () {},
              ),
              SizedBox(height: 20.h),
              // Bank Management
              _SectionTitle('BANK MANAGEMENT'),
              _MenuItem(
                icon: 'kyc_verification',
                label: languageService.tr('kyc_verification'),
                onTap: () {},
              ),
              _MenuItem(
                icon: 'bank_details',
                label: languageService.tr('bank_details'),
                onTap: () {},
              ),
              SizedBox(height: 20.h),
              // Tool Management
              _SectionTitle(languageService.tr('tool_management')),
              _MenuItem(
                icon: 'news',
                label: languageService.tr('news'),
                onTap: () {},
              ),
              _MenuItem(
                icon: 'chat_with_us',
                label: languageService.tr('chat_with_us'),
                onTap: () {},
              ),
              _MenuItem(
                icon: 'tools',
                label: languageService.tr('tools'),
                onTap: () {},
              ),
              _MenuItem(
                icon: 'calculator',
                label: languageService.tr('lot_calculator'),
                onTap: () {},
              ),
              SizedBox(height: 20.h),
              _SectionTitle(languageService.tr('app_setting')),
              _MenuItem(
                icon: 'language',
                label: languageService.tr('more_language'),
                onTap: () {
                  Get.toNamed(AppPages.LANGUAGE_SELECTOR);
                },
              ),
              SizedBox(height: 32.h),
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(authController),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: Text(
                    languageService.tr('more_logout'),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
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

  void _showLogoutDialog(AuthController authController) {
    final languageService = Get.find<LanguageService>();
    Get.dialog(
      AlertDialog(
        title: Text(languageService.tr('logout_confirm_title')),
        content: Text(languageService.tr('logout_confirm_message')),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(languageService.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              languageService.tr('logout'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textGrey,
          fontWeight: FontWeight.w700,
          fontSize: 14.sp,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
class _MenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: SvgPicture.asset(
          'assets/svg/$icon.svg',
          height: 24.h,
          width: 24.w,
          color: AppColors.primary,
        ),
        title: Text(
          label,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
        minLeadingWidth: 0,
        horizontalTitleGap: 12.w,
      ),
    );
  }
}

class _VerificationStepper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Example: 2 steps completed
    int currentStep = 2;
    List<String> steps = [
      'Phone Verified',
      'Email Verified',
      'Profile Details',
      'KYC',
      'Bank Verify',
    ];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          bool isCompleted = index < currentStep;
          bool isCurrent = index == currentStep;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color: isCompleted || isCurrent ? AppColors.primary : AppColors.textGrey,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, color: Colors.white, size: 16.r)
                            : isCurrent
                                ? Icon(Icons.circle, color: AppColors.primary, size: 12.r)
                                : null,
                      ),
                    ),
                    if (index != steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted ? AppColors.primary : AppColors.textGrey.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isCompleted || isCurrent ? AppColors.primary : AppColors.textGrey,
                    fontWeight: isCompleted || isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
