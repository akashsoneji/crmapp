import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';

import 'package:pipze/services/language_service.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/widgets/dashBorder.dart';
import 'package:pipze/widgets/global_drawer.dart';
import 'package:pipze/screens/home/order_history_screen.dart';
import 'package:pipze/screens/home/edit_order_screen.dart';

class TradeScreen extends StatelessWidget {
  const TradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final accountController = Get.find<AccountController>();
    final tradingController = Get.find<TradingController>();

    return Obx(() {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        drawer: const GlobalDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(accountController),

              DashedUnderline(
                dashWidth: 10,
                dashSpace: 0,
                color: AppColors.grey,
              ),

              // Title
              _buildTitle(languageService),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildTabs(tradingController),
              ),

              _buildFloatingSummary(tradingController),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: MediaQuery.of(Get.context!).size.width / 2.7,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackGround,
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: InkWell(
                        onTap:
                            () =>
                                _showInstrumentsBottomSheet(tradingController),
                        child: Row(
                          children: [
                            Text(
                              'Instruments',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(Icons.keyboard_arrow_down, size: 20.h),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      width: MediaQuery.of(Get.context!).size.width / 2.7,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackGround,
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: InkWell(
                        onTap:
                            () => _showDirectionBottomSheet(tradingController),
                        child: Row(
                          children: [
                            Text(
                              'Direction',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(Icons.keyboard_arrow_down, size: 20.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Trade Positions List
              Expanded(child: _buildPositionsList(tradingController)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(AccountController accountController) {
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final isSmallScreen = screenWidth < 400;
    final isLargeScreen = screenWidth > 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Menu icon
          Expanded(
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    Scaffold.of(Get.context!).openDrawer();
                  },
                  child: SvgPicture.asset(
                    "assets/svg/menu.svg",
                    height: 24.h,
                    width: 24.w,
                  ),
                ),
                SizedBox(width: 6.w),
                // Balance and account info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic Balance Display
                      Obx(() {
                        final activeAccount = accountController.activeAccount;
                        return Text(
                          '\$${activeAccount?.balance.toStringAsFixed(2) ?? '0.00'}',
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }),
                      // Account selector
                      GestureDetector(
                        onTap: () {
                          accountController.resetToDefaultAccounts();
                          _showAccountSelectionBottomSheet(accountController);
                        },
                        child: Row(
                          children: [
                            Obx(() {
                              final activeAccount =
                                  accountController.activeAccount;
                              return Text(
                                '${activeAccount?.type} ${activeAccount?.id}',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.textGrey,
                                ),
                              );
                            }),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16.h,
                              color: AppColors.textGrey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SvgPicture.asset(
            "assets/svg/info-circle.svg",
            height: 24.h,
            width: 24.w,
          ),

          SizedBox(width: 22.w),
          SvgPicture.asset("assets/svg/star.svg", height: 22.h, width: 22.w),

          // Account header widget
          if (!isSmallScreen) ...[
            SizedBox(width: 8.w),
            const AccountHeaderWidget(),
          ],
        ],
      ),
    );
  }

  Widget _buildTitle(LanguageService languageService) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Text(
            languageService.tr('trade_title'),
            style: AppTextStyles.heading.copyWith(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Add any additional header buttons here
        ],
      ),
    );
  }

  Widget _buildTabs(TradingController tradingController) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(tradingController, 0, 'Market'),
          _buildTabItem(tradingController, 1, 'Pending'),
          _buildTabItem(tradingController, 2, 'Close'),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    TradingController tradingController,
    int index,
    String title,
  ) {
    return Obx(() {
      final isSelected = tradingController.selectedTab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => tradingController.setSelectedTab(index),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              // color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2.w,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textGrey,
                  ),
                ),
                SizedBox(width: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.cardBackGround
                            : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _getPositionCount(tradingController, index).toString(),
                    style: AppTextStyles.label.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? AppColors.primary : AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  int _getPositionCount(TradingController tradingController, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return tradingController.marketPositions.length;
      case 1:
        return tradingController.pendingPositions.length;
      case 2:
        return tradingController.closedPositions.length;
      default:
        return 0;
    }
  }

  Widget _buildFloatingSummary(TradingController tradingController) {
    return Obx(() {
      final positions = tradingController.getFilteredPositions();
      final totalProfitLoss = positions.fold<double>(
        0,
        (sum, position) => sum + position.profitLoss,
      );
      final isPositive = totalProfitLoss >= 0;

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.cardBackGround,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            width: 1,
            // color: isPositive ? AppColors.success : AppColors.error,
            color: AppColors.cardBackGround,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 8.w),
            RichText(
              text: TextSpan(
                style: AppTextStyles.label.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.icongrey, // base/default color
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Floating profit:\n'),
                  TextSpan(
                    text: '\$${totalProfitLoss.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
            if (positions.isNotEmpty)
              TextButton(
                onPressed:
                    () => _showClosePositionsBottomSheet(tradingController),
                child: Text(
                  'Close All',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterButtons(TradingController tradingController) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instrument Filter Button
          Row(
            children: [
              Text(
                'Instruments',
                style: AppTextStyles.label.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showInstrumentsBottomSheet(tradingController),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        final selectedCount =
                            tradingController.selectedInstruments.length;
                        final totalCount =
                            tradingController.availableInstruments.length;
                        return Text(
                          selectedCount == totalCount
                              ? 'All Instruments'
                              : '$selectedCount/$totalCount Selected',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        );
                      }),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16.h,
                        color: AppColors.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Direction Filter Button
          Row(
            children: [
              Text(
                'Direction',
                style: AppTextStyles.label.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showDirectionBottomSheet(tradingController),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        return Text(
                          tradingController.selectedDirection,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        );
                      }),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16.h,
                        color: AppColors.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionsList(TradingController tradingController) {
    return Obx(() {
      final positions = tradingController.getFilteredPositions();

      if (positions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/svg/trade/trade_pending_empty.svg'),
              SizedBox(height: 16.h),
              SizedBox(height: 8.h),
              Text(
                'You have no pending orders',
                style: AppTextStyles.subheading.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: positions.length,
        itemBuilder: (context, index) {
          final position = positions[index];
          return _buildPositionCard(tradingController, position);
        },
      );
    });
  }

  Widget _buildPositionCard(
    TradingController tradingController,
    TradePosition position,
  ) {
    final isPositive = position.profitLoss >= 0;

    return GestureDetector(
      onTap: () => _showPositionDetailsBottomSheet(tradingController, position),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Text(position.flag, style: TextStyle(fontSize: 30.sp)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              position.symbol,
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '\$${position.profitLoss.toStringAsFixed(2)}',
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color:
                                    isPositive
                                        ? AppColors.success
                                        : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  position.action == 'Buy'
                                      ? 'assets/svg/trade/green_up_icon.svg'
                                      : 'assets/svg/trade/red_down_icon.svg',
                                  height: 9.h,
                                  width: 9.w,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  position.action,
                                  style: AppTextStyles.label.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        position.action == 'Buy'
                                            ? AppColors.success
                                            : AppColors.error,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${position.volume}',
                                  style: AppTextStyles.label.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${position.entryPrice} --> ${position.currentPrice}',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Action buttons row
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //   children: [
              //     Expanded(
              //       child: OutlinedButton(
              //         onPressed:
              //             () => _showQuickCloseConfirmation(
              //               tradingController,
              //               position,
              //             ),
              //         style: OutlinedButton.styleFrom(
              //           side: BorderSide(color: AppColors.primary),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(8.r),
              //           ),
              //           padding: EdgeInsets.symmetric(vertical: 8.h),
              //         ),
              //         child: Text(
              //           'Close Position',
              //           style: AppTextStyles.label.copyWith(
              //             fontSize: 12.sp,
              //             fontWeight: FontWeight.w600,
              //             color: AppColors.primary,
              //           ),
              //         ),
              //       ),
              //     ),
              //     SizedBox(width: 8.w),
              //     Expanded(
              //       child: OutlinedButton(
              //         onPressed:
              //             () =>
              //                 Get.to(() => EditOrderScreen(position: position)),
              //         style: OutlinedButton.styleFrom(
              //           side: BorderSide(color: AppColors.success),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(8.r),
              //           ),
              //           padding: EdgeInsets.symmetric(vertical: 8.h),
              //         ),
              //         child: Text(
              //           'Modify',
              //           style: AppTextStyles.label.copyWith(
              //             fontSize: 12.sp,
              //             fontWeight: FontWeight.w600,
              //             color: AppColors.success,
              //           ),
              //         ),
              //       ),
              //     ),
              //     SizedBox(width: 8.w),
              //     Expanded(
              //       child: OutlinedButton(
              //         onPressed:
              //             () => _showPositionDetailsBottomSheet(
              //               tradingController,
              //               position,
              //             ),
              //         style: OutlinedButton.styleFrom(
              //           side: BorderSide(color: AppColors.textGrey),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(8.r),
              //           ),
              //           padding: EdgeInsets.symmetric(vertical: 8.h),
              //         ),
              //         child: Text(
              //           'Details',
              //           style: AppTextStyles.label.copyWith(
              //             fontSize: 12.sp,
              //             fontWeight: FontWeight.w600,
              //             color: AppColors.textGrey,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountSelectionBottomSheet(AccountController accountController) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    'Select Account',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Obx(() {
              if (accountController.isLoading) {
                return Container(
                  padding: EdgeInsets.all(20.w),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: accountController.accounts.length,
                itemBuilder: (context, index) {
                  final account = accountController.accounts[index];
                  final isActive =
                      accountController.activeAccount?.id == account.id;

                  return ListTile(
                    leading: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                        size: 20.h,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          account.type,
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
                              borderRadius: BorderRadius.circular(8.r),
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
                          'ID: ${account.id}',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                        Text(
                          '\$${account.balance.toStringAsFixed(2)}',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    trailing: Radio<String>(
                      value: account.id,
                      groupValue: accountController.activeAccount?.id,
                      onChanged: (value) {
                        if (value != null) {
                          accountController.setActiveAccount(value);
                          Get.back();
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      accountController.setActiveAccount(account.id);
                      Get.back();
                    },
                    tileColor:
                        isActive
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  );
                },
              );
            }),
            SizedBox(height: MediaQuery.of(Get.context!).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showInstrumentsBottomSheet(TradingController tradingController) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    'Select Instruments',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: tradingController.availableInstruments.length,
                itemBuilder: (context, index) {
                  final instrument =
                      tradingController.availableInstruments.toList()[index];
                  return Obx(() {
                    final isSelected = tradingController.selectedInstruments
                        .contains(instrument);
                    return ListTile(
                      title: Text(
                        instrument,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          if (value == true) {
                            tradingController.addInstrument(instrument);
                          } else {
                            tradingController.removeInstrument(instrument);
                          }
                        },
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      onTap: () {
                        if (isSelected) {
                          tradingController.removeInstrument(instrument);
                        } else {
                          tradingController.addInstrument(instrument);
                        }
                      },
                      tileColor:
                          isSelected
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    );
                  });
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        tradingController.clearInstruments();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Clear All',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        tradingController.availableInstruments.forEach((
                          instrument,
                        ) {
                          tradingController.addInstrument(instrument);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Select All',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(Get.context!).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showDirectionBottomSheet(TradingController tradingController) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    'Select Direction',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: ['All', 'Buy', 'Sell'].length,
              itemBuilder: (context, index) {
                final direction = ['All', 'Buy', 'Sell'][index];
                return Obx(() {
                  final isSelected =
                      tradingController.selectedDirection == direction;
                  return ListTile(
                    title: Text(
                      direction,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: Radio<String>(
                      value: direction,
                      groupValue: tradingController.selectedDirection,
                      onChanged: (value) {
                        if (value != null) {
                          tradingController.setSelectedDirection(value);
                          Get.back();
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      tradingController.setSelectedDirection(direction);
                      Get.back();
                    },
                    tileColor:
                        isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  );
                });
              },
            ),
            SizedBox(height: MediaQuery.of(Get.context!).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showPositionDetailsBottomSheet(
    TradingController tradingController,
    TradePosition position,
  ) {
    final isPositive = position.profitLoss >= 0;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Position Details Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(position.flag, style: TextStyle(fontSize: 30.sp)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              position.symbol,
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '\$${position.profitLoss.toStringAsFixed(2)}',
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color:
                                    isPositive
                                        ? AppColors.success
                                        : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            SvgPicture.asset(
                              position.action == 'Buy'
                                  ? 'assets/svg/trade/green_up_icon.svg'
                                  : 'assets/svg/trade/red_down_icon.svg',
                              height: 12.h,
                              width: 12.w,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${position.action} ${position.volume}',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    position.action == 'Buy'
                                        ? AppColors.success
                                        : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${position.entryPrice} → ${position.currentPrice}',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            // Action Options
            ListView(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: [
                _buildActionOption(
                  icon: Icons.close,
                  title: 'Close Position',
                  subtitle: 'Close this position immediately',
                  onTap: () {
                    Get.back();
                    Get.to(() => CloseOrderScreen(position: position));
                  },
                  color: AppColors.error,
                ),
                _buildActionOption(
                  icon: Icons.edit,
                  title: 'Modify Position',
                  subtitle: 'Change stop loss or take profit',
                  onTap: () {
                    Get.back();
                    Get.to(() => EditOrderScreen(position: position));
                  },
                  color: AppColors.primary,
                ),
                _buildActionOption(
                  icon: Icons.add,
                  title: 'New Order',
                  subtitle: 'Place a new order for this instrument',
                  onTap: () {
                    // TODO: Implement new order
                    Get.back();
                  },
                  color: AppColors.success,
                ),
                _buildActionOption(
                  icon: Icons.show_chart,
                  title: 'Chart',
                  subtitle: 'View detailed chart for this instrument',
                  onTap: () {
                    // TODO: Navigate to chart screen
                    Get.back();
                  },
                  color: AppColors.primary,
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(Get.context!).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      // leading: Container(
      //   width: 40.w,
      //   height: 40.h,
      //   decoration: BoxDecoration(
      //     color: color.withValues(alpha: 0.1),
      //     borderRadius: BorderRadius.circular(8.r),
      //   ),
      //   child: Icon(icon, color: color, size: 20.h),
      // ),
      title: Text(
        title,
        style: AppTextStyles.label.copyWith(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.label.copyWith(
          fontSize: 12.sp,
          color: AppColors.textGrey,
        ),
      ),
      onTap: onTap,
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
    );
  }

  void _showClosePositionsBottomSheet(TradingController tradingController) {
    String selectedOption = 'all_currently_open';

    // Get screen dimensions for proper sizing
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final screenWidth = MediaQuery.of(Get.context!).size.width;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.75,
              minHeight: 400.h,
              maxWidth: screenWidth,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    'Which positions would you like to close at market prices?',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 8.h),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCloseOption(
                            tradingController,
                            'all_currently_open',
                            'All currently open',
                            tradingController.getTotalProfitLoss(),
                            selectedOption == 'all_currently_open',
                            (value) => setState(() => selectedOption = value),
                          ),
                          _buildCloseOption(
                            tradingController,
                            'all_profitable',
                            'All profitable',
                            tradingController.getTotalProfitableProfitLoss(),
                            selectedOption == 'all_profitable',
                            (value) => setState(() => selectedOption = value),
                          ),
                          _buildCloseOption(
                            tradingController,
                            'all_losing',
                            'All losing',
                            tradingController.getTotalLosingProfitLoss(),
                            selectedOption == 'all_losing',
                            (value) => setState(() => selectedOption = value),
                          ),
                          _buildCloseOption(
                            tradingController,
                            'all_long',
                            'All Long',
                            tradingController.getTotalLongProfitLoss(),
                            selectedOption == 'all_long',
                            (value) => setState(() => selectedOption = value),
                          ),
                          _buildCloseOption(
                            tradingController,
                            'all_short',
                            'All Short',
                            tradingController.getTotalShortProfitLoss(),
                            selectedOption == 'all_short',
                            (value) => setState(() => selectedOption = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.label.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _executeClosePositions(
                              tradingController,
                              selectedOption,
                            );
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                          ),
                          child: Text(
                            'Confirm',
                            style: AppTextStyles.label.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(Get.context!).padding.bottom + 16.h,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloseOption(
    TradingController tradingController,
    String value,
    String title,
    double profitLoss,
    bool isSelected,
    Function(String) onChanged,
  ) {
    final isPositive = profitLoss >= 0;
    final hasPositions = profitLoss != 0;

    return Container(
      margin: EdgeInsets.only(bottom: 0.h),
      child: Row(
        children: [
          // Left side: Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        hasPositions
                            ? AppColors.textPrimary
                            : AppColors.textGrey,
                  ),
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
          // Right side: Radio button
          Row(
            children: [
              Text(
                hasPositions ? '\$${profitLoss.toStringAsFixed(2)}' : '-',
                style: AppTextStyles.label.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color:
                      hasPositions
                          ? (isPositive ? AppColors.success : AppColors.error)
                          : AppColors.textGrey,
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: isSelected ? value : null,
                onChanged:
                    hasPositions ? (newValue) => onChanged(newValue!) : null,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _executeClosePositions(
    TradingController tradingController,
    String option,
  ) {
    switch (option) {
      case 'all_currently_open':
        tradingController.closeAllPositions();
        break;
      case 'all_profitable':
        tradingController.closeAllProfitablePositions();
        break;
      case 'all_losing':
        tradingController.closeAllLosingPositions();
        break;
      case 'all_long':
        tradingController.closeAllLongPositions();
        break;
      case 'all_short':
        tradingController.closeAllShortPositions();
        break;
    }
  }

  void _showQuickCloseConfirmation(
    TradingController tradingController,
    TradePosition position,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Close Position',
          style: AppTextStyles.heading.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to close ${position.symbol} ${position.action} ${position.volume}?',
          style: AppTextStyles.label.copyWith(
            fontSize: 14.sp,
            color: AppColors.textGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              tradingController.closePosition(position.orderId);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Close',
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Account Header Widget (placeholder)
class AccountHeaderWidget extends StatelessWidget {
  const AccountHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 16.h,
            color: AppColors.primary,
          ),
          SizedBox(width: 4.w),
          Text(
            'Demo',
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
