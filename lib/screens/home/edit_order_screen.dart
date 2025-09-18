import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/controllers/chart_socket_controller.dart';
import 'package:pipze/controllers/chart_controller.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/widgets/custom_toast.dart';

class EditOrderScreen extends StatefulWidget {
  final TradePosition position;

  const EditOrderScreen({super.key, required this.position});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  int selectedTab = 0; // 0: Edit, 1: Partial close

  // Order type selection
  int selectedOrderType = 0; // 0: Market, 1: Buy Limit, 2: Sell Limit

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
  late TextEditingController limitPriceController;

  // Real-time price data
  late final ChartSocketController chartSocketController;
  late final ChartController chartController;
  late final AccountController accountController;

  // Current market prices
  double? currentBidPrice;
  double? currentAskPrice;
  String? currentSymbol;

  // Validation states
  String? limitPriceError;
  String? stopLossError;
  String? takeProfitError;

  @override
  void initState() {
    super.initState();
    takeProfitController = TextEditingController();
    stopLossController = TextEditingController();
    trailingStopController = TextEditingController();
    breakEvenController = TextEditingController();
    limitPriceController = TextEditingController();

    // Initialize controllers
    _initializeControllers();

    // Initialize current symbol and prices
    currentSymbol = widget.position.symbol;
    _initializePrices();
    _setupPriceListener();
  }

  void _initializeControllers() {
    // Initialize ChartSocketController
    try {
      chartSocketController = Get.find<ChartSocketController>();
      print('EditOrderScreen: ChartSocketController found');
    } catch (e) {
      print(
        'EditOrderScreen: ChartSocketController not found, creating new one: $e',
      );
      chartSocketController = ChartSocketController();
      Get.put(chartSocketController, permanent: true);
    }

    // Initialize ChartController
    try {
      chartController = Get.find<ChartController>();
      print('EditOrderScreen: ChartController found');
    } catch (e) {
      print('EditOrderScreen: ChartController not found, creating new one: $e');
      chartController = ChartController();
      Get.put(chartController, permanent: true);
    }

    // Initialize AccountController
    try {
      accountController = Get.find<AccountController>();
      print('EditOrderScreen: AccountController found');
    } catch (e) {
      print('EditOrderScreen: AccountController not found: $e');
      // AccountController should always be available, but just in case
      Get.snackbar('Error', 'Account controller not available');
    }
  }

  void _initializePrices() {
    // Get current prices from chart socket controller
    final priceData = chartSocketController.getCurrentPrice();
    if (priceData != null) {
      currentBidPrice = chartSocketController.getBidPrice();
      currentAskPrice = chartSocketController.getAskPrice();

      // Initialize limit price based on order type
      if (selectedOrderType == 1) {
        // Buy Limit
        limitPriceController.text = currentBidPrice?.toStringAsFixed(5) ?? '';
      } else if (selectedOrderType == 2) {
        // Sell Limit
        limitPriceController.text = currentAskPrice?.toStringAsFixed(5) ?? '';
      }
    }
  }

  void _setupPriceListener() {
    // Listen to real-time price updates
    chartSocketController.priceStream.listen((priceData) {
      if (mounted) {
        setState(() {
          currentBidPrice = chartSocketController.getBidPrice();
          currentAskPrice = chartSocketController.getAskPrice();
          _validateLimitPrice();
          _validateStopLoss();
          _validateTakeProfit();
        });
      }
    });
  }

