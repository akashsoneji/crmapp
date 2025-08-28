import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import '../../controllers/dashboard_controller.dart';
import 'more/finance/internal_transfer_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  DashboardScreen({this.onNavigateToTab});

  late final DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    // Set the navigation callback in the controller
    if (onNavigateToTab != null) {
      controller.setNavigationCallback(onNavigateToTab!);
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SvgPicture.asset(
            "assets/svg/menu.svg",
            height: 18.h,
            width: 18.w,
          ),
        ),
        title: Text('Dashboard', style: AppTextStyles.screenTitle),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 0),
            child: IconButton(
              icon: SvgPicture.asset(
                "assets/svg/deshboard/empty-wallet-add.svg",
              ),
              onPressed: () {},
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: SvgPicture.asset("assets/svg/deshboard/add-square.svg"),
              onPressed: controller.showOpenAccountSheet,
            ),
          ),
        ],
      ),
      body: Obx(
        () => Stack(
          children: [
            // Main Content
            (controller.accounts.isEmpty)
                ? Container(
                  color: AppColors.backgroundLight,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 22.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/svg/deshboard/no_account.svg",
                        width: 143.43.w,
                        height: 98.95.h,
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        "New Account",
                        style: AppTextStyles.heading,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 14.h),

                      Text(
                        "Open a trading account to get superior trading conditions for any strategy.",
                        style: AppTextStyles.grey14400h57,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 14.h),
                      SizedBox(
                        height: 44.h,
                        width: 333.w,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: () {
                            controller.openRealAccount();
                          },
                          child: Text(
                            'Open Real Account',
                            style: AppTextStyles.black14600h1_71.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),

                      SizedBox(
                        height: 44.h,
                        width: 333.w,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.backgroundLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: () {
                            controller.openDemoAccount();
                          },
                          child: Text(
                            'Open Demo Account',
                            style: AppTextStyles.black14600h1_71.copyWith(
                              color: AppColors.whiteColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : AnimatedOpacity(
                  opacity: controller.isBottomSheetOpen.value ? 0.3 : 1.0,
                  duration: Duration(milliseconds: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: controller.accounts.length,
                    itemBuilder: (context, index) {
                      final account = controller.accounts[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: _buildAccountCard(account),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showAccountInfoBottomSheet(Account account) {
    Get.bottomSheet(
      AccountInfoBottomSheet(account: account),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildAccountCard(Account account) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    account.accountNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    height: 22,
                    width: 42,
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    alignment: Alignment.center,
                    // padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          account.label == 'REAL'
                              ? AppColors.accent
                              : AppColors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      account.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color:
                            account.label == 'REAL'
                                ? AppColors.textPrimary
                                : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Equity',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                              color: AppColors.icongrey,
                            ),
                          ),
                          Text(
                            '\$${account.equity.toStringAsFixed(2)} ${account.currency}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 4),
                      SvgPicture.asset(
                        "assets/svg/info-circle.svg",
                        height: 24,
                        width: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Account Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              RichText(
                textAlign: TextAlign.start,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: ' ${account.type}\t\t',
                      style: TextStyle(
                        backgroundColor: AppColors.accent.withAlpha(50),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    TextSpan(
                      text: '\t${account.status}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.icongrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              // Trade icon
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackGround,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: SvgPicture.asset(
                  "assets/svg/bottom_navigation/candle_bold.svg",
                  height: 22,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12),

              // First Action (Always present)
              Expanded(
                child: _buildActionButton(
                  color: AppColors.green,
                  isSvg: true,
                  icon: Icons.add,
                  svg: 'assets/svg/deshboard/money-recive.svg',
                  label: account.actions[0],
                  onTap: () {
                    if (account.actions[0] == 'Deposit') {
                      controller.onDeposit(account.accountNumber);
                    }
                  },
                ),
              ),

              SizedBox(width: 12),

              // Second Action
              Expanded(
                child: _buildActionButton(
                  color:
                      account.actions[1] == 'Withdraw'
                          ? AppColors.red
                          : AppColors.primary,
                  isSvg: true,
                  svg:
                      account.actions.length > 1 &&
                              account.actions[1] == 'Withdraw'
                          ? "assets/svg/deshboard/money-send.svg"
                          : "assets/svg/bottom_navigation/setting.svg",
                  icon:
                      account.actions.length > 1 &&
                              account.actions[1] == 'Withdraw'
                          ? Icons.trending_down
                          : Icons.settings,
                  label:
                      account.actions.length > 1
                          ? account.actions[1]
                          : 'Settings',
                  onTap: () {
                    if (account.actions.length > 1) {
                      if (account.actions[1] == 'Withdraw') {
                        controller.onWithdraw(account.accountNumber);
                      } else {
                        controller.onSettings(account.accountNumber);
                      }
                    } else {
                      controller.onSettings(account.accountNumber);
                    }
                  },
                ),
              ),

              SizedBox(width: 6),

              // Three dots button with onTap functionality
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                decoration: BoxDecoration(
                  color: Color(0xffFBF5FF),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: GestureDetector(
                  onTap: () => _showAccountInfoBottomSheet(account),
                  child: SvgPicture.asset(
                    "assets/svg/deshboard/Three_dot.svg",
                    height: 21,
                    color: AppColors.primary,
                  ),
                ),
              ),

              // More Options
            ],
          ),

          // Switch to Trade Button (only for some accounts)
          if (account.label == 'DEMO' ||
              (account.actions.contains('Withdraw'))) ...[
            SizedBox(height: 14),
            Container(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    () => controller.switchToTrade(account.accountNumber),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/svg/deshboard/switch_icon.svg",
                      height: 18,
                      color: AppColors.primary,
                    ),
                    // Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Switch to Trade',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    bool? isSvg,
    String? svg,
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color!.withAlpha(20),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            (isSvg == true)
                ? SvgPicture.asset(svg!, height: 18, width: 18, color: color)
                : Icon(icon, color: AppColors.primary, size: 18),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountInfoBottomSheet extends StatelessWidget {
  final Account account;

  const AccountInfoBottomSheet({Key? key, required this.account})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Account Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Account Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          account.accountNumber,
                          style: TextStyle(
                            fontSize: 16.sp,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                account.label == 'REAL'
                                    ? AppColors.accent
                                    : AppColors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            account.label,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  account.label == 'REAL'
                                      ? AppColors.textPrimary
                                      : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            child: Container(
                              height: 15.h,
                              width: 29.w,
                              padding: EdgeInsets.only(left: 4.w, right: 4.w),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withAlpha(50),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                              child: Text.rich(
                                TextSpan(
                                  text: 'MT5',
                                  style: AppTextStyles.grey10400,
                                ),
                              ),
                            ),
                          ),
                          TextSpan(
                            text: ' Standard',
                            style: AppTextStyles.grey10400,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Equity Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Equity',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.icongrey,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '\$${account.equity.toStringAsFixed(2)} USD',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Account Details
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildDetailRow('Balance', '\$0 USD'),
                _buildDetailRow('Equity', '\$0 USD'),
                _buildDetailRow('Total P/L', '\$0 USD'),
                _buildDetailRow('Margin', '\$0 USD'),
                _buildDetailRow('Free Margin', '\$0 USD'),
                _buildDetailRow('Margin Level', ''),
                _buildDetailRow('Max. Leverage', '1:500'),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical:
                  MediaQuery.of(context).padding.bottom -
                  MediaQuery.of(context).size.height * 0.03,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    isSvg: true,
                    color: AppColors.green,
                    svg: 'assets/svg/deshboard/money-recive.svg',
                    icon: Icons.arrow_upward,
                    label: 'Deposit',
                    onTap: () {
                      Get.back();
                      Get.find<DashboardController>().onDeposit(
                        account.accountNumber,
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    isSvg: true,
                    color: AppColors.red,
                    svg: 'assets/svg/deshboard/money-send.svg',
                    icon: Icons.arrow_downward,
                    label: 'Withdraw',
                    onTap: () {
                      Get.back();
                      Get.find<DashboardController>().onWithdraw(
                        account.accountNumber,
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    color: AppColors.primary,
                    icon: Icons.swap_horiz,
                    label: 'Transfer',
                    onTap: () {
                      Get.back();
                      Get.to(() => InternalTransferScreen());

                      // Navigate to transfer screen
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
              height: 1.375,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.icongrey,
              fontWeight: FontWeight.w400,
              height: 1.57,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    bool? isSvg,
    String? svg,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withAlpha(20),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            (isSvg == true)
                ? SvgPicture.asset(svg!, height: 18, width: 18, color: color)
                : Icon(icon, size: 18, color: color),
            SizedBox(width: 6),

            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpenAccountBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(height: 24),

          // Title
          Text(
            'Open Account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 8),

          // Subtitle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Open a trading account to get superior trading conditions any strategy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),

          SizedBox(height: 15),

          // Real Account Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: GestureDetector(
              onTap: controller.openRealAccount,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'Real',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 8),

          // Demo Account Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: GestureDetector(
              onTap: controller.openDemoAccount,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'Demo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 8),

          // Cancel Button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
