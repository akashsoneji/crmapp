import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/models/mt5_account.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/services/language_service.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/account_controller.dart';
import '../../widgets/common_loading_widget.dart';
import '../auth/register/account_created_screen.dart';
import 'more/finance/internal_transfer_screen.dart';
import 'more/finance/transaction_history_screen.dart';
import 'more/more_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  DashboardScreen({this.onNavigateToTab});

  late final DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    // Opportunistic, throttled refresh whenever Dashboard appears
    controller.maybeRefreshOnAppear();
    // Set the navigation callback in the controller
    if (onNavigateToTab != null) {
      controller.setNavigationCallback(onNavigateToTab!);
    }

    return Scaffold(
      // backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SvgPicture.asset(
            "assets/svg/menu.svg",
            height: 18.h,
            width: 18.w,
          ),
        ),
        title: Text(
          languageService.tr('dashboard_title'),
          style: AppTextStyles.screenTitle,
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 0),
            child: IconButton(
              icon: SvgPicture.asset(
                "assets/svg/deshboard/empty-wallet-add.svg",
              ),
              onPressed: () {
                Get.toNamed(AppPages.WALLET);
              },
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
        () => Container(
          color: AppColors.tradeBackgroundCenterColor,
          child: Stack(
            children: [
              // Main Content
              (controller.mt5Accounts.isEmpty)
                  ? Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 22.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FutureBuilder<Widget>(
                          future: SvgColorHelper.loadSvgWithColor(
                            assetPath: 'assets/svg/deshboard/no_account.svg',
                            targetColor: AppColors.primary,
                            colorToReplace:
                                '#5F259E', // Replace this color in the SVG
                            height: 100.h,
                            width: 100.w,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) return snapshot.data!;
                            return SizedBox(height: 100.h, width: 100.w);
                          },
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          languageService.tr('dashboard_new_account_title'),
                          style: AppTextStyles.heading,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 14.h),

                        Text(
                          languageService.tr(
                            'dashboard_new_account_description',
                          ),
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
                              languageService.tr('dashboard_open_real_account'),
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
                              side: BorderSide(
                                color: AppColors.backgroundLight,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () {
                              controller.openDemoAccount();
                            },
                            child: Text(
                              languageService.tr('dashboard_open_demo_account'),
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
                      // Performance optimizations
                      cacheExtent: 500, // Cache 500 pixels worth of items
                      addAutomaticKeepAlives:
                          false, // Don't keep off-screen items alive
                      addRepaintBoundaries:
                          true, // Add repaint boundaries for better performance
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom:
                            16 + 77.h + MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount: controller.mt5Accounts.length,
                      itemBuilder: (context, index) {
                        final account = controller.mt5Accounts[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: _buildAccountCard(account),
                        );
                      },
                    ),
                  ),
              // Overlay loading indicator
              controller.isLoadingMT5Accounts.value
                  ? Center(child: CommonLoadingWidget(isFullScreen: true))
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountInfoBottomSheet(MT5Account account) {
    Get.bottomSheet(
      AccountInfoBottomSheet(account: account),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showAccountMenuBottomSheet(MT5Account account) {
    Get.bottomSheet(
      AccountMenuBottomSheet(account: account),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildAccountCard(MT5Account account) {
    final dashboardController = Get.find<DashboardController>();

    return Obx(() {
      final accountInfo = dashboardController.getAccountInfo(
        account.metaAccountNumber,
      );

      return _buildAccountCardContent(account, accountInfo);
    });
  }

  Widget _buildAccountCardContent(
    MT5Account account,
    AccountInfo? accountInfo,
  ) {
    final languageService = Get.find<LanguageService>();
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
                    account.metaAccountNumber,
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
                          account.accountType == 'live'
                              ? AppColors.accent
                              : AppColors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      account.accountType.capitalizeFirst ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color:
                            account.accountType == 'live'
                                ? AppColors.whiteColor
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
                            languageService.tr('dashboard_equity'),
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                              color: AppColors.icongrey,
                            ),
                          ),
                          Text(
                            accountInfo != null
                                ? '\$${accountInfo.equity.toStringAsFixed(2)}'
                                : '\$${account.equity}',
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
                      InkWell(
                        onTap: () => _showAccountInfoBottomSheet(account),
                        child: SvgPicture.asset(
                          "assets/svg/info-circle.svg",
                          height: 24,
                          width: 24,
                        ),
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
                      text: ' ${account.accountType.capitalizeFirst}\t\t',
                      style: TextStyle(
                        backgroundColor: AppColors.accent.withAlpha(50),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    TextSpan(
                      text: '\t${account.masterGroupId}',
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
              // Trade icon with InkWell
              InkWell(
                onTap: () async {
                  // Call setActiveMT5Account which handles socket reconnection
                  final accountController = Get.find<AccountController>();
                  await accountController.setActiveMT5Account(
                    account.metaAccountNumber,
                  );
                  // Navigate to TradingMainScreen (first tab - Instruments/Quotes)
                  // Get.toNamed(AppPages.TRADING);
                },
                borderRadius: BorderRadius.circular(5),
                child: Container(
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
              ),
              SizedBox(width: 12),

              // First Action (Always present)
              Expanded(
                child: _buildActionButton(
                  color: AppColors.green,
                  isSvg: true,
                  icon: Icons.add,
                  svg: 'assets/svg/deshboard/money-recive.svg',
                  // label: account.actions[0],
                  label: languageService.tr('dashboard_deposit'),
                  onTap: () {
                    if (account.accountType.toLowerCase() == 'live') {
                      controller.onDepositRealAccount(
                        account.metaAccountNumber,
                      );
                    } else {
                      controller.onDeposit(account.metaAccountNumber);
                    }
                  },
                ),
              ),

              SizedBox(width: 12),

              // Second Action
              Expanded(
                child: _buildActionButton(
                  color:
                      account.accountType.toLowerCase() == 'live'
                          ? AppColors.red
                          : AppColors.primary,
                  isSvg: true,
                  svg:
                      account.accountType.toLowerCase() == 'live'
                          ? "assets/svg/deshboard/money-send.svg"
                          : "assets/svg/bottom_navigation/setting.svg",
                  icon:
                      account.accountType.toLowerCase() == 'live'
                          ? Icons.trending_down
                          : Icons.settings,
                  label:
                      account.accountType.toLowerCase() == 'live'
                          ? languageService.tr('dashboard_withdraw')
                          : languageService.tr('more_settings'),
                  onTap: () {
                    if (account.accountType.toLowerCase() == 'live') {
                      controller.onWithdraw(account.metaAccountNumber);
                    } else {
                      controller.onSettings(account.metaAccountNumber);
                    }
                  },
                ),
              ),

              SizedBox(width: 6),

              // Three dots button with onTap functionality
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.cardBackGround,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: GestureDetector(
                  onTap: () => _showAccountMenuBottomSheet(account),
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
          if (!account.isPrimaryAccount) ...[
            SizedBox(height: 14),
            Container(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    () => controller.switchToTrade(account.metaAccountNumber),
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
                    SizedBox(width: 8),
                    Text(
                      languageService.tr('dashboard_switch_to_trade'),
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
          color: color.withAlpha(20),
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
  final MT5Account account;

  const AccountInfoBottomSheet({Key? key, required this.account})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();

    return Obx(() {
      final accountInfo = dashboardController.getAccountInfo(
        account.metaAccountNumber,
      );

      return _buildContent(context, accountInfo);
    });
  }

  Widget _buildContent(BuildContext context, AccountInfo? accountInfo) {
    final languageService = Get.find<LanguageService>();
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
                          account.metaAccountNumber,
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
                                account.accountType == 'live'
                                    ? AppColors.accent
                                    : AppColors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            account.accountType.capitalizeFirst ?? '',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  account.accountType == 'live'
                                      ? AppColors.whiteColor
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
                              // width: 29.w,
                              padding: EdgeInsets.only(left: 4.w, right: 4.w),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withAlpha(50),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                              child: Text.rich(
                                TextSpan(
                                  text: account.tradingServer.capitalizeFirst,
                                  style: AppTextStyles.grey10400,
                                ),
                              ),
                            ),
                          ),
                          TextSpan(
                            text: "  ${account.masterGroupId}",
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
                      languageService.tr('dashboard_equity'),
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
                          accountInfo != null
                              ? '\$${accountInfo.equity.toStringAsFixed(2)} USD'
                              : '\$${account.equity} USD',
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
                _buildDetailRow(
                  languageService.tr('dashboard_balance'),
                  accountInfo != null
                      ? '\$${accountInfo.balance.toStringAsFixed(2)} USD'
                      : '\$${account.balance} USD',
                ),
                _buildDetailRow(
                  languageService.tr('dashboard_equity'),
                  accountInfo != null
                      ? '\$${accountInfo.equity.toStringAsFixed(2)} USD'
                      : '\$${account.equity} USD',
                ),
                _buildDetailRow(
                  languageService.tr('dashboard_total_pl'),
                  accountInfo != null
                      ? '\$${accountInfo.profit.toStringAsFixed(2)} USD'
                      : '\$0.00 USD',
                ),
                _buildDetailRow(
                  languageService.tr('trade_metric_margin'),
                  accountInfo != null
                      ? '\$${accountInfo.margin.toStringAsFixed(2)} USD'
                      : '\$${account.margin} USD',
                ),
                _buildDetailRow(
                  languageService.tr('trade_metric_free_margin'),
                  accountInfo != null
                      ? '\$${accountInfo.marginFree.toStringAsFixed(2)} USD'
                      : '\$${account.freeMargin} USD',
                ),
                _buildDetailRow(
                  languageService.tr('trade_metric_margin_level'),
                  accountInfo != null && accountInfo.marginLevel > 0
                      ? '${accountInfo.marginLevel.toStringAsFixed(2)}%'
                      : account.marginLevel.isNotEmpty &&
                          account.marginLevel != '0'
                      ? '${account.marginLevel}%'
                      : '-',
                ),
                _buildDetailRow(
                  languageService.tr('dashboard_max_leverage'),
                  '1:500',
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Original Action Buttons (Deposit, Withdraw, Transfer)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: MediaQuery.of(context).padding.bottom > 0 ? 0 : 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    isSvg: true,
                    color: AppColors.green,
                    svg: 'assets/svg/deshboard/money-recive.svg',
                    icon: Icons.arrow_upward,
                    label: languageService.tr('dashboard_deposit'),
                    onTap: () {
                      Get.back();
                      if (account.accountType.toLowerCase() == 'live') {
                        Get.find<DashboardController>().onDepositRealAccount(
                          account.metaAccountNumber,
                        );
                      } else {
                        Get.find<DashboardController>().onDeposit(
                          account.metaAccountNumber,
                        );
                      }
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
                    label: languageService.tr('dashboard_withdraw'),
                    onTap: () {
                      Get.back();
                      Get.find<DashboardController>().onWithdraw(
                        account.metaAccountNumber,
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    color: AppColors.primary,
                    icon: Icons.swap_horiz,
                    label: languageService.tr('dashboard_transfer'),
                    onTap: () {
                      Get.back();
                      Get.to(() => InternalTransferScreen());
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

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

class AccountMenuBottomSheet extends StatelessWidget {
  final MT5Account account;

  const AccountMenuBottomSheet({Key? key, required this.account})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
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

          // Menu Items
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.swap_horiz,
                  label: languageService.tr('dashboard_transfer'),
                  onTap: () {
                    Get.back();
                    Get.to(() => InternalTransferScreen());
                  },
                ),
                SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.card_giftcard,
                  label: languageService.tr('dashboard_bonus'),
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      languageService.tr('common_coming_soon'),
                      languageService.tr('dashboard_bonus_coming_soon_message'),
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.history,
                  label: languageService.tr('dashboard_history'),
                  onTap: () {
                    Get.back();
                    Get.to(
                      () => TransactionHistoryScreen(),
                      arguments: {'from': 'dashboard'},
                    );
                  },
                ),
                SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.settings,
                  label: languageService.tr('more_settings'),
                  onTap: () {
                    Get.back();
                    Get.to(() => MoreScreen());
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Cancel Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              margin: EdgeInsets.only(bottom: 10.h),

              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  languageService.tr('navigation_cancel'),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.red,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.primary),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.icongrey),
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
    final languageService = Get.find<LanguageService>();
    return SafeArea(
      child: Container(
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
              languageService.tr('dashboard_open_account'),
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
                languageService.tr('dashboard_open_account_subtitle'),
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
                      languageService.tr('dashboard_live'),
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
                      languageService.tr('dashboard_demo'),
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
                    languageService.tr('navigation_cancel'),
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
      ),
    );
  }
}