  // Validation methods
  void _validateLimitPrice() {
    if (selectedOrderType == 0)
      return; // Market order doesn't need limit price validation

    final limitPrice = double.tryParse(limitPriceController.text);
    if (limitPrice == null) {
      limitPriceError = 'Invalid price format';
      return;
    }

    if (selectedOrderType == 1) {
      // Buy Limit
      if (currentAskPrice != null && limitPrice >= currentAskPrice!) {
        limitPriceError =
            'Buy Limit should be below current price ${currentAskPrice!.toStringAsFixed(5)}';
      } else {
        limitPriceError = null;
      }
    } else if (selectedOrderType == 2) {
      // Sell Limit
      if (currentBidPrice != null && limitPrice <= currentBidPrice!) {
        limitPriceError =
            'Sell Limit should be above current price ${currentBidPrice!.toStringAsFixed(5)}';
      } else {
        limitPriceError = null;
      }
    }
  }

  void _validateStopLoss() {
    if (!stopLossEnabled) return;

    final stopLossPrice = double.tryParse(stopLossController.text);
    if (stopLossPrice == null) {
      stopLossError = 'Invalid price format';
      return;
    }

    if (selectedOrderType == 1) {
      // Buy Limit
      if (currentAskPrice != null && stopLossPrice >= currentAskPrice!) {
        stopLossError =
            'Stop Loss should be below current price ${currentAskPrice!.toStringAsFixed(5)}';
      } else {
        stopLossError = null;
      }
    } else if (selectedOrderType == 2) {
      // Sell Limit
      if (currentBidPrice != null && stopLossPrice <= currentBidPrice!) {
        stopLossError =
            'Stop Loss should be above current price ${currentBidPrice!.toStringAsFixed(5)}';
      } else {
        stopLossError = null;
      }
    }
  }

  void _validateTakeProfit() {
    if (!takeProfitEnabled) return;

    final takeProfitPrice = double.tryParse(takeProfitController.text);
    if (takeProfitPrice == null) {
      takeProfitError = 'Invalid price format';
      return;
    }

    if (selectedOrderType == 1) {
      // Buy Limit
      if (currentBidPrice != null && takeProfitPrice <= currentBidPrice!) {
        takeProfitError =
            'Take Profit should be above current price ${currentBidPrice!.toStringAsFixed(5)}';
      } else {
        takeProfitError = null;
      }
    } else if (selectedOrderType == 2) {
      // Sell Limit
      if (currentAskPrice != null && takeProfitPrice >= currentAskPrice!) {
        takeProfitError =
            'Take Profit should be below current price ${currentAskPrice!.toStringAsFixed(5)}';
      } else {
        takeProfitError = null;
      }
    }
  }

