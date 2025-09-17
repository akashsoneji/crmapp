import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/color.dart';
import '../../constants/text_styles.dart';
import '../../controllers/chart_socket_controller.dart';
import '../../controllers/account_controller.dart';
import 'package:get/get.dart';

class PendingOrderContent extends StatefulWidget {
  final ValueNotifier<int> selectedPendingOrderType;
  final ValueNotifier<double> limitPrice;
  final ValueNotifier<double> openPrice;
  final ValueNotifier<double> distance;
  final ValueNotifier<bool> whenPriceIsEnabled;
  final ValueNotifier<bool> takeProfitEnabled;
  final ValueNotifier<bool> stopLossEnabled;
  final ValueNotifier<double> takeProfitPrice;
  final ValueNotifier<double> stopLossPrice;
  final TextEditingController takeProfitController;
  final TextEditingController stopLossController;
  final TextEditingController limitPriceController;
  final VoidCallback onPlaceOrder;
  final String selectedSymbol;
  final Function(double) onVolumeChanged;

  const PendingOrderContent({
    Key? key,
    required this.selectedPendingOrderType,
    required this.limitPrice,
    required this.openPrice,
    required this.distance,
    required this.whenPriceIsEnabled,
    required this.takeProfitEnabled,
    required this.stopLossEnabled,
    required this.takeProfitPrice,
    required this.stopLossPrice,
    required this.takeProfitController,
    required this.stopLossController,
    required this.limitPriceController,
    required this.onPlaceOrder,
    required this.selectedSymbol,
    required this.onVolumeChanged,
  }) : super(key: key);

  @override
  State<PendingOrderContent> createState() => _PendingOrderContentState();
}

class _PendingOrderContentState extends State<PendingOrderContent> {
  late ChartSocketController chartSocketController;
  late AccountController accountController;

  // Live price data
  double? currentBidPrice;
  double? currentAskPrice;
  double volume = 0.01;

  // Flag to track manual price editing
  bool isManuallyEditingPrice = false;

  @override
  void initState() {
    super.initState();

    // Get controllers
    chartSocketController = Get.find<ChartSocketController>();
    accountController = Get.find<AccountController>();

    // Initialize limit price controller
    widget.limitPriceController.text = widget.limitPrice.value.toStringAsFixed(
      5,
    );

    // Initialize with current prices
    _updatePrices();

    // Listen to price updates
    chartSocketController.priceStream.listen((priceData) {
      if (mounted) {
        setState(() {
          _updatePrices();
        });
      }
    });

    // Listen to order type changes
    widget.selectedPendingOrderType.addListener(() {
      if (mounted) {
        setState(() {
          isManuallyEditingPrice = false; // Reset flag when order type changes
          _updatePrices();
        });
      }
    });
  }

  void _updatePrices() {
    currentBidPrice = chartSocketController.getBidPrice();
    currentAskPrice = chartSocketController.getAskPrice();

    // Only update limit price if user is not manually editing
    if (!isManuallyEditingPrice) {
      // Update limit price based on current order type
      if (widget.selectedPendingOrderType.value == 0) {
        // Sell Limit - use bid price
        widget.limitPrice.value = currentBidPrice ?? 3673.90;
        widget.limitPriceController.text = widget.limitPrice.value
            .toStringAsFixed(5);
      } else {
        // Buy Limit - use ask price
        widget.limitPrice.value = currentAskPrice ?? 3674.16;
        widget.limitPriceController.text = widget.limitPrice.value
            .toStringAsFixed(5);
      }
    }

    // Always update Take Profit and Stop Loss based on current market prices
    if (widget.takeProfitEnabled.value) {
      if (widget.selectedPendingOrderType.value == 0) {
        // Sell Limit - Take Profit below current price
        widget.takeProfitPrice.value = (currentBidPrice ?? 3673.90) - 1.0;
      } else {
        // Buy Limit - Take Profit above current price
        widget.takeProfitPrice.value = (currentAskPrice ?? 3674.16) + 1.0;
      }
    }

    if (widget.stopLossEnabled.value) {
      if (widget.selectedPendingOrderType.value == 0) {
        // Sell Limit - Stop Loss above current price
        widget.stopLossPrice.value = (currentBidPrice ?? 3673.90) + 1.0;
      } else {
        // Buy Limit - Stop Loss below current price
        widget.stopLossPrice.value = (currentAskPrice ?? 3674.16) - 1.0;
      }
    }
  }

