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
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: Text(
          languageService.tr('setting_title'),
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 18.sp,
            fontFamily: 'Roboto',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/svg/edit_profile.svg',
              height: 24.h,
              width: 24.w,
              color: AppColors.primary,
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            onPressed: () {
              Get.toNamed(AppPages.EDIT_PROFILE);
            },
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
                      child: Icon(
                        Icons.person,
                        size: 40.r,
                        color: AppColors.primary,
                      ),
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
                                  fontWeight: FontWeight.w600,
                                  height: 1.6,
                                  fontSize: 18.sp,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.verified,
                                color: AppColors.primary,
                                size: 20.r,
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'brooklynsimmons@gmail.com',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              // Stepper
              _VerificationStepper(),
              SizedBox(height: 8.h),
              // Fund Management
              _SectionTitle(languageService.tr('fund_management')),
              _MenuItem(
                icon: 'deposit',
                label: languageService.tr('deposit'),
                onTap: () {
                  Get.toNamed(AppPages.DEPOSIT);
                },
              ),
              _MenuItem(
                icon: 'withdrawal',
                label: languageService.tr('withdrawal'),
                onTap: () {
                  Get.toNamed(AppPages.WITHDRAWAL);
                },
              ),
              _MenuItem(
                icon: 'wallet',
                label: languageService.tr('wallet'),
                onTap: () {
                  Get.toNamed(AppPages.WALLET);
                },
              ),
              _MenuItem(
                icon: 'transaction_history',
                label: languageService.tr('transaction_history'),
                onTap: () {
                  Get.toNamed(AppPages.TRANSACTION_HISTORY);
                },
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
                onTap: () {
                  Get.toNamed(AppPages.KYC_VERIFICATION);
                },
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
                onTap: () {
                  Get.toNamed(AppPages.CHAT_WITH_US);
                },
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
                height: 46.h,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(authController),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                  ),
                  child: Text(
                    languageService.tr('more_logout'),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                      fontFamily: 'Roboto',
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
        title: Text(
          languageService.tr('logout_confirm_title'),
          style: TextStyle(fontFamily: 'RobotoMono'),
        ),
        content: Text(
          languageService.tr('logout_confirm_message'),
          style: TextStyle(fontFamily: 'RobotoMono'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              languageService.tr('cancel'),
              style: TextStyle(fontFamily: 'RobotoMono'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              languageService.tr('logout'),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'RobotoMono',
              ),
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
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textGrey,
        fontWeight: FontWeight.w500,
        fontSize: 14.sp,
        letterSpacing: 1.4,
        fontFamily: 'RobotoMono',
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
      child: SizedBox(
        height: 40.h,
        child: ListTile(
          contentPadding: EdgeInsets.all(0),
          minVerticalPadding: 0,
          leading: SvgPicture.asset(
            'assets/svg/$icon.svg',
            height: 18.h,
            width: 18.w,
            color: AppColors.primary,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.4,
              fontFamily: 'Roboto',
            ),
          ),
          onTap: onTap,
          minLeadingWidth: 10,
          horizontalTitleGap: 8.w,
        ),
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

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 4.w),
      child: Row(
        children: List.generate(steps.length, (index) {
          bool isCompleted = index < currentStep;
          bool isCurrent = index == currentStep;

          return Expanded(
            child: Container(
              height: 80.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Step circle and connecting line
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Step circle - centered in its space
                      Center(
                        child: Container(
                          width: 32.r,
                          height: 32.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                isCompleted || isCurrent
                                    ? AppColors.primary
                                    : Colors.white,
                            border: Border.all(
                              color:
                                  isCompleted || isCurrent
                                      ? AppColors.primary
                                      : AppColors.textGrey,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child:
                              isCompleted
                                  ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20.r,
                                  )
                                  : isCurrent
                                  ? Icon(
                                    Icons.circle,
                                    color: AppColors.primary,
                                    size: 20.r,
                                  )
                                  : null,
                        ),
                      ),
                      // Connecting line (except for last step)
                      if (index != steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            width: 50,
                            color:
                                isCompleted
                                    ? AppColors.primary
                                    : AppColors.textGrey.withOpacity(0.3),
                          ),
                        ),
                    ],
                  ),
                  // Step text label - centered below the circle
                  SizedBox(height: 16.h),
                  Container(
                    alignment: Alignment.topLeft,
                    width: 50.w,
                    child: Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 11.sp,
                        color:
                            isCompleted || isCurrent
                                ? AppColors.primary
                                : AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'RobotoMono',
                      ),
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
