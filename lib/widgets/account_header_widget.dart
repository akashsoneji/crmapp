import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/dashboard_controller.dart';

class AccountHeaderWidget extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final bool showSearchIcon;
  final bool showMenuIcon;
  final Widget? rightWidget;
  final EdgeInsets? padding;

  const AccountHeaderWidget({
    super.key,
    this.onMenuTap,
    this.onSearchTap,
    this.showSearchIcon = true,
    this.showMenuIcon = true,
    this.rightWidget,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final AccountController accountController = Get.find<AccountController>();

    return Container(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          if (showMenuIcon) ...[
            SvgPicture.asset("assets/svg/menu.svg", height: 24.h, width: 24.w),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            accountController.activeMT5Account != null
                                ? '\$${accountController.activeMT5Account!.balance}'
                                : '\$0.00',
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
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
                                color: _getAccountTypeColor(accountController),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getAccountTypeText(
                                  accountController,
                                ).toUpperCase(),
                                style: TextStyle(
                                  color: _getAccountTypeTextColor(
                                    accountController,
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
                                _getAccountNumber(accountController),
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
    );
  }

  Color _getAccountTypeColor(AccountController accountController) {
    // Use activeMT5Account if available, otherwise fallback to first account
    if (accountController.activeMT5Account != null) {
      final accountType = accountController.activeMT5Account!.accountType;
      return accountType.toLowerCase() == "live"
          ? AppColors.accent
          : AppColors.blue;
    } else if (accountController.mt5Accounts.isNotEmpty) {
      final firstAccount = accountController.mt5Accounts.first;
      return firstAccount.accountType.toLowerCase() == "live"
          ? AppColors.accent
          : AppColors.blue;
    }
    // Default color when no accounts are available
    return AppColors.blue;
  }

  String _getAccountTypeText(AccountController accountController) {
    if (accountController.activeMT5Account != null) {
      final accountType = accountController.activeMT5Account!.accountType;
      // Map account types to display text
      switch (accountType.toLowerCase()) {
        case 'live':
          return 'REAL';
        case 'demo':
          return 'DEMO';
        default:
          return accountType.toUpperCase();
      }
    }
    return 'REAL'; // Default fallback
  }

  Color _getAccountTypeTextColor(AccountController accountController) {
    // Safe access to activeAccount with null check
    if (accountController.activeAccount?.type == "REAL") {
      return AppColors.textPrimary;
    }
    return AppColors.whiteColor;
  }

  String _getAccountNumber(AccountController accountController) {
    // Use activeMT5Account if available, otherwise fallback to first account
    if (accountController.activeMT5Account != null) {
      return accountController.activeMT5Account!.metaAccountNumber;
    } else if (accountController.mt5Accounts.isNotEmpty) {
      return accountController.mt5Accounts.first.metaAccountNumber;
    }
    return '0'; // Default account number
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

          return Container(
            height: dynamicHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
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
                          final account = accountController.mt5Accounts[index];
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
                                    account.accountType,
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
                                    await accountController.setActiveMT5Account(
                                      value!,
                                    );
                                  } catch (e) {
                                    print('Account switch failed: $e');
                                  } finally {
                                    Get.back();
                                    // Always close the bottom sheet after API call
                                    // await Future.delayed(
                                    //   const Duration(milliseconds: 300),
                                    // );

                                    // // Close any open dialogs/loading overlays
                                    // if (Get.isDialogOpen ?? false) {
                                    //   Get.back();
                                    // }

                                    // // Then close the bottom sheet
                                    // if (Get.isBottomSheetOpen ?? false) {
                                    //   Get.back();
                                    // }

                                    // Refresh accounts in background after bottom sheet closes
                                    // Future.delayed(
                                    //   const Duration(milliseconds: 200),
                                    //   () {
                                    //     try {
                                    //       final dashboardController =
                                    //           Get.find<DashboardController>();
                                    //       dashboardController
                                    //           .checkMT5Accounts();
                                    //     } catch (e) {
                                    //       print(
                                    //         'Error refreshing accounts: $e',
                                    //       );
                                    //     }
                                    //   },
                                    // );
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
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        });
      },
    );
  }
}