  // Calculate profit/loss for Take Profit
  double _calculateTakeProfitValue() {
    if (!widget.takeProfitEnabled.value) return 0.0;

    // Use limit price for limit orders, current market price for market orders
    final currentPrice =
        widget.whenPriceIsEnabled.value
            ? widget.limitPrice.value
            : (widget.selectedPendingOrderType.value == 0
                ? currentBidPrice
                : currentAskPrice);

    if (currentPrice == null || currentPrice == 0) return 0.0;

    final priceDiff = widget.takeProfitPrice.value - currentPrice;

    // For EURUSD: 1 pip = 0.0001, 1 lot = 100,000 units
    // For XAUUSD: 1 pip = 0.01, 1 lot = 100 ounces
    if (widget.selectedSymbol.contains('EUR') ||
        widget.selectedSymbol.contains('USD')) {
      return priceDiff * volume * 100000; // EURUSD calculation
    } else {
      return priceDiff * volume * 100; // XAUUSD calculation
    }
  }

  // Calculate loss for Stop Loss
  double _calculateStopLossValue() {
    if (!widget.stopLossEnabled.value) return 0.0;

    // Use limit price for limit orders, current market price for market orders
    final currentPrice =
        widget.whenPriceIsEnabled.value
            ? widget.limitPrice.value
            : (widget.selectedPendingOrderType.value == 0
                ? currentBidPrice
                : currentAskPrice);

    if (currentPrice == null || currentPrice == 0) return 0.0;

    final priceDiff = currentPrice - widget.stopLossPrice.value;

    // For EURUSD: 1 pip = 0.0001, 1 lot = 100,000 units
    // For XAUUSD: 1 pip = 0.01, 1 lot = 100 ounces
    if (widget.selectedSymbol.contains('EUR') ||
        widget.selectedSymbol.contains('USD')) {
      return priceDiff * volume * 100000; // EURUSD calculation
    } else {
      return priceDiff * volume * 100; // XAUUSD calculation
    }
  }

  // Calculate required margin
  double _calculateRequiredMargin() {
    final currentPrice =
        widget.selectedPendingOrderType.value == 0
            ? currentBidPrice
            : currentAskPrice;

    if (currentPrice == null) return 0.0;

    // Simple margin calculation - adjust based on your broker's requirements
    return currentPrice * volume * 0.01; // 1% margin
  }

  // Get free margin
  double _getFreeMargin() {
    final activeAccount = accountController.activeMT5Account;
    if (activeAccount == null) return 0.0;

    // This should come from your account data
    return 20007.19; // Placeholder - replace with actual free margin
  }

  // Validate Stop Loss
  String? _validateStopLoss() {
    if (!widget.stopLossEnabled.value) return null;

    // Use limit price for limit orders, current market price for market orders
    final currentPrice =
        widget.whenPriceIsEnabled.value
            ? widget.limitPrice.value
            : (widget.selectedPendingOrderType.value == 0
                ? currentBidPrice
                : currentAskPrice);

    if (currentPrice == null) return null;

    if (widget.selectedPendingOrderType.value == 0) {
      // Sell - Stop Loss should be above current price
      if (widget.stopLossPrice.value <= currentPrice) {
        return 'Stop Loss should be above price ${currentPrice.toStringAsFixed(5)}';
      }
    } else {
      // Buy - Stop Loss should be below current price
      if (widget.stopLossPrice.value >= currentPrice) {
        return 'Stop Loss should be below price ${currentPrice.toStringAsFixed(5)}';
      }
    }

    return null;
  }

