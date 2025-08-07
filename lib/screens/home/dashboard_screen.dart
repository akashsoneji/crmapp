import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/controllers/account_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AccountController accountController = Get.find<AccountController>();
    final languageService = Get.find<LanguageService>();

    return Obx(() {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(languageService.tr('dashboard_title')),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account balance card
              Obx(() {
                final activeAccount = accountController.activeAccount;
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                                  Text(
                            languageService.tr('account_balance'),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textGrey,
                            ),
                          ),
                        SizedBox(height: 8.h),
                        Text(
                          activeAccount != null
                              ? '\$${activeAccount.balance.toStringAsFixed(2)}'
                              : '\$0.00',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          activeAccount?.type ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              SizedBox(height: 20.h),

              // Quick actions
              Text(
                languageService.tr('quick_actions'),
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.add,
                      title: languageService.tr('deposit'),
                      onTap: () {
                        Get.snackbar('Info', 'Deposit feature coming soon');
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.remove,
                      title: languageService.tr('withdraw'),
                      onTap: () {
                        Get.snackbar('Info', 'Withdraw feature coming soon');
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Recent activity placeholder
              Text(
                languageService.tr('recent_activity'),
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: Card(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 48.h,
                          color: AppColors.textGrey,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          languageService.tr('no_recent_activity'),
                          style: AppTextStyles.subheading.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Icon(icon, size: 32.h, color: AppColors.primary),
              SizedBox(height: 8.h),
              Text(
                title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
