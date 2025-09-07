import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
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
          style: AppTextStyles.screenTitle,
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
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Container(
                padding: EdgeInsets.all(1.w),
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

              VerifyAccountCard(
                title: languageService.tr('verify_your_account'),
                subTitle: languageService.tr('complete_verification_to_unlock'),
                percentage: '25',
              ),

              SizedBox(height: 22.h),
              _MenuItem(
                icon: 'dollar-circle',
                label: languageService.tr('general_finance'),
                onTap: () {
                  Get.toNamed(AppPages.FINANCE);
                },
                showTopBorder: true,
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'dashboard',
                label: languageService.tr('more_dashboard'),
                onTap: () {
                  Get.toNamed(AppPages.IB_DASHBOARD);
                },
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'copy-trading',
                label: languageService.tr('more_copy_trading'),
                onTap: () {
                  Get.toNamed(AppPages.COPY_TRADING);
                },
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'bonus',
                label: languageService.tr('more_bonus'),
                onTap: () {
                  Get.toNamed(AppPages.BONUS);
                },
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'demo-account',
                label: languageService.tr('more_demo_contest'),
                onTap: () {
                  Get.toNamed(AppPages.DEMO_CONTEST);
                },
                color: AppColors.textPrimary,
              ),

              _MenuItem(
                icon: 'tools',
                label: languageService.tr('more_tool_education'),
                onTap: () {
                  Get.toNamed(AppPages.TOOLS_EDUCATION);
                },
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'support',
                label: languageService.tr('more_support'),
                onTap: () {
                  Get.toNamed(AppPages.SUPPORT);
                },
                color: AppColors.textPrimary,
              ),

              _MenuItem(
                icon: 'settings',
                label: languageService.tr('more_settings'),
                onTap: () {
                  Get.toNamed(AppPages.SETTING);
                },
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'logout',
                label: languageService.tr('more_logout'),
                onTap: () {
                  _showLogoutDialog(authController);
                },
                showBottomBorder: false,
                color: AppColors.red,
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthController authController) {
    final languageService = Get.find<LanguageService>();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App logo - replace asset path with your app logo svg or image
              SvgPicture.asset(
                'assets/svg/logo.svg',
                height: 60.h,
                width: 60.w,
              ),
              SizedBox(height: 24.h),
              Text(
                "Are you sure you want to logout?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        authController.logout();
                      },
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Yes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "No",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool showTopBorder;
  final bool showBottomBorder;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.showTopBorder = false,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top:
                showTopBorder
                    ? BorderSide(color: Colors.grey.shade300, width: 1)
                    : BorderSide.none,
            bottom:
                showBottomBorder
                    ? BorderSide(color: Colors.grey.shade300, width: 1)
                    : BorderSide.none,
          ),
        ),
        child: SizedBox(
          height: 56.h,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: 0,
            leading: SvgPicture.asset(
              'assets/svg/more/$icon.svg',
              height: 24.h,
              width: 24.w,
              color: showBottomBorder ? AppColors.primary : color,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
                color: color,
              ),
            ),
            trailing:
                showBottomBorder
                    ? Icon(
                      Icons.arrow_forward_ios_sharp,
                      size: 14.h,
                      color: AppColors.icongrey,
                    )
                    : null,
            onTap: onTap,
            minLeadingWidth: 10,
            horizontalTitleGap: 8.w,
          ),
        ),
      ),
    );
  }
}

class VerifyAccountCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final String percentage;

  VerifyAccountCard({
    super.key,
    required this.title,
    required this.subTitle,
    required this.percentage,
  });

  final languageService = Get.find<LanguageService>();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withOpacity(0.1), // light purple background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Get.toNamed(AppPages.KYC_INTRO),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with title + arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: AppTextStyles.heading)),
                  Icon(Icons.arrow_forward, color: Colors.black87),
                ],
              ),

              const SizedBox(height: 6),

              // Subtitle
              Text(subTitle, style: AppTextStyles.labelOnChartPendingOrder),

              const SizedBox(height: 16),

              // Progress row with percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$percentage% ${languageService.tr('completed')}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: 0.2, // 20% progress
                      minHeight: 3,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