  // Validate Take Profit
  String? _validateTakeProfit() {
    if (!widget.takeProfitEnabled.value) return null;

    // Use limit price for limit orders, current market price for market orders
    final currentPrice =
        widget.whenPriceIsEnabled.value
            ? widget.limitPrice.value
            : (widget.selectedPendingOrderType.value == 0
                ? currentBidPrice
                : currentAskPrice);

    if (currentPrice == null) return null;

    if (widget.selectedPendingOrderType.value == 0) {
      // Sell - Take Profit should be below current price
      if (widget.takeProfitPrice.value >= currentPrice) {
        return 'Take Profit should be below price ${currentPrice.toStringAsFixed(5)}';
      }
    } else {
      // Buy - Take Profit should be above current price
      if (widget.takeProfitPrice.value <= currentPrice) {
        return 'Take Profit should be above price ${currentPrice.toStringAsFixed(5)}';
      }
    }

    return null;
  }

  // Validate Limit Price
  String? _validateLimitPrice() {
    // Only validate if "When price is" toggle is ON
    if (!widget.whenPriceIsEnabled.value) return null;

    final currentPrice =
        widget.selectedPendingOrderType.value == 0
            ? currentBidPrice
            : currentAskPrice;

    if (currentPrice == null) return null;

    if (widget.selectedPendingOrderType.value == 0) {
      // Sell Limit - Limit price should be above current price
      if (widget.limitPrice.value <= currentPrice) {
        return 'Sell Limit price should be above ${currentPrice.toStringAsFixed(5)}';
      }
    } else {
      // Buy Limit - Limit price should be below current price
      if (widget.limitPrice.value >= currentPrice) {
        return 'Buy Limit price should be below ${currentPrice.toStringAsFixed(5)}';
      }
    }

    return null;
  }

