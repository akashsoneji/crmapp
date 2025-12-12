import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/dashboard_controller.dart';
import 'package:pipze/models/mt5_account.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/utils/precision_helper.dart';

class AccountHeaderWidget extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final bool showSearchIcon;
  final bool showMenuIcon;
  final Widget? rightWidget;
  final EdgeInsets? padding;
  final double? floatingProfit;

  const AccountHeaderWidget({
    super.key,
    this.onMenuTap,
    this.onSearchTap,
    this.showSearchIcon = true,
    this.showMenuIcon = true,
    this.rightWidget,
    this.padding,
    this.floatingProfit,
  });

  @override
  Widget build(BuildContext context) {
    final AccountController accountController = Get.find<AccountController>();
    // Get DashboardController for primary account (like dashboard screen)
    final DashboardController? dashboardController =
        Get.isRegistered<DashboardController>()
            ? Get.find<DashboardController>()
            : null;

    return SafeArea(
      child: Container(
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            if (showMenuIcon) ...[
              SvgPicture.asset(
                "assets/svg/menu.svg",
                height: 24.h,
                width: 24.w,
              ),
              // InkWell(
              //   onTap:
              //       onMenuTap ??
              //       () {
              //         Scaffold.of(context).openDrawer();
              //       },
              //   child: SvgPicture.asset(
              //     "assets/svg/menu.svg",
              //     height: 24.h,
              //     width: 24.w,
              //   ),
              // ),
              SizedBox(width: 6.w),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    // ✅ FIX: Observe active account from AccountController to react immediately to account switches
                    final activeAccount = accountController.activeMT5Account;

                    // ✅ FIX: Use primary account from DashboardController (like dashboard screen)
                    // But prefer activeAccount if available (more reactive to account switches)
                    final primaryAccount =
                        activeAccount ?? dashboardController?.primaryMT5Account;

                    // ✅ FIX: Directly observe accountInfoMap to react to WebSocket updates
                    // Access accountInfoMap directly to ensure GetX tracks changes to the RxMap
                    final accountInfoMap = dashboardController?.accountInfoMap;

                    // Check if WebSocket is connected
                    final isWebSocketConnected =
                        dashboardController?.isWebSocketConnected ?? false;

                    // Get account info from WebSocket (real-time) if available
                    AccountInfo? accountInfo;
                    if (primaryAccount != null && accountInfoMap != null) {
                      // Directly access the map to ensure reactivity - GetX will track this access
                      accountInfo =
                          accountInfoMap[primaryAccount.metaAccountNumber];
                    }

                    // Get equity from WebSocket AccountInfo (real-time) if available, otherwise from account's equity
                    final double? realTimeEquity = accountInfo?.equity;
                    final double? apiEquity =
                        primaryAccount != null
                            ? double.tryParse(primaryAccount.equity)
                            : null;

                    // Use real-time equity if available, otherwise fallback to API equity
                    final double displayEquity =
                        realTimeEquity ?? (apiEquity ?? 0.0);

                    // Determine if we should show loading indicator
                    // Show loading if:
                    // 1. We have a primary account
                    // 2. But no WebSocket data yet (realTimeEquity is null)
                    // 3. AND WebSocket is not connected OR accountInfoMap doesn't have the account yet
                    final bool hasAccountInfo =
                        primaryAccount != null &&
                        accountInfoMap != null &&
                        accountInfoMap.containsKey(
                          primaryAccount.metaAccountNumber,
                        );
                    final bool showLoading =
                        primaryAccount != null &&
                        realTimeEquity == null &&
                        (!isWebSocketConnected || !hasAccountInfo) &&
                        displayEquity ==
                            0.0; // Only show loading if equity is 0 (not yet loaded)

                    // Ensure WebSocket is initialized when widget builds
                    if (primaryAccount != null && dashboardController != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        dashboardController.ensureWebSocketInitialized();
                      });
                    }

                    // If floatingProfit is provided, use it instead of equity
                    final bool useFloatingProfit = floatingProfit != null;
                    final double displayValue =
                        useFloatingProfit ? floatingProfit! : displayEquity;
                    final bool isPositive = displayValue >= 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (showLoading && !useFloatingProfit) ...[
                              LoadingAnimationWidget.fourRotatingDots(
                                color: AppColors.primary,
                                size: 18.w,
                              ),
                              SizedBox(width: 8.w),
                            ],
                            Text(
                              useFloatingProfit
                                  ? '\$${PrecisionHelper.formatPnL(displayValue)}'
                                  : '\$${displayEquity.toStringAsFixed(2)}',
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color:
                                    useFloatingProfit
                                        ? (isPositive
                                            ? AppColors.success
                                            : AppColors.error)
                                        : null,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // Connection status indicator
                            //   if (instrumentsController != null)
                            //     Obx(() {
                            //       if (instrumentsController.isReconnecting.value) {
                            //         return SizedBox(
                            //           width: 12.w,
                            //           height: 12.h,
                            //           child: CircularProgressIndicator(
                            //             strokeWidth: 2,
                            //             valueColor: AlwaysStoppedAnimation<Color>(
                            //               AppColors.accent,
                            //             ),
                            //           ),
                            //         );
                            //       } else if (instrumentsController
                            //           .isConnected
                            //           .value) {
                            //         return Container(
                            //           width: 8.w,
                            //           height: 8.h,
                            //           decoration: BoxDecoration(
                            //             color: AppColors.green,
                            //             shape: BoxShape.circle,
                            //           ),
                            //         );
                            //       } else {
                            //         return GestureDetector(
                            //           onTap:
                            //               () =>
                            //                   instrumentsController
                            //                       .manualReconnect(),
                            //           child: Container(
                            //             width: 8.w,
                            //             height: 8.h,
                            //             decoration: BoxDecoration(
                            //               color: AppColors.red,
                            //               shape: BoxShape.circle,
                            //             ),
                            //           ),
                            //         );
                            //       }
                            //     }),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            accountController.resetToDefaultAccounts();
                            _showAccountSelectionBottomSheet(
                              context,
                              accountController,
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: 45.w,
                                height: 22.h,
                                decoration: BoxDecoration(
                                  color: _getAccountTypeColor(primaryAccount),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getAccountTypeText(
                                    primaryAccount,
                                  ).toUpperCase(),
                                  style: TextStyle(
                                    color: _getAccountTypeTextColor(
                                      primaryAccount,
                                    ),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              SizedBox(
                                height: 22.h,
                                width: 75.w,
                                child: Text(
                                  _getAccountNumber(primaryAccount),
                                  textAlign: TextAlign.start,
                                  style: AppTextStyles.subheading.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16.h,
                                color: AppColors.textGrey,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            if (rightWidget != null) ...[
              rightWidget!,
            ] else if (showSearchIcon) ...[
              GestureDetector(
                onTap: onSearchTap,
                child: SvgPicture.asset(
                  "assets/svg/search-normal.svg",
                  height: 24.h,
                  width: 24.w,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ FIX: Updated to use primary account (MT5Account) instead of AccountController
  Color _getAccountTypeColor(MT5Account? primaryAccount) {
    if (primaryAccount != null) {
      final accountType = primaryAccount.accountType;
      return accountType.toLowerCase() == "live"
          ? AppColors.accent
          : AppColors.primary;
    }
    // Default color when no accounts are available
    return AppColors.primary;
  }

  String _getAccountTypeText(MT5Account? primaryAccount) {
    if (primaryAccount != null) {
      final accountType = primaryAccount.accountType;
      // Map account types to display text
      switch (accountType.toLowerCase()) {
        case 'live':
          return 'Live';
        case 'demo':
          return 'DEMO';
        default:
          return accountType.toUpperCase();
      }
    }
    return 'Live'; // Default fallback
  }

  Color _getAccountTypeTextColor(MT5Account? primaryAccount) {
    // Always white text for better contrast
    return AppColors.whiteColor;
  }

  String _getAccountNumber(MT5Account? primaryAccount) {
    // ✅ FIX: Use primary account number (like dashboard screen)
    if (primaryAccount != null) {
      return primaryAccount.metaAccountNumber;
    }
    return 'No Account'; // Default account number
  }

  void _showAccountSelectionBottomSheet(
    BuildContext context,
    AccountController accountController,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Obx(() {
          double dynamicHeight;
          if (accountController.accounts.length <= 2) {
            dynamicHeight = MediaQuery.of(context).size.height * 0.35;
          } else if (accountController.accounts.length <= 3) {
            dynamicHeight = MediaQuery.of(context).size.height * 0.45;
          } else if (accountController.accounts.length <= 4) {
            dynamicHeight = MediaQuery.of(context).size.height * 0.55;
          } else {
            dynamicHeight = MediaQuery.of(context).size.height * 0.65;
          }

          // Compute insets for iOS/Android
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final systemPadding = MediaQuery.of(context).padding.bottom;

          return Padding(
            padding: EdgeInsets.only(
              bottom:
                  bottomInset +
                  (defaultTargetPlatform == TargetPlatform.android
                      ? systemPadding
                      : 0),
            ),
            child: Container(
              height: dynamicHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                  // bottomLeft and bottomRight are not set, so only top corners are rounded
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Account',
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                  accountController.isLoading
                      ? Expanded(
                        child: Container(
                          padding: EdgeInsets.all(20.w),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                      : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: accountController.mt5Accounts.length,
                          itemBuilder: (context, index) {
                            final account =
                                accountController.mt5Accounts[index];
                            final isActive =
                                accountController
                                    .activeMT5Account
                                    ?.metaAccountNumber ==
                                account.metaAccountNumber;
                            return Container(
                              child: ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color:
                                        account.accountType == 'live'
                                            ? AppColors.primary
                                            : AppColors.success,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: 20.h,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      account.accountType.capitalizeFirst ?? '',
                                      style: AppTextStyles.label.copyWith(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      SizedBox(width: 8.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: AppTextStyles.label.copyWith(
                                            fontSize: 8.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID: ${account.metaAccountNumber}',
                                      style: AppTextStyles.label.copyWith(
                                        fontSize: 12.sp,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                    Text(
                                      '\$${account.balance}',
                                      style: AppTextStyles.label.copyWith(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Radio<String>(
                                  value: account.metaAccountNumber,
                                  groupValue:
                                      accountController
                                          .activeMT5Account
                                          ?.metaAccountNumber,
                                  onChanged: (value) async {
                                    // Disable the radio button while loading
                                    if (accountController.isLoading) {
                                      return;
                                    }

                                    try {
                                      // Call API to switch account
                                      await accountController
                                          .setActiveMT5Account(value!);
                                    } catch (e) {
                                      if (kDebugMode) {
                                        print('Account switch failed: $e');
                                      }
                                    } finally {
                                      // Close bottom sheet AFTER account switch completes
                                      // Wait for loading to finish
                                      if (accountController.isLoading) {
                                        // Wait until loading is false
                                        await Future.delayed(
                                          const Duration(milliseconds: 100),
                                        );
                                        // Check again
                                        int attempts = 0;
                                        while (accountController.isLoading &&
                                            attempts < 20) {
                                          await Future.delayed(
                                            const Duration(milliseconds: 100),
                                          );
                                          attempts++;
                                        }
                                      }

                                      // Close the bottom sheet
                                      if (Get.isBottomSheetOpen ?? false) {
                                        Get.back();
                                      }
                                    }
                                  },
                                  activeColor: AppColors.primary,
                                ),
                                tileColor:
                                    isActive
                                        ? AppColors.primary.withOpacity(0.1)
                                        : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
