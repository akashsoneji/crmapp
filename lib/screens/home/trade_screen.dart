//* in sid elike data is not coem sho note visiblefloating profit
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';

import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/services/trading_websocket_service.dart';
import 'package:pipze/widgets/account_header_widget.dart';
import 'package:pipze/widgets/dashBorder.dart';
import 'package:pipze/widgets/global_drawer.dart';
import 'package:pipze/screens/home/edit_order_screen.dart';
import 'package:pipze/screens/home/close_position_screen.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/utils/precision_helper.dart';

import '../auth/register/account_created_screen.dart';

class TradeScreen extends StatefulWidget {
  final Function(String)? onNavigateToChart;

  const TradeScreen({super.key, this.onNavigateToChart});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  // Track dismissed positions to prevent Dismissible widget issues
  final Set<String> _dismissedPositions = <String>{};

  @override
  void initState() {
    super.initState();
    // Initialize WebSocket service for trading data
    Get.put(TradingWebSocketService());

    // Reset to Market tab (0) when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tradingController = Get.find<TradingController>();
      tradingController.setSelectedTab(0);
    });
  }

  @override
  void dispose() {
    // Clear dismissed positions when screen is disposed
    _dismissedPositions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountController = Get.find<AccountController>();
    final tradingController = Get.find<TradingController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      drawer: const GlobalDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, accountController, tradingController),

            DashedUnderline(dashWidth: 10, dashSpace: 0, color: AppColors.grey),

            // Title
            // _buildTitle(languageService),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.0),
              child: _buildTabs(tradingController),
            ),
            SizedBox(height: 10.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),

              decoration: BoxDecoration(
                color: AppColors.cardBackGround,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary header

                  // Financial metrics with dashed lines - using real data
                  Obx(() => _buildAccountMetrics(tradingController)),
                ],
              ),
            ),

            // Container(
            //   height: 226.h,
            //   width: 327.w,
            //   decoration: BoxDecoration(
            //     color: AppColors.cardBackGround,
            //     borderRadius: BorderRadius.circular(10.r),
            //   ),
            //   padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 14.w),
            //   child: Column(
            //     children: [
            //       Row(
            //         children: [
            //           Text("Daata"),
            //           DashedUnderline(color: AppColors.icongrey),
            //           Text(
            //             "109.74",
            //             style: AppTextStyles.labelOnTradeBottomTitle,
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
            _buildFloatingSummary(tradingController),
            SizedBox(height: 8.h),

            // Trade Positions List
            Expanded(child: _buildPositionsList(tradingController)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AccountController accountController,
    TradingController tradingController,
  ) {
    // Create the Close All button widget
    final closeAllButton = Obx(() {
      final positions = tradingController.getFilteredPositions();
      // final totalProfitLoss = positions.fold<double>(
      //   0,
      //   (sum, position) => sum + position.profitLoss,
      // );

      return (positions.isNotEmpty)
          ? (tradingController.selectedTab == 0)
              ? TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  backgroundColor: AppColors.cardBackGround,
                ),
                onPressed: () {
                  print('🔘 Close All button clicked!');
                  _showClosePositionsBottomSheet(tradingController);
                },
                child: Text(
                  'Close All',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primary,
                  ),
                ),
              )
              : SizedBox.shrink()
          : const SizedBox.shrink();
    });

    return AccountHeaderWidget(
      showSearchIcon: false,
      rightWidget: closeAllButton,
    );
  }

  Widget _buildTabs(TradingController tradingController) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0.w),
      decoration: BoxDecoration(
        // color: AppColors.backgroundLight,
        // borderRadius: BorderRadius.circular(12.r),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.05),
        //     blurRadius: 10,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
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
                    height: 1.57.h,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isSelected ? AppColors.textPrimary : AppColors.textGrey,
                  ),
                ),
                SizedBox(width: 4.h),
                (index == 0)
                    ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            // isSelected
                            // ?
                            AppColors.cardBackGround,
                        // : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _getPositionCount(tradingController, index).toString(),
                        style: AppTextStyles.label.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.textGrey,
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
                SizedBox(width: 4.h),
                (index == 1)
                    ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackGround,

                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _getPositionCount(tradingController, index).toString(),
                        style: AppTextStyles.label.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.textGrey,
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
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
      // Only calculate profit/loss for market positions, not pending orders
      final totalProfitLoss = positions.fold<double>(
        0,
        (sum, position) =>
            tradingController.selectedTab == 1 ? 0 : sum + position.profitLoss,
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
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.icongrey, // base/default color
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text:
                        tradingController.selectedTab == 1
                            ? 'Pending orders:\n'
                            : 'Floating profit:\n',
                  ),
                  TextSpan(
                    text:
                        tradingController.selectedTab == 1
                            ? '${positions.length} orders'
                            : '\$${PrecisionHelper.formatPnL(totalProfitLoss)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          tradingController.selectedTab == 1
                              ? AppColors.textGrey
                              : (isPositive
                                  ? AppColors.success
                                  : AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            Row(
              children: [
                // Show calendar icon only for Close tab (History)
                if (tradingController.selectedTab == 2)
                  InkWell(
                    onTap: () => _showFilterBottomSheet(tradingController),
                    child: Container(
                      height: 35,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () => _showInstrumentsBottomSheet(tradingController),
                  child: Container(
                    height: 35,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Transform.rotate(
                      angle: 1.55,
                      child: SvgPicture.asset(
                        "assets/svg/bottom_navigation/candle_bold.svg",
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showDirectionBottomSheet(tradingController),
                  child: Container(
                    height: 35,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: SvgPicture.asset(
                      "assets/svg/trade/trade_arrow_icon.svg",
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPositionsList(TradingController tradingController) {
    return Obx(() {
      final positions = tradingController.getFilteredPositions();
      final isLoadingHistory = tradingController.isLoadingHistory;
      final hasMorePages = tradingController.hasMoreHistoryPages;

      if (positions.isEmpty && !isLoadingHistory) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<Widget>(
                future: SvgColorHelper.loadSvgWithColor(
                  assetPath: 'assets/svg/trade/trade_pending_empty.svg',
                  targetColor: AppColors.primary,
                  colorToReplace: '#5F259E', // Replace this color in the SVG
                  height: 100.h,
                  width: 100.w,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) return snapshot.data!;
                  return SizedBox(height: 100.h, width: 100.w);
                },
              ),
              SizedBox(height: 16.h),
              SizedBox(height: 8.h),
              Text(
                tradingController.selectedTab == 1
                    ? 'You have no pending orders'
                    : tradingController.selectedTab == 2
                    ? 'You have no closed positions'
                    : 'You have no open positions',
                style: AppTextStyles.subheading.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          if (tradingController.selectedTab == 2) {
            await tradingController.refreshTradeHistory();
          }
        },
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: positions.length + (hasMorePages ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the end if there are more pages
            if (index == positions.length) {
              return (tradingController.selectedTab == 2)
                  ? _buildPaginationLoader(tradingController)
                  : null;
            }

            final position = positions[index];
            return _buildPositionCard(tradingController, position);
          },
        ),
      );
    });
  }

  Widget _buildPaginationLoader(TradingController tradingController) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Center(
        child: Column(
          children: [
            if (tradingController.isLoadingHistory)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              )
            else
              ElevatedButton(
                onPressed: () => tradingController.loadNextPage(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('Load More', style: TextStyle(color: Colors.white)),
              ),
            SizedBox(height: 8.h),
            Text(
              'Page ${tradingController.currentHistoryPage} of ${tradingController.totalHistoryPages}',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textGrey,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionCard(
    TradingController tradingController,
    TradePosition position,
  ) {
    final isPositive = position.profitLoss >= 0;
    final isCloseTab = tradingController.selectedTab == 2;

    // Check if position has been dismissed
    if (_dismissedPositions.contains(position.orderId)) {
      return SizedBox.shrink(); // Return empty widget if dismissed
    }

    // Check if order is being cancelled (for pending orders only)
    // This prevents the widget from freezing when order is removed
    if (tradingController.selectedTab == 1) {
      final orderId = int.tryParse(position.orderId);
      if (orderId != null &&
          tradingController.isOrderBeingCancelled(orderId) &&
          !tradingController.hasPendingOrder(orderId)) {
        // Order is being cancelled and no longer in list - hide widget to prevent freeze
        return SizedBox.shrink();
      }
    }

    // Build the card content widget
    final cardContent = _buildCardContent(
      tradingController,
      position,
      isPositive,
    );

    // If Close tab, return card without Dismissible and without tap
    if (isCloseTab) {
      return SizedBox(
        width: 40.w,
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
            padding: EdgeInsets.all(16.w).copyWith(bottom: 0),
            child: cardContent,
          ),
        ),
      );
    }

    // For Market and Pending tabs, use Dismissible with swipe enabled
    return SizedBox(
      width: 40.w,
      child: Dismissible(
        key: Key(position.orderId.toString()),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {
          DismissDirection.endToStart: 0.4, // Require 60% swipe to dismiss
        },
        confirmDismiss: (direction) async {
          // Show confirmation dialog and return the result
          return await _showClosePositionConfirmation(
            tradingController,
            position,
          );
        },
        onDismissed: (direction) async {
          // Mark position as dismissed
          setState(() {
            _dismissedPositions.add(position.orderId);
          });

          // NOTE: The API call is already handled in _showClosePositionConfirmation
          // when the user confirms. This callback only marks the position as dismissed
          // to prevent widget issues. No need to call the API again here.
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.close_rounded, color: Colors.white, size: 24.h),
              SizedBox(width: 8.w),
              Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  // border: Border.all(color: AppColors.whiteColor),
                  // color: AppC,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24.h,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        child: GestureDetector(
          // For Close tab, show filter bottom sheet; for others show position details
          onTap:
              isCloseTab
                  ? () => _showFilterBottomSheet(tradingController)
                  : () => _showPositionDetailsBottomSheet(
                    tradingController,
                    position,
                  ),
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
              padding: EdgeInsets.all(16.w).copyWith(bottom: 0),
              child: _buildCardContent(tradingController, position, isPositive),
            ),
          ),
        ),
      ),
    );
  }

  // Extract card content to reuse for Close tab (no swipe, no tap)
  Widget _buildCardContent(
    TradingController tradingController,
    TradePosition position,
    bool isPositive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            _buildPositionFlag(position.flag),
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
                        position.symbol.replaceAll('.c', ''),
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        tradingController.selectedTab == 1
                            ? 'Pending'
                            : '\$${PrecisionHelper.formatPnL(position.profitLoss)}',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color:
                              tradingController.selectedTab == 1
                                  ? AppColors.textGrey
                                  : (isPositive
                                      ? AppColors.success
                                      : AppColors.error),
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
                            height: 7.h,
                            width: 7.w,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            position.action,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
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
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        tradingController.selectedTab == 1
                            ? 'Order: ${position.currentPrice} | Current: ${position.entryPrice}'
                            : '${position.entryPrice} --> ${position.currentPrice}',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // SL, TP, and Position ID row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side: SL and TP
                      Row(
                        children: [
                          if (position.stopLoss.isNotEmpty &&
                              position.stopLoss != '-') ...[
                            Text(
                              'SL: ${position.stopLoss}',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w400,
                                color: AppColors.error,
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          if (position.takeProfit.isNotEmpty &&
                              position.takeProfit != '-') ...[
                            Text(
                              'TP: ${position.takeProfit}',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w400,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                          if (position.stopLoss.isEmpty ||
                              position.stopLoss == '-')
                            if (position.takeProfit.isEmpty ||
                                position.takeProfit == '-')
                              Text(
                                'SL: -  TP: -',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textGrey,
                                ),
                              ),
                        ],
                      ),
                      // Right side: Position ID
                      Text(
                        'ID: ${position.orderId}',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
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
      ],
    );
  }

  void _showInstrumentsBottomSheet(TradingController tradingController) {
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: 350.h,
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
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Select Instruments",
                  style: AppTextStyles.label.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child:
                      tradingController.availableInstruments.isEmpty
                          ? Center(
                            child: Text(
                              'No Open Trade',
                              style: AppTextStyles.heading,
                            ),
                          )
                          : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 0.w),
                            itemCount:
                                tradingController.availableInstruments.length,
                            itemBuilder: (context, index) {
                              final instrument =
                                  tradingController.availableInstruments
                                      .toList()[index];
                              return Obx(() {
                                final isSelected = tradingController
                                    .selectedInstruments
                                    .contains(instrument);
                                return ListTile(
                                  title: Text(
                                    instrument,
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      if (value == true) {
                                        tradingController.addInstrument(
                                          instrument,
                                        );
                                      } else {
                                        tradingController.removeInstrument(
                                          instrument,
                                        );
                                      }
                                    },
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                  ),
                                  onTap: () {
                                    if (isSelected) {
                                      tradingController.removeInstrument(
                                        instrument,
                                      );
                                    } else {
                                      tradingController.addInstrument(
                                        instrument,
                                      );
                                    }
                                  },
                                  tileColor:
                                      isSelected
                                          ? AppColors.primary.withValues(
                                            alpha: 0.05,
                                          )
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
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Confirm',
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
          );
        },
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
              child: Text(
                "Direction",
                style: AppTextStyles.label.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
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
                        fontWeight: FontWeight.w400,
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

  void _showFilterBottomSheet(TradingController tradingController) {
    String? selectedFilter = null; // 'today', 'lastWeek', 'lastMonth', 'custom'
    DateTime? startDate;
    DateTime? endDate;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                // Compact Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter History',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20.w),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Quick Filter Buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickFilterButton(
                          'Today',
                          selectedFilter == 'today',
                          () {
                            setState(() {
                              selectedFilter = 'today';
                              final now = DateTime.now();
                              startDate = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              endDate = DateTime(now.year, now.month, now.day);
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildQuickFilterButton(
                          'Last Week',
                          selectedFilter == 'lastWeek',
                          () {
                            setState(() {
                              selectedFilter = 'lastWeek';
                              final now = DateTime.now();
                              endDate = DateTime(now.year, now.month, now.day);
                              startDate = endDate!.subtract(Duration(days: 7));
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildQuickFilterButton(
                          'Last Month',
                          selectedFilter == 'lastMonth',
                          () {
                            setState(() {
                              selectedFilter = 'lastMonth';
                              final now = DateTime.now();
                              endDate = DateTime(now.year, now.month, now.day);
                              startDate = DateTime(
                                now.year,
                                now.month - 1,
                                now.day,
                              );
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildQuickFilterButton(
                          'Custom',
                          selectedFilter == 'custom',
                          () {
                            setState(() {
                              selectedFilter = 'custom';
                              startDate = null;
                              endDate = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Custom Date Pickers (shown only when Custom is selected)
                if (selectedFilter == 'custom')
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        // Start Date - Compact
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppColors.primary,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: AppColors.textPrimary,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  startDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    startDate != null
                                        ? AppColors.primary.withValues(
                                          alpha: 0.1,
                                        )
                                        : AppColors.backgroundLight,
                                border: Border.all(
                                  color:
                                      startDate != null
                                          ? AppColors.primary
                                          : AppColors.border,
                                  width: startDate != null ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Start',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    startDate != null
                                        ? '${startDate!.day}/${startDate!.month}'
                                        : 'Select',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          startDate != null
                                              ? AppColors.primary
                                              : AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // End Date - Compact
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: startDate ?? DateTime(2000),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppColors.primary,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: AppColors.textPrimary,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  endDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    endDate != null
                                        ? AppColors.primary.withValues(
                                          alpha: 0.1,
                                        )
                                        : AppColors.backgroundLight,
                                border: Border.all(
                                  color:
                                      endDate != null
                                          ? AppColors.primary
                                          : AppColors.border,
                                  width: endDate != null ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'End',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    endDate != null
                                        ? '${endDate!.day}/${endDate!.month}'
                                        : 'Select',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          endDate != null
                                              ? AppColors.primary
                                              : AppColors.textGrey,
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
                SizedBox(height: 20.h),
                // Apply Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedFilter == null) {
                          CustomToastService.showError(
                            message: 'Please select a filter option',
                          );
                          return;
                        }

                        if (selectedFilter == 'custom' &&
                            (startDate == null || endDate == null)) {
                          CustomToastService.showError(
                            message: 'Please select both start and end dates',
                          );
                          return;
                        }

                        if (selectedFilter == 'custom' &&
                            endDate!.isBefore(startDate!)) {
                          CustomToastService.showError(
                            message: 'End date must be after start date',
                          );
                          return;
                        }

                        // Convert dates to timestamps
                        DateTime finalStartDate;
                        DateTime finalEndDate;

                        if (selectedFilter == 'custom') {
                          finalStartDate = startDate!;
                          finalEndDate = endDate!;
                        } else {
                          finalStartDate = startDate!;
                          finalEndDate = endDate!;
                        }

                        final fromTimestamp =
                            finalStartDate.millisecondsSinceEpoch ~/ 1000;
                        final toTimestamp =
                            finalEndDate
                                    .add(Duration(days: 1))
                                    .millisecondsSinceEpoch ~/
                                1000 -
                            1;

                        Get.back();

                        // Load history with timestamp filters
                        await tradingController.loadTradeHistoryWithTimestamps(
                          page: 1,
                          refresh: true,
                          fromTimestamp: fromTimestamp,
                          toTimestamp: toTimestamp,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Apply Filter',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildQuickFilterButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundLight,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 0 : 1,
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _showPositionDetailsBottomSheet(
    TradingController tradingController,
    TradePosition position,
  ) {
    final isPositive = position.profitLoss >= 0;

    // Pre-build the bottom sheet content to avoid rebuilding during animation
    final bottomSheetContent = _buildPositionDetailsContent(
      tradingController,
      position,
      isPositive,
    );

    Get.bottomSheet(
      bottomSheetContent,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
    );
  }

  // Helper method to get symbol without .c suffix
  String _getDisplaySymbol(String symbol) {
    return symbol.replaceFirst('.c', '');
  }

  Widget _buildPositionDetailsContent(
    TradingController tradingController,
    TradePosition position,
    bool isPositive,
  ) {
    return Container(
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
                _buildPositionFlag(position.flag, size: 32.h),
                SizedBox(width: 12.w),
                Expanded(
                  child: Obx(() {
                    // Get real-time position data filtered by orderId
                    final realTimePosition = tradingController.marketPositions
                        .firstWhereOrNull((p) => p.orderId == position.orderId);

                    // Use real-time data if available, otherwise fallback to static position
                    final currentPosition = realTimePosition ?? position;
                    final currentProfitLoss = currentPosition.profitLoss;
                    final currentIsPositive = currentProfitLoss >= 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getDisplaySymbol(currentPosition.symbol),
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              tradingController.selectedTab == 1
                                  ? 'Pending'
                                  : '\$${PrecisionHelper.formatPnL(currentProfitLoss)}',
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color:
                                    tradingController.selectedTab == 1
                                        ? AppColors.textGrey
                                        : (currentIsPositive
                                            ? AppColors.success
                                            : AppColors.error),
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
                                  currentPosition.action == 'Buy'
                                      ? 'assets/svg/trade/green_up_icon.svg'
                                      : 'assets/svg/trade/red_down_icon.svg',
                                  height: 9.h,
                                  width: 9.w,
                                ),
                                SizedBox(width: 6.w),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${currentPosition.action}',
                                        style: AppTextStyles.label.copyWith(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' ${currentPosition.volume}',
                                        style: AppTextStyles.label.copyWith(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.icongrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              tradingController.selectedTab == 1
                                  ? 'Order: ${currentPosition.entryPrice} | Current: ${currentPosition.currentPrice}'
                                  : '${currentPosition.entryPrice} → ${currentPosition.currentPrice}',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        // SL, TP, and Position ID in bottom sheet
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side: SL and TP
                            Row(
                              children: [
                                if (currentPosition.stopLoss.isNotEmpty &&
                                    currentPosition.stopLoss != '-') ...[
                                  Text(
                                    'SL: ${currentPosition.stopLoss}',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                ],
                                if (currentPosition.takeProfit.isNotEmpty &&
                                    currentPosition.takeProfit != '-') ...[
                                  Text(
                                    'TP: ${currentPosition.takeProfit}',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                                if (currentPosition.stopLoss.isEmpty ||
                                    currentPosition.stopLoss == '-')
                                  if (currentPosition.takeProfit.isEmpty ||
                                      currentPosition.takeProfit == '-')
                                    Text(
                                      'SL: -  TP: -',
                                      style: AppTextStyles.label.copyWith(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                              ],
                            ),
                            // Right side: Position ID
                            Text(
                              'ID: ${currentPosition.orderId}',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          // Action Options
          ListView(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            children:
                tradingController.selectedTab == 1
                    ? [
                      // Pending order actions
                      _buildActionOption(
                        icon: Icons.cancel,
                        title: 'Cancel Order',
                        subtitle: 'Cancel this pending order',
                        onTap: () async {
                          Get.back();
                          await _showCancelOrderConfirmation(
                            tradingController,
                            position,
                          );
                        },
                        color: AppColors.error,
                      ),
                      _buildActionOption(
                        icon: Icons.edit,
                        title: 'Modify Order',
                        subtitle:
                            'Change order price, stop loss or take profit',
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
                          Get.back();
                          // Use callback to navigate to chart tab in TradingMainScreen
                          if (widget.onNavigateToChart != null) {
                            widget.onNavigateToChart!(position.symbol);
                          }
                        },
                        color: AppColors.success,
                      ),
                      _buildActionOption(
                        icon: Icons.show_chart,
                        title: 'Chart',
                        subtitle: 'View detailed chart for this instrument',
                        onTap: () {
                          Get.back();
                          // Use callback to navigate to chart tab in TradingMainScreen
                          if (widget.onNavigateToChart != null) {
                            widget.onNavigateToChart!(position.symbol);
                          }
                        },
                        color: AppColors.primary,
                      ),
                    ]
                    : [
                      // Market position actions
                      _buildActionOption(
                        icon: Icons.close,
                        title: 'Close Position',
                        subtitle: 'Close this position immediately',
                        onTap: () {
                          Get.back();
                          Get.to(() => ClosePositionScreen(position: position));
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
                          Get.back();
                          // Use callback to navigate to chart tab in TradingMainScreen
                          if (widget.onNavigateToChart != null) {
                            widget.onNavigateToChart!(position.symbol);
                          }
                        },
                        color: AppColors.success,
                      ),
                      _buildActionOption(
                        icon: Icons.show_chart,
                        title: 'Chart',
                        subtitle: 'View detailed chart for this instrument',
                        onTap: () {
                          Get.back();
                          // Use callback to navigate to chart tab in TradingMainScreen
                          if (widget.onNavigateToChart != null) {
                            widget.onNavigateToChart!(position.symbol);
                          }
                        },
                        color: AppColors.primary,
                      ),
                    ],
          ),
          SizedBox(height: MediaQuery.of(Get.context!).padding.bottom),
        ],
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
      title: Text(
        title,
        style: AppTextStyles.label.copyWith(
          fontSize: 15.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.33,
        ),
      ),
      onTap: onTap,
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
    );
  }

  void _showClosePositionsBottomSheet(TradingController tradingController) {
    print('📋 _showClosePositionsBottomSheet called');
    String selectedOption = 'all_currently_open';

    // Get screen dimensions for proper sizing
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final screenWidth = MediaQuery.of(Get.context!).size.width;

    print('📊 Screen dimensions: ${screenWidth}x${screenHeight}');
    print('📊 Selected option: $selectedOption');

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
                            print('🔘 Bottom sheet confirm button clicked!');
                            print('📊 Selected option: $selectedOption');

                            // Close bottom sheet first
                            Get.back();

                            // Then execute close positions after a short delay
                            Future.delayed(Duration(milliseconds: 300), () {
                              _executeClosePositions(
                                tradingController,
                                selectedOption,
                              );
                            });
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
                hasPositions
                    ? '\$${PrecisionHelper.formatPnL(profitLoss)}'
                    : '-',
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
  ) async {
    print('🚀 _executeClosePositions called with option: $option');

    final accountController = Get.find<AccountController>();
    final activeAccount = accountController.activeMT5Account;

    print('📊 Active account: ${activeAccount?.metaAccountNumber}');
    print('📊 Selected tab: ${tradingController.selectedTab}');
    print(
      '📊 Current positions count: ${tradingController.getFilteredPositions().length}',
    );

    if (activeAccount == null) {
      print('❌ No active account found');
      CustomToastService.showError(
        title: 'Error',
        message: 'No active account found',
      );
      return;
    }

    print('✅ Account found, showing confirmation dialog...');

    // Show confirmation dialog before calling API
    final result = await _showClosePositionsConfirmation(
      tradingController,
      option,
      activeAccount.metaAccountNumber,
    );

    print('📋 Confirmation dialog result: $result');

    // Handle the result
    if (result == true) {
      // Success - message is already shown in the dialog callback
      print('✅ Close positions operation completed successfully');
    } else if (result == false) {
      // User cancelled or API failed
      print('❌ Close positions operation cancelled or failed');
    } else {
      print('❓ Close positions operation returned null');
    }
  }

  Future<bool?> _showClosePositionsConfirmation(
    TradingController tradingController,
    String option,
    String mt5Account,
  ) async {
    print('🔔 _showClosePositionsConfirmation called');
    print('📊 Option: $option');
    print('📊 MT5 Account: $mt5Account');

    // Get the appropriate message based on option
    String message = _getClosePositionsMessage(option, tradingController);
    print('📝 Message: $message');
    print('📋 About to show Get.dialog...');

    return await Get.dialog<bool>(
          barrierDismissible: false, // Prevent dismissal by clicking outside
          barrierColor: Colors.black54, // Add semi-transparent background
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              tradingController.selectedTab == 1
                  ? 'Cancel Orders'
                  : 'Close Positions',
              style: AppTextStyles.heading.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              message,
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                color: AppColors.textGrey,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('🔘 CANCEL BUTTON CLICKED IN DIALOG!');
                  Navigator.of(Get.context!).pop(false);
                },
                child: Text(
                  'Cancel',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
              Obx(
                () => ElevatedButton(
                  onPressed:
                      tradingController.isLoading
                          ? null
                          : () async {
                            print('🔘 CONFIRM BUTTON CLICKED IN DIALOG!');
                            print(
                              '📊 Trading controller loading: ${tradingController.isLoading}',
                            );
                            print(
                              '📊 Selected tab: ${tradingController.selectedTab}',
                            );
                            print(
                              '📊 Button is enabled: ${!tradingController.isLoading}',
                            );

                            // Close dialog immediately when user clicks Close All
                            print('📋 Closing dialog immediately...');
                            Navigator.of(Get.context!).pop(true);

                            // Call the appropriate API based on option and current tab in background
                            bool success = false;

                            try {
                              print('🚀 Starting API call...');
                              if (tradingController.selectedTab == 1) {
                                print('📋 Handling pending orders...');
                                // Handle pending orders
                                final pendingOrders =
                                    tradingController.pendingPositions;
                                final orderIds =
                                    pendingOrders
                                        .map((p) => int.parse(p.orderId))
                                        .toList();

                                print(
                                  '📊 Pending orders count: ${pendingOrders.length}',
                                );
                                print('📊 Order IDs: $orderIds');

                                if (orderIds.isNotEmpty) {
                                  print(
                                    '🚀 Calling closeMultiplePendingOrders...',
                                  );
                                  await tradingController
                                      .closeMultiplePendingOrders(
                                        mt5Account: mt5Account,
                                        orderIds: orderIds,
                                      );
                                  success = true;
                                  print(
                                    '✅ closeMultiplePendingOrders completed',
                                  );
                                } else {
                                  print('⚠️ No pending orders to close');
                                }
                              } else {
                                print('📋 Handling market positions...');
                                print('📊 Option: $option');
                                print('📊 MT5 Account: $mt5Account');
                                // Handle market positions
                                switch (option) {
                                  case 'all_currently_open':
                                    print('🚀 Calling closeAllPositions...');
                                    print(
                                      '📊 About to call API with account: $mt5Account',
                                    );
                                    await tradingController.closeAllPositions(
                                      mt5Account: mt5Account,
                                    );
                                    success = true;
                                    print('✅ closeAllPositions completed');
                                    break;
                                  case 'all_profitable':
                                    await tradingController
                                        .closeAllProfitablePositions(
                                          mt5Account: mt5Account,
                                        );
                                    success = true;
                                    break;
                                  case 'all_losing':
                                    await tradingController
                                        .closeAllLosingPositions(
                                          mt5Account: mt5Account,
                                        );
                                    success = true;
                                    break;
                                  case 'all_long':
                                    await tradingController
                                        .closeAllLongPositions(
                                          mt5Account: mt5Account,
                                        );
                                    success = true;
                                    break;
                                  case 'all_short':
                                    await tradingController
                                        .closeAllShortPositions(
                                          mt5Account: mt5Account,
                                        );
                                    success = true;
                                    break;
                                }
                              }
                            } catch (e) {
                              print('❌ Error closing positions: $e');
                              CustomToastService.showError(
                                title: 'Error',
                                message: 'Failed to close positions: $e',
                              );
                            }

                            print('📋 Final success status: $success');
                            print('📋 API call completed in background');

                            // Show success message
                            if (success) {
                              final action =
                                  tradingController.selectedTab == 1
                                      ? 'cancelled'
                                      : 'closed';
                              CustomToastService.showSuccess(
                                title: 'Success',
                                message:
                                    'All positions have been $action successfully',
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child:
                      tradingController.isLoading
                          ? SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            tradingController.selectedTab == 1
                                ? 'Cancel All'
                                : 'Close All',
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
        ) ??
        false;
  }

  String _getClosePositionsMessage(
    String option,
    TradingController tradingController,
  ) {
    if (tradingController.selectedTab == 1) {
      // Pending orders message
      final pendingCount = tradingController.pendingPositions.length;
      return 'Are you sure you want to cancel ALL pending orders?\n\nOrders: $pendingCount';
    }

    // Market positions messages
    switch (option) {
      case 'all_currently_open':
        final totalPnl = tradingController.getTotalProfitLoss();
        return 'Are you sure you want to close ALL currently open positions?\n\nTotal P&L: \$${PrecisionHelper.formatPnL(totalPnl)}';
      case 'all_profitable':
        final profitablePnl = tradingController.getTotalProfitableProfitLoss();
        final count = tradingController.getProfitablePositionsCount();
        return 'Are you sure you want to close ALL profitable positions?\n\nPositions: $count\nTotal P&L: \$${PrecisionHelper.formatPnL(profitablePnl)}';
      case 'all_losing':
        final losingPnl = tradingController.getTotalLosingProfitLoss();
        final count = tradingController.getLosingPositionsCount();
        return 'Are you sure you want to close ALL losing positions?\n\nPositions: $count\nTotal P&L: \$${PrecisionHelper.formatPnL(losingPnl)}';
      case 'all_long':
        final longPnl = tradingController.getTotalLongProfitLoss();
        final count = tradingController.getLongPositionsCount();
        return 'Are you sure you want to close ALL long positions?\n\nPositions: $count\nTotal P&L: \$${PrecisionHelper.formatPnL(longPnl)}';
      case 'all_short':
        final shortPnl = tradingController.getTotalShortProfitLoss();
        final count = tradingController.getShortPositionsCount();
        return 'Are you sure you want to close ALL short positions?\n\nPositions: $count\nTotal P&L: \$${PrecisionHelper.formatPnL(shortPnl)}';
      default:
        return 'Are you sure you want to close these positions?';
    }
  }

  Future<bool> _showClosePositionConfirmation(
    TradingController tradingController,
    TradePosition position,
  ) async {
    print('🔔 Showing close position confirmation dialog');

    // Check if this is a pending order or market position
    final isPendingOrder = tradingController.selectedTab == 1;

    return await Get.dialog<bool>(
          barrierDismissible: true, // Allow dismissal by tapping outside
          barrierColor: Colors.black54, // Semi-transparent background
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              isPendingOrder ? 'Cancel Order' : 'Close Position',
              style: AppTextStyles.heading.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              isPendingOrder
                  ? 'Are you sure you want to cancel ${_getDisplaySymbol(position.symbol)} ${position.action} ${position.volume} order?'
                  : 'Are you sure you want to close ${_getDisplaySymbol(position.symbol)} ${position.action} ${position.volume} ?',
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                color: AppColors.textGrey,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('🔘 CANCEL BUTTON CLICKED IN DIALOG!');
                  Navigator.of(Get.context!).pop(false);
                },
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
                onPressed: () async {
                  print('🔘 CONFIRM BUTTON CLICKED IN DIALOG!');
                  print('📊 Is Pending Order: $isPendingOrder');

                  // Close the dialog first
                  Navigator.of(Get.context!).pop(true);

                  // Add a small delay to ensure dialog is closed
                  await Future.delayed(Duration(milliseconds: 100));

                  // Call the appropriate API based on order type
                  final accountController = Get.find<AccountController>();
                  final activeAccount = accountController.activeMT5Account;

                  if (activeAccount != null) {
                    if (isPendingOrder) {
                      // This is a pending order - cancel it
                      print('📞 Calling cancel order API...');
                      await tradingController.cancelOrderWithImmediateUpdate(
                        mt5Account: activeAccount.metaAccountNumber,
                        orderId: int.parse(position.orderId),
                      );
                      print('✅ Cancel order API completed');
                    } else {
                      // This is a market position - close it
                      print('📞 Calling close position API...');
                      await tradingController.closePositionWithImmediateUpdate(
                        mt5Account: activeAccount.metaAccountNumber,
                        positionId: int.parse(position.orderId),
                      );
                      print('✅ Close position API completed');
                    }
                  } else {
                    print('❌ No active account found');
                    CustomToastService.showError(
                      title: 'Error',
                      message: 'No active account found',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  isPendingOrder ? 'Cancel Order' : 'Close',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showCancelOrderConfirmation(
    TradingController tradingController,
    TradePosition position,
  ) async {
    print('🔔 Showing cancel order confirmation dialog');

    return await Get.dialog<bool>(
          barrierDismissible: true, // Allow dismissal by tapping outside
          barrierColor: Colors.black54, // Semi-transparent background
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Cancel Order',
              style: AppTextStyles.heading.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to cancel ${_getDisplaySymbol(position.symbol)} ${position.action} ${position.volume} order?',
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                color: AppColors.textGrey,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('🔘 CANCEL BUTTON CLICKED IN DIALOG!');
                  Navigator.of(Get.context!).pop(false);
                },
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
                onPressed: () async {
                  print('🔘 CANCEL ORDER BUTTON CLICKED IN DIALOG!');

                  // Close the dialog first
                  Navigator.of(Get.context!).pop(true);

                  // Add a small delay to ensure dialog is closed
                  await Future.delayed(Duration(milliseconds: 100));

                  // Call the API to cancel order
                  final accountController = Get.find<AccountController>();
                  final activeAccount = accountController.activeMT5Account;

                  if (activeAccount != null) {
                    print('📞 Calling cancel order API...');
                    await tradingController.cancelOrderWithImmediateUpdate(
                      mt5Account: activeAccount.metaAccountNumber,
                      orderId: int.parse(position.orderId),
                    );
                    print('✅ Cancel order API completed');
                  } else {
                    print('❌ No active account found');
                    CustomToastService.showError(
                      title: 'Error',
                      message: 'No active account found',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Cancel Order',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildAccountMetrics(TradingController tradingController) {
    // Check if Close tab - show trade history totals instead
    if (tradingController.selectedTab == 2) {
      final totals = tradingController.tradeHistoryTotals;

      if (totals == null) {
        // Show loading or default values
        return Column(
          children: [
            _buildMetricRow("Profit", "0.00"),
            _buildMetricRow("Deposit", "0.00"),
            _buildMetricRow("Withdrawal", "0.00"),
            _buildMetricRow("Swap", "0.00"),
            _buildMetricRow("Commission", "0.00"),
            _buildMetricRow("Balance", "0.00"),
          ],
        );
      }

      return Column(
        children: [
          _buildMetricRow("Profit", totals.profit.toStringAsFixed(2)),
          _buildMetricRow("Deposit", totals.deposit.toStringAsFixed(2)),
          _buildMetricRow("Withdrawal", totals.withdrawal.toStringAsFixed(2)),
          _buildMetricRow("Swap", totals.swap.toStringAsFixed(2)),
          _buildMetricRow("Commission", totals.commission.toStringAsFixed(2)),
          _buildMetricRow("Balance", totals.balance.toStringAsFixed(2)),
        ],
      );
    }

    // For Market and Pending tabs - show regular account metrics
    final accountInfo = tradingController.accountInfo;

    if (accountInfo == null) {
      // Show loading or default values
      return Column(
        children: [
          _buildMetricRow("Balance", "0.00"),

          _buildMetricRow("Equity", "0.00"),

          _buildMetricRow("Credit", "0.00"),

          _buildMetricRow("Swap", "0.00"),

          _buildMetricRow("Margin", "0.00"),

          _buildMetricRow("Free Margin", "0.00"),

          _buildMetricRow("Margin Level (%)", "0.00"),
        ],
      );
    }

    return Column(
      children: [
        _buildMetricRow("Balance", accountInfo.balance.toStringAsFixed(2)),

        _buildMetricRow("Equity", accountInfo.equity.toStringAsFixed(2)),

        //
        // _buildMetricRow("Credit", accountInfo.credit.toStringAsFixed(2)),
        //
        // _buildMetricRow("Swap", accountInfo.storage.toStringAsFixed(2)),
        _buildMetricRow("Margin", accountInfo.margin.toStringAsFixed(2)),

        _buildMetricRow(
          "Free Margin",
          accountInfo.marginFree.toStringAsFixed(2),
        ),

        _buildMetricRow(
          "Margin Level (%)",
          accountInfo.marginLevel.toStringAsFixed(2),
        ),
      ],
    );
  }

  // helper lives outside the widget:
  String fixIconUrl(String url) =>
      url.replaceFirst(RegExp(r'\.[a-z]\.png$'), '.png');

  Widget _buildPositionFlag(String flag, {double? size}) {
    final flagSize = size ?? 24.h;
    final fontSize = (flagSize * 0.7).clamp(12.0, 28.0);

    // Check if it's a URL (contains http) or an emoji
    // It's a URL, use Image.network
    return Container(
      height: flagSize,
      width: flagSize,
      child: Image.network(
        fixIconUrl(flag),
        height: flagSize,
        width: flagSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to emoji if image fails to load
          return Container(
            height: flagSize,
            width: flagSize,
            child: Text(
              '💱',
              style: TextStyle(fontSize: fontSize),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      children: [
        // Label
        Text(
          label + ":",
          style: AppTextStyles.label.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        // Flexible space with dashed line
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            child: Container(
              height: 10,
              alignment: Alignment.bottomCenter,
              child: DashedUnderline(
                dashWidth: 2.w,
                dashSpace: 7.w,
                color: AppColors.icongrey,
              ),
            ),
          ),
        ),

        // Value
        Text(
          value,
          style: AppTextStyles.label.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
