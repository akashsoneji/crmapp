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

              VerifyAccountCard(),

              SizedBox(height: 22.h),
              _MenuItem(
                icon: 'dollar-circle',
                label: languageService.tr('general_finance'),
                onTap: () {
                  // Get.toNamed(AppPages.DEPOSIT);
                },
                showTopBorder: true,
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'dashboard',
                label: languageService.tr('more_dashboard'),
                onTap: () {
                  // Get.toNamed(AppPages.WITHDRAWAL);
                },
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'copy-trading',
                label: languageService.tr('more_copy_trading'),
                onTap: () {
                  // Get.toNamed(AppPages.WALLET);
                },
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'bonus',
                label: languageService.tr('more_bonus'),
                onTap: () {
                  // Get.toNamed(AppPages.TRANSACTION_HISTORY);
                },
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'demo-account',
                label: languageService.tr('more_demo_contest'),
                onTap: () {},
                color: AppColors.textPrimary,
              ),

              _MenuItem(
                icon: 'tools',
                label: languageService.tr('more_tool_education'),
                onTap: () {
                  Get.toNamed(AppPages.KYC_VERIFICATION);
                },
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'support',
                label: languageService.tr('more_support'),
                onTap: () {},
                color: AppColors.textPrimary,
              ),

              _MenuItem(
                icon: 'settings',
                label: languageService.tr('more_settings'),
                onTap: () {},
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
            top: showTopBorder
                ? BorderSide(color: Colors.grey.shade300, width: 1)
                : BorderSide.none,
            bottom: showBottomBorder
                ? BorderSide(color: Colors.grey.shade300, width: 1)
                : BorderSide.none,
          ),
        ),
        child: SizedBox(
          height: 50.h,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: 0,
            leading: SvgPicture.asset(
              'assets/svg/more/$icon.svg',
              height: 22.h,
              width: 22.w,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 1.4,
                fontFamily: 'Roboto',
                color: color,
              ),
            ),
            trailing: showBottomBorder ? Icon(Icons.arrow_forward_ios_sharp,size: 14.h,color: AppColors.icongrey,) : null,
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
  const VerifyAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8F3FF), // light purple background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with title + arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Verify your account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.black87),
              ],
            ),

            const SizedBox(height: 6),

            // Subtitle
            const Text(
              "Complete verification to unlock all app features",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 16),

            // Progress row with percentage
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "20% completed",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 0.2, // 20% progress
                    minHeight: 3,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