  // Check if order is valid for placement
  bool _isOrderValid() {
    // For market orders (toggle OFF), only check SL/TP validation
    if (!widget.whenPriceIsEnabled.value) {
      // Market orders - only validate SL/TP if enabled
      if (widget.stopLossEnabled.value && _validateStopLoss() != null)
        return false;
      if (widget.takeProfitEnabled.value && _validateTakeProfit() != null)
        return false;
      return true;
    }

    // For limit orders (toggle ON), check all validations
    if (_validateLimitPrice() != null) return false;
    if (widget.stopLossEnabled.value && _validateStopLoss() != null)
      return false;
    if (widget.takeProfitEnabled.value && _validateTakeProfit() != null)
      return false;

    return true;
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    widget.selectedPendingOrderType.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Limit Order Buttons
          Container(
            padding: EdgeInsets.all(10.spMax),
            decoration: BoxDecoration(
              color: AppColors.cardBackGround,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: ValueListenableBuilder<int>(
              valueListenable: widget.selectedPendingOrderType,
              builder: (context, selectedType, child) {
                return Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.selectedPendingOrderType.value = 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 42,
                          ),
                          height: 55.h,
                          width: 150.w,
                          decoration: BoxDecoration(
                            color:
                                selectedType == 0
                                    ? AppColors.backgroundLight
                                    : AppColors.cardBackGround,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Sell Limit',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w400,
                                  color:
                                      selectedType == 0
                                          ? AppColors.textPrimary
                                          : AppColors.textGrey,
                                ),
                              ),
                              Text(
                                currentBidPrice?.toStringAsFixed(5) ??
                                    '3673.90',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color:
                                      selectedType == 0
                                          ? AppColors.red
                                          : AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.selectedPendingOrderType.value = 1,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 42,
                          ),
                          height: 55.h,
                          width: 150.w,
                          decoration: BoxDecoration(
                            color:
                                selectedType == 1
                                    ? AppColors.backgroundLight
                                    : AppColors.cardBackGround,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Buy Limit',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w400,
                                  color:
                                      selectedType == 1
                                          ? AppColors.textPrimary
                                          : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                currentAskPrice?.toStringAsFixed(5) ??
                                    '3674.16',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color:
                                      selectedType == 1
                                          ? AppColors.green
                                          : AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 14.h),

          // Quantity Section
          _buildQuantitySection(),

          SizedBox(height: 8.h),

          // Monetary Equivalent
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monetary equivalent',
                style: AppTextStyles.label.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGrey,
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: widget.openPrice,
                builder: (context, price, child) {
                  return Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // When Price Is Toggle
          _buildSwitchTile(
            'When price is',
            widget.whenPriceIsEnabled,
            onChanged: (value) {
              widget.whenPriceIsEnabled.value = value;
            },
          ),

          // Open Price Input - Only show when toggle is ON
          ValueListenableBuilder<bool>(
            valueListenable: widget.whenPriceIsEnabled,
            builder: (context, isEnabled, child) {
              if (!isEnabled) return SizedBox.shrink();
              return Column(
                children: [
                  _buildOpenPriceInput(),
                  // Error message for Limit Price
                  if (_validateLimitPrice() != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      child: Text(
                        _validateLimitPrice()!,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          SizedBox(height: 16.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance',
                style: AppTextStyles.label.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textGrey,
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: widget.distance,
                builder: (context, distanceValue, child) {
                  return Text(
                    '${distanceValue.toStringAsFixed(2)} points',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Take Profit
          _buildSwitchTile(
            'Take Profit',
            widget.takeProfitEnabled,
            onChanged: (value) {
              widget.takeProfitEnabled.value = value;
              if (value) widget.stopLossEnabled.value = false;
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: widget.takeProfitEnabled,
            builder: (context, enabled, child) {
              if (!enabled) return SizedBox.shrink();
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPriceInputField(
                        'Take Profit',
                        widget.takeProfitPrice,
                        widget.takeProfitController,
                      ),
                      Container(
                        width: 96.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: _buildPriceTypeDropdown(),
                      ),
                    ],
                  ),
                  // Profit calculation display
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profit: \$${_calculateTakeProfitValue().toStringAsFixed(2)}',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.green,
                          ),
                        ),
                        Icon(
                          Icons.info_outline,
                          size: 16.h,
                          color: AppColors.textGrey,
                        ),
                      ],
                    ),
                  ),
                  // Error message for Take Profit
                  if (_validateTakeProfit() != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      child: Text(
                        _validateTakeProfit()!,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  SizedBox(height: 8.h),
                ],
              );
            },
          ),

          // Stop Loss
          _buildSwitchTile(
            'Stop Loss',
            widget.stopLossEnabled,
            onChanged: (value) {
              widget.stopLossEnabled.value = value;
              if (value) widget.takeProfitEnabled.value = false;
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: widget.stopLossEnabled,
            builder: (context, enabled, child) {
              if (!enabled) return SizedBox.shrink();
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPriceInputField(
                        'Stop Loss',
                        widget.stopLossPrice,
                        widget.stopLossController,
                      ),
                      Container(
                        width: 96.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: _buildPriceTypeDropdown(),
                      ),
                    ],
                  ),
                  // Loss calculation display
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Loss: \$${_calculateStopLossValue().toStringAsFixed(2)}',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.red,
                          ),
                        ),
                        Icon(
                          Icons.info_outline,
                          size: 16.h,
                          color: AppColors.textGrey,
                        ),
                      ],
                    ),
                  ),
                  // Error message for Stop Loss
                  if (_validateStopLoss() != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      child: Text(
                        _validateStopLoss()!,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  SizedBox(height: 8.h),
                ],
              );
            },
          ),

          SizedBox(height: 24.h),

          // Confirm Button
          GestureDetector(
            onTap: _isOrderValid() ? widget.onPlaceOrder : null,
            child: Container(
              width: double.infinity,
              height: 50.h,
              decoration: BoxDecoration(
                color:
                    _isOrderValid()
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ValueListenableBuilder<int>(
                valueListenable: widget.selectedPendingOrderType,
                builder: (context, orderType, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: widget.whenPriceIsEnabled,
                    builder: (context, isConditional, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isOrderValid()
                                ? 'Place pending order'
                                : 'Fix validation errors',
                            style: AppTextStyles.button.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color:
                                  _isOrderValid()
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Container(
      height: 117.h,
      width: 343.w,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Quantity input row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
            child: Row(
              children: [
                // Minus button
                Container(
                  height: 24.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.icongrey),
                  ),
                  width: 24.w,
                  child: IconButton(
                    onPressed: () {
                      if (volume > 0.01) {
                        setState(() {
                          volume -= 0.01;
                          widget.onVolumeChanged(volume);
                        });
                      }
                    },
                    icon: Icon(
                      Icons.remove,
                      size: 18.h,
                      color: AppColors.icongrey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
                SizedBox(width: 8.w),
                // Quantity display
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Quantity (lots)',
                        style: AppTextStyles.labelOnTradeQuantity,
                      ),
                      Text(
                        volume.toStringAsFixed(2),
                        style: AppTextStyles.labelOnTradeQuantityDigit,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Plus button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  width: 24.w,
                  height: 24.h,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        volume += 0.01;
                        widget.onVolumeChanged(volume);
                      });
                    },
                    icon: Icon(Icons.add, size: 18.h, color: AppColors.primary),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
          Container(width: double.maxFinite, height: 2, color: AppColors.grey),
          SizedBox(height: 6.h),

          // Required Margin
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 11.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Required Margin",
                      style: AppTextStyles.labelOnChartPendingOrder,
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.info_outline_rounded, size: 16.h),
                  ],
                ),
                Text(
                  "\$${_calculateRequiredMargin().toStringAsFixed(2)}",
                  style: AppTextStyles.labelOnChartPendingOrderBold,
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),

          // Free Margin
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 11.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Free margin",
                  style: AppTextStyles.labelOnChartPendingOrder,
                ),
                Text(
                  "\$${_getFreeMargin().toStringAsFixed(2)}",
                  style: AppTextStyles.labelOnChartPendingOrder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenPriceInput() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 2.h),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 11.w),
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
            Container(
              height: 24.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.icongrey),
              ),
              width: 24.w,
              child: IconButton(
                onPressed: () {
                  if (widget.limitPrice.value > 0.01) {
                    isManuallyEditingPrice = true; // User is manually editing
                    widget.limitPrice.value -= 0.01;
                    widget.limitPriceController.text = widget.limitPrice.value
                        .toStringAsFixed(5);
                  }
                },
                icon: Icon(Icons.remove, size: 18.h, color: AppColors.icongrey),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),

            // Price input field
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Price', style: AppTextStyles.labelOnTradeQuantity),
                  TextField(
                    controller: widget.limitPriceController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelOnTradeQuantityDigit,
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
                      isManuallyEditingPrice = true; // User is manually editing
                      final newPrice = double.tryParse(value);
                      if (newPrice != null && newPrice > 0) {
                        widget.limitPrice.value = newPrice;
                      }
                    },
                  ),
                ],
              ),
            ),

            // Plus button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              width: 24.w,
              height: 24.h,
              child: IconButton(
                onPressed: () {
                  isManuallyEditingPrice = true; // User is manually editing
                  widget.limitPrice.value += 0.01;
                  widget.limitPriceController.text = widget.limitPrice.value
                      .toStringAsFixed(5);
                },
                icon: Icon(Icons.add, size: 18.h, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInputField(
    String label,
    ValueNotifier<double> priceNotifier,
    TextEditingController controller,
  ) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.only(left: 17.0),
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
                  if (priceNotifier.value > 0.01) {
                    priceNotifier.value -= 0.01;
                    controller.text = priceNotifier.value.toStringAsFixed(5);
                  }
                },
                icon: Icon(Icons.remove, size: 16.h, color: AppColors.icongrey),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
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
                          final newPrice = double.tryParse(value);
                          if (newPrice != null && newPrice > 0) {
                            priceNotifier.value = newPrice;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
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
                  priceNotifier.value += 0.01;
                  controller.text = priceNotifier.value.toStringAsFixed(5);
                },
                icon: Icon(Icons.add, size: 16.h, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    ValueNotifier<bool> valueNotifier, {
    required Function(bool) onChanged,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
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
                padding: const EdgeInsets.only(right: 16.0),
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
                      inactiveThumbColor: AppColors.whiteColor,
                      inactiveTrackColor: AppColors.icongrey.withAlpha(55),
                      trackOutlineColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceTypeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'Asset Price',
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16.h,
            color: AppColors.textGrey,
          ),
          style: AppTextStyles.label.copyWith(
            fontSize: 12.sp,
            color: AppColors.textGrey,
          ),
          items: [
            DropdownMenuItem<String>(
              value: 'Asset Price',
              child: Text('Asset Price'),
            ),
            DropdownMenuItem<String>(
              value: 'Profit in \$',
              child: Text('Profit in \$'),
            ),
          ],
          onChanged: (String? newValue) {
            // Handle dropdown change
          },
        ),
      ),
    );
  }
}
