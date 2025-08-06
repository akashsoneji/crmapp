import 'package:flutter/material.dart';
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

    return Obx(() {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(languageService.tr('more_title')),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Profile section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30.r,
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.person,
                          size: 30.h,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageService.tr('user_profile'),
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              languageService.tr('view_profile'),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16.h,
                        color: AppColors.textGrey,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Menu items
              _buildMenuItem(
                icon: Icons.account_balance_wallet,
                title: languageService.tr('account_management'),
                onTap: () {
                  Get.toNamed(AppPages.ACCOUNT_MANAGEMENT);
                },
              ),
              _buildMenuItem(
                icon: Icons.language,
                title: languageService.tr('language_settings'),
                onTap: () {
                  Get.toNamed(AppPages.LANGUAGE_SELECTOR);
                },
              ),
              _buildMenuItem(
                icon: Icons.notifications,
                title: languageService.tr('notifications'),
                onTap: () {
                  Get.snackbar('Info', 'Notifications settings coming soon');
                },
              ),
              _buildMenuItem(
                icon: Icons.security,
                title: languageService.tr('security'),
                onTap: () {
                  Get.snackbar('Info', 'Security settings coming soon');
                },
              ),
              _buildMenuItem(
                icon: Icons.help,
                title: languageService.tr('help_support'),
                onTap: () {
                  Get.snackbar('Info', 'Help & Support coming soon');
                },
              ),
              _buildMenuItem(
                icon: Icons.info,
                title: languageService.tr('about'),
                onTap: () {
                  Get.snackbar('Info', 'About section coming soon');
                },
              ),

              const Spacer(),

              // Logout button
              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showLogoutDialog(authController);
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      languageService.tr('logout'),
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.h,
          color: AppColors.textGrey,
        ),
        onTap: onTap,
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