  // Order placement method
  Future<void> _placeOrder() async {
    if (!_isOrderValid()) return;

    final activeAccount = accountController.activeMT5Account;
    if (activeAccount == null) {
      Get.snackbar('Error', 'No active account found');
      return;
    }

    try {
      String orderType;
      String? price;

      switch (selectedOrderType) {
        case 0: // Market
          orderType = widget.position.action == 'Buy' ? '0' : '1';
          break;
        case 1: // Buy Limit
          orderType = '2';
          price = limitPriceController.text;
          break;
        case 2: // Sell Limit
          orderType = '3';
          price = limitPriceController.text;
          break;
        default:
          orderType = '0';
      }

      // Ensure chartController is available
      if (!Get.isRegistered<ChartController>()) {
        chartController = ChartController();
        Get.put(chartController, permanent: true);
      }

      print(
        'EditOrderScreen: Placing order with type: $orderType, price: $price',
      );
      final success = await chartController.placeTradeOrder(
        mt5Account: activeAccount.metaAccountNumber,
        symbol: widget.position.symbol,
        volume: widget.position.volume,
        type: orderType,
        price: price,
        priceSl: stopLossEnabled ? stopLossController.text : '',
        priceTp: takeProfitEnabled ? takeProfitController.text : '',
      );

      if (success) {
        Get.back();
        CustomToastService.showSuccess(
          title: 'Success',
          message: 'Order placed successfully',
        );
      }
    } catch (e) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Failed to place order: $e',
      );
    }
  }

  bool _isOrderValid() {
    _validateLimitPrice();
    _validateStopLoss();
    _validateTakeProfit();

    if (selectedOrderType > 0 && limitPriceError != null) return false;
    if (stopLossEnabled && stopLossError != null) return false;
    if (takeProfitEnabled && takeProfitError != null) return false;

    return true;
  }

  @override
  void dispose() {
    takeProfitController.dispose();
    stopLossController.dispose();
    trailingStopController.dispose();
    breakEvenController.dispose();
    limitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.position.profitLoss >= 0;

    // Check if controllers are available
    if (!Get.isRegistered<ChartSocketController>()) {
      return Scaffold(
        body: Center(
          child: Text('Chart controller not available. Please try again.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
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
            _buildOrderSummary(widget.position, isPositive),
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

  Widget _buildOrderSummary(TradePosition position, bool isPositive) {
    return Container(
      // margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(24.w),

      child: Row(
        children: [
          // Flag and Symbol
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(position.flag, style: TextStyle(fontSize: 30.sp)),
                  SizedBox(width: 8.w),
                  Column(
                    children: [
                      Text(position.symbol, style: AppTextStyles.black14500),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          SvgPicture.asset(
                            position.action == 'Buy'
                                ? 'assets/svg/trade/green_up_icon.svg'
                                : 'assets/svg/trade/red_down_icon.svg',
                            height: 9.h,
                            width: 9.w,
                          ),
                          SizedBox(width: 2.w),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${position.action}',
                                  style: AppTextStyles.black11400,
                                ),
                                TextSpan(
                                  text: ' ${position.volume}',
                                  style: AppTextStyles.grey11400,
                                ),
                              ],
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

          // Profit/Loss and Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${position.profitLoss.toStringAsFixed(2)}',
                style: AppTextStyles.black14500.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
                  height: 1.4,
                ),
              ),

              Text(
                '${position.entryPrice} → ${position.currentPrice}',
                style: AppTextStyles.grey10400,
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
                    fontWeight: FontWeight.w400,
                    color:
                        selectedTab == 0
                            ? AppColors.textPrimary
                            : AppColors.textGrey,
                    height: 1.57,
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
                    fontWeight: FontWeight.w400,
                    color:
                        selectedTab == 1
                            ? AppColors.textPrimary
                            : AppColors.textGrey,
                    height: 1.57,
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
          // Order Type Selection
          _buildOrderTypeSelection(),
          SizedBox(height: 20.h),

          // Limit Price Input (for Buy Limit and Sell Limit)
          if (selectedOrderType > 0) ...[
            _buildLimitPriceInput(),
            SizedBox(height: 16.h),
          ],

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
                _validateTakeProfit();
              });
            },
          ),
          if (takeProfitEnabled)
            _buildPriceInput(
              'Take Profit',
              takeProfitController,
              1.15550,
              error: takeProfitError,
            ),

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
                _validateStopLoss();
              });
            },
          ),
          if (stopLossEnabled)
            _buildPriceInput(
              'Stop Loss',
              stopLossController,
              1.15448,
              error: stopLossError,
            ),

          // Advanced Settings
          // _buildAdvancedSettings(),

          // Trailing Stop
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
          height: 48.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Minus button
              Container(
                width: 24.w,
                height: 24.h,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                margin: EdgeInsets.only(left: 12.w),
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
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      partialCloseVolume.toStringAsFixed(2),
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Plus button
              Container(
                width: 24.w,
                height: 24.h,
                margin: EdgeInsets.only(right: 12.w),
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
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.37,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.label.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.icongrey,
              height: 1.57,
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
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.4,
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
          // SizedBox(height: 8.h),
          // // Add advanced settings content here if needed
          // Container(
          //   padding: EdgeInsets.all(12.w),
          //   decoration: BoxDecoration(
          //     color: AppColors.cardBackGround,
          //     borderRadius: BorderRadius.circular(8.r),
          //   ),
          //   child: Text(
          //     'Advanced settings content will be added here',
          //     style: AppTextStyles.label.copyWith(
          //       fontSize: 12.sp,
          //       color: AppColors.textGrey,
          //     ),
          //   ),
          // ),
        ],
      ],
    );
  }

  Widget _buildOrderTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Type',
          style: AppTextStyles.label.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildOrderTypeButton('Market', 0)),
            SizedBox(width: 8.w),
            Expanded(child: _buildOrderTypeButton('Buy Limit', 1)),
            SizedBox(width: 8.w),
            Expanded(child: _buildOrderTypeButton('Sell Limit', 2)),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderTypeButton(String title, int type) {
    final isSelected = selectedOrderType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOrderType = type;
          _initializePrices();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLimitPriceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Limit Price',
          style: AppTextStyles.label.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 50.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color:
                  limitPriceError != null ? AppColors.error : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // Minus button
              Container(
                width: 24.w,
                height: 24.h,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                margin: EdgeInsets.only(left: 12.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                ),
                child: IconButton(
                  onPressed: () {
                    final currentValue =
                        double.tryParse(limitPriceController.text) ?? 0.0;
                    final newValue = currentValue - 0.01;
                    limitPriceController.text = newValue.toStringAsFixed(5);
                    _validateLimitPrice();
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

              // Price input field
              Expanded(
                child: TextField(
                  controller: limitPriceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    hintText: 'Enter price',
                  ),
                  onChanged: (value) {
                    _validateLimitPrice();
                  },
                ),
              ),

              // Plus button
              Container(
                width: 24.w,
                height: 24.h,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                ),
                child: IconButton(
                  onPressed: () {
                    final currentValue =
                        double.tryParse(limitPriceController.text) ?? 0.0;
                    final newValue = currentValue + 0.01;
                    limitPriceController.text = newValue.toStringAsFixed(5);
                    _validateLimitPrice();
                  },
                  icon: Icon(Icons.add, size: 10.h, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
        if (limitPriceError != null) ...[
          SizedBox(height: 4.h),
          Text(
            limitPriceError!,
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceInput(
    String label,
    TextEditingController controller,
    double defaultValue, {
    String? error,
  }) {
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
                border: Border.all(
                  color: error != null ? AppColors.error : AppColors.border,
                ),
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
                            if (label == 'Stop Loss') {
                              _validateStopLoss();
                            } else if (label == 'Take Profit') {
                              _validateTakeProfit();
                            }
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
                            if (label == 'Stop Loss') {
                              _validateStopLoss();
                            } else if (label == 'Take Profit') {
                              _validateTakeProfit();
                            }
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
                          if (label == 'Stop Loss') {
                            _validateStopLoss();
                          } else if (label == 'Take Profit') {
                            _validateTakeProfit();
                          }
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
        if (error != null) ...[
          SizedBox(height: 4.h),
          Text(
            error,
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              color: AppColors.error,
            ),
          ),
        ],
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

  // Bottom action buttons
  Widget _buildSimpleButton() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          if (selectedTab == 0) ...[
            // History Button
            Expanded(
              child: SizedBox(
                height: 46.h,
                width: 169.6.w,

                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to history
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xffEFEAF6),
                    side: BorderSide(color: AppColors.whiteColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Discard',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      height: 1.71,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Confirm Button
            SizedBox(
              height: 46.h,
              width: 169.6.w,
              child: OutlinedButton(
                onPressed: _isOrderValid() ? _placeOrder : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      _isOrderValid()
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.3),
                  side: BorderSide(
                    color:
                        _isOrderValid()
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteColor,
                    height: 1.71,
                  ),
                ),
              ),
            ),
          ],

          if (selectedTab == 1) ...[
            SizedBox(
              height: 46.h,
              width: MediaQuery.of(context).size.width * 0.91,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to chart
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  // padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: Text(
                  'Close ${partialCloseVolume} lots',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteColor,
                    height: 1.71,
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
