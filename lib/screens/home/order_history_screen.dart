import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/trading_controller.dart';

class CloseOrderScreen extends StatelessWidget {
  final TradePosition position;

  const CloseOrderScreen({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final isPositive = position.profitLoss >= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24.h,
          ),
        ),
        title: Text(
          'Close Order',
          style: AppTextStyles.heading.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Order Summary Section
            _buildOrderSummary(position, isPositive),

            // Order Details Section
            Expanded(child: _buildOrderDetails(position)),

            // History Button
            _buildHistoryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(TradePosition position, bool isPositive) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackGround,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Flag and Symbol
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(position.flag, style: TextStyle(fontSize: 24.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    position.symbol,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
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
            ],
          ),

          const Spacer(),

          // Profit/Loss and Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${position.profitLoss.toStringAsFixed(2)}',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
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
        ],
      ),
    );
  }

  Widget _buildOrderDetails(TradePosition position) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Details',
            style: AppTextStyles.heading.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView(
              children: [
                _buildDetailRow('Open Time', position.openTime),
                _buildDetailRow('Close Time', position.closeTime),
                _buildDetailRow('Reason', position.reason),
                _buildDetailRow('Order No.', position.orderNo),
                _buildDetailRow('Commission', '\$${position.commission}'),
                _buildDetailRow('Swap', '\$${position.swap}'),
                _buildDetailRow('TP (Take Profit)', position.takeProfit),
                _buildDetailRow(
                  'SL (Stop Loss)',
                  position.stopLoss == '-' ? '-' : position.stopLoss,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.label.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: OutlinedButton(
        onPressed: () {
          Get.to(() => const HistoryScreen());
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          minimumSize: Size(double.infinity, 48.h),
        ),
        child: Text(
          'History',
          style: AppTextStyles.label.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Track which history entries are expanded
  final Map<int, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    // Initialize all entries as collapsed by default
    _expandedStates[0] = false;
    _expandedStates[1] = false;
    _expandedStates[2] = false;
  }

  void _toggleExpanded(int index) {
    setState(() {
      _expandedStates[index] = !(_expandedStates[index] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        // elevation: 0,
        shadowColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24.h,
          ),
        ),
        title: Text(
          'History',
          style: AppTextStyles.heading.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Trade Summary
            _buildTradeSummary(),

            // History Entries
            Expanded(child: _buildHistoryEntries()),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeSummary() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Flag and Symbol
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🇪🇺🇺🇸', style: TextStyle(fontSize: 24.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    'EURUSD',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/svg/trade/red_down_icon.svg',
                    height: 12.h,
                    width: 12.w,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Sell 0.02',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Profit/Loss and Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-\$8.56',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '3425.59 → 3430.23',
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEntries() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      children: [
        _buildHistoryEntry(
          index: 0,
          title: 'Order Closed',
          subtitle: 'Manual operation',
          profitLoss: '+ \$89.54',
          isPositive: true,
          dateTime: '25 jan 2025 • 12:49',
          expandedDetails: {
            'Device': 'Android',
            'Direction': 'Sell',
            'Close Price': '3,408.65',
            'Volume Closed': '0.03 lots',
            'Overnight fee': '\$0.00',
            'Gross profit': '+\$71.28',
            'Net profit': '+\$71.28',
            'Deal ID': '6341532',
          },
        ),
        _buildHistoryEntry(
          index: 1,
          title: 'Order Opened',
          subtitle: 'Manual operation',
          profitLoss: '',
          isPositive: false,
          dateTime: '25 jan 2025 • 12:49',
          expandedDetails: {
            'Device': 'Android',
            'Direction': 'Sell',
            'Open Price': '3,408.65',
            'Volume': '0.03 lots',
          },
        ),
        _buildHistoryEntry(
          index: 2,
          title: 'Order Closed',
          subtitle: 'Manual operation',
          profitLoss: '-\$8.56',
          isPositive: false,
          dateTime: '25 jan 2025 • 12:49',
        ),
      ],
    );
  }

  Widget _buildHistoryEntry({
    required int index,
    required String title,
    required String subtitle,
    required String profitLoss,
    required bool isPositive,
    required String dateTime,
    Map<String, String>? expandedDetails,
  }) {
    final isExpanded = _expandedStates[index] ?? false;

    return GestureDetector(
      onTap: () => _toggleExpanded(index),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profitLoss.isNotEmpty)
                    Text(
                      profitLoss,
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dateTime,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16.h,
                        color: AppColors.textGrey,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Expanded Details
            if (isExpanded && expandedDetails != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8.r),
                    bottomRight: Radius.circular(8.r),
                  ),
                ),
                child: Column(
                  children:
                      expandedDetails.entries.map((entry) {
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.border,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              Text(
                                entry.value,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
