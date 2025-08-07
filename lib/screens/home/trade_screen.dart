import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/screens/home/dashboard_screen.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/widgets/dashBorder.dart';
import 'package:pipze/widgets/global_drawer.dart';

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

              // Floating Profit/Loss Summary
              _buildFloatingSummary(tradingController),

              // Filter Buttons
              _buildFilterButtons(tradingController),

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
                onPressed: () => tradingController.closeAllPositions(),
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
          // Instrument Filter
          Text(
            'Instruments',
            style: AppTextStyles.label.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children:
                tradingController.availableInstruments.map((instrument) {
                  return Obx(() {
                    final isSelected = tradingController.selectedInstruments
                        .contains(instrument);
                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          tradingController.removeInstrument(instrument);
                        } else {
                          tradingController.addInstrument(instrument);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          instrument,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  });
                }).toList(),
          ),
          SizedBox(height: 16.h),
          // Direction Filter
          Text(
            'Direction',
            style: AppTextStyles.label.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children:
                ['All', 'Buy', 'Sell'].map((direction) {
                  return Obx(() {
                    final isSelected =
                        tradingController.selectedDirection == direction;
                    return Expanded(
                      child: GestureDetector(
                        onTap:
                            () => tradingController.setSelectedDirection(
                              direction,
                            ),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: direction != 'Sell' ? 8.w : 0,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            direction,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                }).toList(),
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
              Icon(Icons.inbox_outlined, size: 64.h, color: AppColors.textGrey),
              SizedBox(height: 16.h),
              Text(
                'No positions found',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Try adjusting your filters',
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

    return Container(
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
                Text(position.flag, style: TextStyle(fontSize: 20.sp)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    position.symbol,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color:
                        position.action == 'Buy'
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
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
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Details row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volume: ${position.volume}',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Entry: ${position.entryPrice}',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${position.profitLoss.toStringAsFixed(2)}',
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Current: ${position.currentPrice}',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        () => tradingController.closePosition(position.orderId),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Show position details
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Details',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
