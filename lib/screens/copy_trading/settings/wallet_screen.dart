import 'package:crm_app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_settings_controller.dart';

class CopyTradingWalletScreen extends StatelessWidget {
  const CopyTradingWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CopyTradingSettingsController>();

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,

        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Wallet',
          style: AppTextStyles.heading.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: AppColors.textPrimary,
              size: 24.r,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            // Balance Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 32.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Balance',
                    style: AppTextStyles.subheading.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Obx(
                    () => Text(
                      controller.walletBalance.value,
                      style: TextStyle(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Tabs (Actions, History, About)
            Row(
              children: [
                _buildTab(context, 'Actions', 0, controller),
                SizedBox(width: 8.w),
                _buildTab(context, 'History', 1, controller),
                SizedBox(width: 8.w),
                _buildTab(context, 'About', 2, controller),
              ],
            ),

            SizedBox(height: 16.h),

            // List of Actions
            Expanded(
              child: Obx(() {
                if (controller.selectedWalletTab.value == 0) {
                  return ListView(
                    children: [
                      _ActionItem(
                        iconData: Icons.add_circle_outline_rounded,
                        label: 'Deposit',
                        onTap: () => Get.toNamed(AppPages.FINANCE),
                      ),
                      _ActionItem(
                        iconData: Icons.arrow_circle_up_rounded,
                        label: 'Withdrawal',
                        onTap: () {},
                      ),
                      _ActionItem(
                        iconData: Icons.swap_horizontal_circle_outlined,
                        label: 'Internal Transfer',
                        onTap:
                            () =>
                                Get.toNamed('/copy-trading-internal-transfer'),
                      ),
                      _ActionItem(
                        iconData: Icons.history_rounded,
                        label: 'Internal Transfer History',
                        onTap: () {},
                      ),
                    ],
                  );
                }
                return const Center(child: Text('Work in Progress'));
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    int index,
    CopyTradingSettingsController controller,
  ) {
    return Expanded(
      child: Obx(() {
        final isSelected = controller.selectedWalletTab.value == index;
        return GestureDetector(
          onTap: () => controller.selectedWalletTab.value = index,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color:
                    isSelected
                        ? AppColors.primary
                        : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData iconData;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.iconData,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(iconData, color: AppColors.primary, size: 28.r),
          title: Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16.r,
            color: AppColors.textGrey,
          ),
          onTap: onTap,
        ),
        Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
      ],
    );
  }
}
