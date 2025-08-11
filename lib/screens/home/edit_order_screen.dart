import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/trading_controller.dart';

class EditOrderScreen extends StatefulWidget {
  final TradePosition position;

  const EditOrderScreen({super.key, required this.position});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  int selectedTab = 0; // 0: Edit, 1: Partial close

  // Toggle states
  bool takeProfitEnabled = false;
  bool stopLossEnabled = false;
  bool advanceSettingsExpanded = false;
  bool trailingStopEnabled = false;
  bool breakEvenEnabled = false;

  // Partial close volume
  double partialCloseVolume = 0.03;

  // Controllers
  late TextEditingController takeProfitController;
  late TextEditingController stopLossController;
  late TextEditingController trailingStopController;
  late TextEditingController breakEvenController;

  @override
  void initState() {
    super.initState();
    takeProfitController = TextEditingController();
    stopLossController = TextEditingController();
    trailingStopController = TextEditingController();
    breakEvenController = TextEditingController();
  }

  @override
  void dispose() {
    takeProfitController.dispose();
    stopLossController.dispose();
    trailingStopController.dispose();
    breakEvenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.position.profitLoss >= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
        ),
        title: Text(
          'Edit Order',
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
            // Order Overview Section
            _buildOrderOverview(isPositive),
            _buildOrderDetailsList(),

            // Tabs
            _buildTabs(),

            // Content
            Expanded(
              child:
                  selectedTab == 0
                      ? _buildEditContent()
                      : _buildPartialCloseContent(),
            ),

            // Bottom Action Buttons
            // _buildBottomActions(),
            _buildSimpleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderOverview(bool isPositive) {
    return Container(
      margin: EdgeInsets.all(16.w),

      // padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Left side: Flag and Symbol
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.position.flag, style: TextStyle(fontSize: 24.sp)),
                  SizedBox(width: 8.w),
                  Column(
                    children: [
                      Text(
                        widget.position.symbol,
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          SvgPicture.asset(
                            widget.position.action == 'Buy'
                                ? 'assets/svg/trade/green_up_icon.svg'
                                : 'assets/svg/trade/red_down_icon.svg',
                            height: 12.h,
                            width: 12.w,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${widget.position.action} ${widget.position.volume}',
                            style: AppTextStyles.label.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  widget.position.action == 'Buy'
                                      ? AppColors.success
                                      : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Right side: Profit/Loss and Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${widget.position.profitLoss.toStringAsFixed(2)}',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${widget.position.entryPrice} → ${widget.position.currentPrice}',
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

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 0),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color:
                          selectedTab == 0
                              ? AppColors.primary
                              : Colors.transparent,
                      width: 2.w,
                    ),
                  ),
                ),
                child: Text(
                  'Edit',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        selectedTab == 0
                            ? AppColors.textPrimary
                            : AppColors.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 1),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color:
                          selectedTab == 1
                              ? AppColors.primary
                              : Colors.transparent,
                      width: 2.w,
                    ),
                  ),
                ),
                child: Text(
                  'Partial close',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        selectedTab == 1
                            ? AppColors.textPrimary
                            : AppColors.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Details List
          SizedBox(height: 24.h),

          // Order Settings Section
          Text(
            'Order Settings',
            style: AppTextStyles.heading.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          // Take Profit
          _buildSwitchTile(
            'Take Profit',
            takeProfitEnabled,
            onChanged: (value) {
              setState(() {
                takeProfitEnabled = value;
                if (value) {
                  stopLossEnabled = false;
                  trailingStopEnabled = false;
                  breakEvenEnabled = false;
                }
              });
            },
          ),
          if (takeProfitEnabled)
            _buildPriceInput('Take Profit', takeProfitController, 1.15550),

          // Stop Loss
          _buildSwitchTile(
            'Stop Loss',
            stopLossEnabled,
            onChanged: (value) {
              setState(() {
                stopLossEnabled = value;
                if (value) {
                  takeProfitEnabled = false;
                  trailingStopEnabled = false;
                  breakEvenEnabled = false;
                }
              });
            },
          ),
          if (stopLossEnabled)
            _buildPriceInput('Stop Loss', stopLossController, 1.15448),

          // Advanced Settings
          _buildAdvancedSettings(),

          // Trailing Stop
          _buildSwitchTile(
            'Trailing Stop',
            trailingStopEnabled,
            onChanged: (value) {
              setState(() {
                trailingStopEnabled = value;
                if (value) {
                  takeProfitEnabled = false;
                  stopLossEnabled = false;
                  breakEvenEnabled = false;
                }
              });
            },
          ),
          if (trailingStopEnabled)
            _buildPriceInput('Trailing Stop', trailingStopController, 40.0),

          // Break Even
          _buildSwitchTile(
            'Break even',
            breakEvenEnabled,
            onChanged: (value) {
              setState(() {
                breakEvenEnabled = value;
                if (value) {
                  takeProfitEnabled = false;
                  stopLossEnabled = false;
                  trailingStopEnabled = false;
                }
              });
            },
          ),
          if (breakEvenEnabled)
            _buildPriceInput('Break Even', breakEvenController, 0.0),
        ],
      ),
    );
  }

  Widget _buildPartialCloseContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Details List

          // Volume to Close Input
          _buildVolumeToCloseInput(),
          SizedBox(height: 24.h),

          // Partial Close Summary
          _buildPartialCloseSummary(),
        ],
      ),
    );
  }

  Widget _buildVolumeToCloseInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Container(
          height: 60.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Minus button
              Container(
                width: 20.w,
                height: 20.h,
                alignment: Alignment.center,
                margin: EdgeInsets.only(left: 8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (partialCloseVolume > 0.01) {
                        partialCloseVolume -= 0.01;
                      }
                    });
                  },
                  icon: Icon(
                    Icons.remove,
                    size: 10.h,
                    color: AppColors.primary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),

              // Volume input field
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Volume to close',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      partialCloseVolume.toStringAsFixed(2),
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Plus button
              Container(
                width: 20.w,
                height: 20.h,
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (partialCloseVolume < widget.position.volume) {
                        partialCloseVolume += 0.01;
                      }
                    });
                  },
                  icon: Icon(Icons.add, size: 10.h, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartialCloseSummary() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        // color: AppColors.cardBackGround,
        // borderRadius: BorderRadius.circular(12.r),
        // border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Total volume',
            widget.position.volume.toStringAsFixed(2),
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            'Remaining volume',
            (widget.position.volume - partialCloseVolume).toStringAsFixed(2),
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            'Profit from partial close',
            '-\$${(widget.position.profitLoss * (partialCloseVolume / widget.position.volume)).toStringAsFixed(2)}',
            isProfit: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isProfit = false}) {
    return Row(
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
            color:
                isProfit
                    ? (value.startsWith('-')
                        ? AppColors.error
                        : AppColors.success)
                    : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Open Time', widget.position.openTime),
          _buildDetailRow(
            'Gross Profit',
            '\$${widget.position.profitLoss.toStringAsFixed(2)}',
          ),
          _buildDetailRow('Swap', '\$${widget.position.swap}'),
          _buildDetailRow('Position ID', '#${widget.position.orderId}'),
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
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.label.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.icongrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value, {
    required Function(bool) onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            style: AppTextStyles.label.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: SizedBox(
              height: 20.h,
              width: 25.w,
              child: Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withOpacity(0.3),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: AppColors.icongrey.withAlpha(55),
                  trackOutlineColor: MaterialStateProperty.all(
                    Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              advanceSettingsExpanded = !advanceSettingsExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Advanced Settings',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                Icon(
                  advanceSettingsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                  size: 20.h,
                ),
              ],
            ),
          ),
        ),
        if (advanceSettingsExpanded) ...[
          SizedBox(height: 8.h),
          // Add advanced settings content here if needed
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.cardBackGround,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'Advanced settings content will be added here',
              style: AppTextStyles.label.copyWith(
                fontSize: 12.sp,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceInput(
    String label,
    TextEditingController controller,
    double defaultValue,
  ) {
    // Initialize controller with default value if empty
    if (controller.text.isEmpty) {
      controller.text = defaultValue.toStringAsFixed(5);
    }

    return Column(
      children: [
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 236.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Minus button
                  Padding(
                    padding: EdgeInsets.only(left: 17.w),
                    child: Container(
                      width: 22.w,
                      height: 22.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        onPressed: () {
                          final currentValue =
                              double.tryParse(controller.text) ?? defaultValue;
                          if (currentValue > 0.01) {
                            final newValue = currentValue - 0.01;
                            controller.text = newValue.toStringAsFixed(5);
                          }
                        },
                        icon: Icon(
                          Icons.remove,
                          size: 16.h,
                          color: AppColors.icongrey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Price input field
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textGrey,
                          ),
                        ),
                        TextField(
                          controller: controller,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: (value) {
                            // Handle input validation if needed
                          },
                        ),
                      ],
                    ),
                  ),
                  // Plus button
                  Padding(
                    padding: EdgeInsets.only(right: 17.w),
                    child: Container(
                      width: 22.w,
                      height: 22.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: IconButton(
                        onPressed: () {
                          final currentValue =
                              double.tryParse(controller.text) ?? defaultValue;
                          final newValue = currentValue + 0.01;
                          controller.text = newValue.toStringAsFixed(5);
                        },
                        icon: Icon(
                          Icons.add,
                          size: 16.h,
                          color: AppColors.primary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Price type dropdown (optional)
            Container(
              width: 96.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                'Points',
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        // Additional info text (optional)
        Text(
          '68 points | Profit +4.08 USD | +0.08% of balance',
          style: AppTextStyles.label.copyWith(
            fontSize: 12.sp,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // History Button
          // SizedBox(
          //   width: double.infinity,
          //   child: OutlinedButton(
          //     onPressed: () {
          //       // TODO: Navigate to history
          //     },
          //     style: OutlinedButton.styleFrom(
          //       side: BorderSide(color: AppColors.primary),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8.r),
          //       ),
          //       padding: EdgeInsets.symmetric(vertical: 16.h),
          //     ),
          //     child: Text(
          //       'History',
          //       style: AppTextStyles.label.copyWith(
          //         fontSize: 16.sp,
          //         fontWeight: FontWeight.w600,
          //         color: AppColors.primary,
          //       ),
          //     ),
          //   ),
          // ),

          // SizedBox(height: 12.h),

          // // Show Chart Button
          // SizedBox(
          //   width: double.infinity,
          //   child: OutlinedButton(
          //     onPressed: () {
          //       // TODO: Navigate to chart
          //     },
          //     style: OutlinedButton.styleFrom(
          //       backgroundColor: AppColors.primary.withOpacity(0.1),
          //       side: BorderSide(color: AppColors.primary),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8.r),
          //       ),
          //       padding: EdgeInsets.symmetric(vertical: 16.h),
          //     ),
          //     child: Text(
          //       'Show Chart',
          //       style: AppTextStyles.label.copyWith(
          //         fontSize: 16.sp,
          //         fontWeight: FontWeight.w600,
          //         color: AppColors.primary,
          //       ),
          //     ),
          //   ),
          // ),
          // SizedBox(height: 12.h),

          // // Close Order Button
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: () {
          //       // TODO: Close order logic
          //     },
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppColors.primary,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8.r),
          //       ),
          //       padding: EdgeInsets.symmetric(vertical: 16.h),
          //     ),
          //     child: Column(
          //       children: [
          //         Text(
          //           'Close order',
          //           style: AppTextStyles.label.copyWith(
          //             fontSize: 16.sp,
          //             fontWeight: FontWeight.w600,
          //             color: Colors.white,
          //           ),
          //         ),
          //         SizedBox(height: 4.h),
          //         Text(
          //           '\$${widget.position.profitLoss.toStringAsFixed(2)}',
          //           style: AppTextStyles.label.copyWith(
          //             fontSize: 14.sp,
          //             fontWeight: FontWeight.w600,
          //             color: Colors.white,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Bottom action buttons
  Widget _buildSimpleButton() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          if (selectedTab == 0) ...[
            // History Button
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to history
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: Text(
                  'Discard',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Show Chart Button
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.45,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to chart
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  side: BorderSide(color: AppColors.primary),
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
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],

          if (selectedTab == 1) ...[
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.91,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to chart
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: Text(
                  'Close ${partialCloseVolume} lots',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
          // SizedBox(height: 12.h),

          // // Close Order Button
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: () {
          //       // TODO: Close order logic
          //     },
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppColors.primary,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8.r),
          //       ),
          //       padding: EdgeInsets.symmetric(vertical: 16.h),
          //     ),
          //     child: Column(
          //       children: [
          //         Text(
          //           'Close order',
          //           style: AppTextStyles.label.copyWith(
          //             fontSize: 16.sp,
          //             fontWeight: FontWeight.w600,
          //             color: Colors.white,
          //           ),
          //         ),
          //         SizedBox(height: 4.h),
          //         Text(
          //           '\$${widget.position.profitLoss.toStringAsFixed(2)}',
          //           style: AppTextStyles.label.copyWith(
          //             fontSize: 14.sp,
          //             fontWeight: FontWeight.w600,
          //             color: Colors.white,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
