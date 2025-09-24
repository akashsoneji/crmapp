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
  int currentDigits = 5; // Default to 5 decimal places

  // Flag to track manual price editing
  bool isManuallyEditingPrice = false;
  bool isManuallyEditingTakeProfit = false;
  bool isManuallyEditingStopLoss = false;

  // Get current digits from API
  int _getCurrentDigits() {
    final priceData = chartSocketController.getCurrentPrice();
    if (priceData != null && priceData.containsKey('digits')) {
      return int.tryParse(priceData['digits'].toString()) ?? 5;
    }
    return 5; // Default fallback
  }

  // Method to recalculate TP/SL based on current limit price
  void _recalculateTPSL() {
    if (widget.limitPrice.value > 0) {
      final entryPrice = widget.limitPrice.value;
      final percentageValue = entryPrice * 0.0115; // 1.15%

      // Only update Take Profit if user hasn't manually edited it
      if (widget.takeProfitEnabled.value && !isManuallyEditingTakeProfit) {
        if (widget.selectedPendingOrderType.value == 0) {
          // Sell Limit - Take Profit BELOW entry price
          widget.takeProfitPrice.value = entryPrice - percentageValue;
        } else {
          // Buy Limit - Take Profit ABOVE entry price
          widget.takeProfitPrice.value = entryPrice + percentageValue;
        }
        widget.takeProfitController.text = widget.takeProfitPrice.value
            .toStringAsFixed(currentDigits);
      }

      // Only update Stop Loss if user hasn't manually edited it
      if (widget.stopLossEnabled.value && !isManuallyEditingStopLoss) {
        if (widget.selectedPendingOrderType.value == 0) {
          // Sell Limit - Stop Loss ABOVE entry price
          widget.stopLossPrice.value = entryPrice + percentageValue;
        } else {
          // Buy Limit - Stop Loss BELOW entry price
          widget.stopLossPrice.value = entryPrice - percentageValue;
        }
        widget.stopLossController.text = widget.stopLossPrice.value
            .toStringAsFixed(currentDigits);
      }
    }
  }

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

    // Add listener to limit price controller for real-time TP/SL recalculation
    widget.limitPriceController.addListener(() {
      final text = widget.limitPriceController.text;
      if (text.isNotEmpty) {
        final newPrice = double.tryParse(text);
        if (newPrice != null && newPrice > 0) {
          widget.limitPrice.value = newPrice;
          // Recalculate TP/SL when limit price changes
          _recalculateTPSL();
        }
      }
    });

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
          isManuallyEditingTakeProfit = false; // Reset TP manual editing
          isManuallyEditingStopLoss = false; // Reset SL manual editing
          _updatePrices();
        });
      }
    });
  }

  void _updatePrices() {
    currentBidPrice = chartSocketController.getBidPrice();
    currentAskPrice = chartSocketController.getAskPrice();
    currentDigits = _getCurrentDigits(); // Update digits from API

    // Only update limit price if user is not manually editing
    if (!isManuallyEditingPrice) {
      // Update limit price based on current order type
      if (widget.selectedPendingOrderType.value == 0) {
        // Sell Limit - use bid price
        widget.limitPrice.value = currentBidPrice ?? 3673.90;
        widget.limitPriceController.text = widget.limitPrice.value
            .toStringAsFixed(currentDigits);
      } else {
        // Buy Limit - use ask price
        widget.limitPrice.value = currentAskPrice ?? 3674.16;
        widget.limitPriceController.text = widget.limitPrice.value
            .toStringAsFixed(currentDigits);
      }
    }

    // Always update Take Profit and Stop Loss based on entry price (limit price for limit orders)
    final entryPrice =
        widget.whenPriceIsEnabled.value
            ? widget.limitPrice.value
            : (widget.selectedPendingOrderType.value == 0
                ? currentBidPrice
                : currentAskPrice);

    if (entryPrice != null) {
      // Calculate 1.15% of the entry price for TP/SL
      final percentageValue = entryPrice * 0.0115; // 1.15%

      // Only update Take Profit if user hasn't manually edited it
      if (widget.takeProfitEnabled.value && !isManuallyEditingTakeProfit) {
        if (widget.selectedPendingOrderType.value == 0) {
          // Sell Limit - Take Profit BELOW entry price (profit when price drops)
          widget.takeProfitPrice.value = entryPrice - percentageValue;
        } else {
          // Buy Limit - Take Profit ABOVE entry price (profit when price rises)
          widget.takeProfitPrice.value = entryPrice + percentageValue;
        }
        // Update the text field
        widget.takeProfitController.text = widget.takeProfitPrice.value
            .toStringAsFixed(currentDigits);
      }

      // Only update Stop Loss if user hasn't manually edited it
      if (widget.stopLossEnabled.value && !isManuallyEditingStopLoss) {
        if (widget.selectedPendingOrderType.value == 0) {
          // Sell Limit - Stop Loss ABOVE entry price (safety net above)
          widget.stopLossPrice.value = entryPrice + percentageValue;
        } else {
          // Buy Limit - Stop Loss BELOW entry price (safety net below)
          widget.stopLossPrice.value = entryPrice - percentageValue;
        }
        // Update the text field
        widget.stopLossController.text = widget.stopLossPrice.value
            .toStringAsFixed(currentDigits);
      }
    }
  }

  // Calculate profit/loss for Take Profit
  double _calculateTakeProfitValue() {
    if (!widget.takeProfitEnabled.value) return 0.0;

    // Use entry price (limit price for limit orders, current market price for market orders)
    final entryPrice =
        widget.whenPriceIsEnabled.value
            ? widget.limitPrice.value
            : (widget.selectedPendingOrderType.value == 0
                ? currentBidPrice
                : currentAskPrice);

    if (entryPrice == null || entryPrice == 0) return 0.0;

    final priceDiff = widget.takeProfitPrice.value - entryPrice;
    final currentVolume = volume;

    // Debug print
    print(
      'TP Calculation: TP=${widget.takeProfitPrice.value}, Entry=$entryPrice, Diff=$priceDiff, Volume=$currentVolume, Symbol=${widget.selectedSymbol}',
    );

    // For EURUSD: 1 pip = 0.0001, 1 lot = 100,000 units
    // For XAUUSD: 1 pip = 0.01, 1 lot = 100 ounces
    double result;
    if (widget.selectedSymbol.contains('EUR') ||
        widget.selectedSymbol.contains('USD')) {
      result = priceDiff * currentVolume * 100000; // EURUSD calculation
    } else {
      result = priceDiff * currentVolume * 100; // XAUUSD calculation
    }

    print('TP Result: $result');
    return result;
  }

  // Calculate loss for Stop Loss
  double _calculateStopLossValue() {
    if (!widget.stopLossEnabled.value) return 0.0;

    // Use entry price (limit price for limit orders, current market price for market orders)
    final entryPrice =
        widget.whenPriceIsEnabled.value
            ? widget.limitPrice.value
            : (widget.selectedPendingOrderType.value == 0
                ? currentBidPrice
                : currentAskPrice);

    if (entryPrice == null || entryPrice == 0) return 0.0;

    final priceDiff = entryPrice - widget.stopLossPrice.value;
    final currentVolume = volume;

    // Debug print
    print(
      'SL Calculation: SL=${widget.stopLossPrice.value}, Entry=$entryPrice, Diff=$priceDiff, Volume=$currentVolume, Symbol=${widget.selectedSymbol}',
    );

    // For EURUSD: 1 pip = 0.0001, 1 lot = 100,000 units
    // For XAUUSD: 1 pip = 0.01, 1 lot = 100 ounces
    double result;
    if (widget.selectedSymbol.contains('EUR') ||
        widget.selectedSymbol.contains('USD')) {
      result = priceDiff * currentVolume * 100000; // EURUSD calculation
    } else {
      result = priceDiff * currentVolume * 100; // XAUUSD calculation
    }

    print('SL Result: $result');
    return result;
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
    final entryPrice =
        widget.whenPriceIsEnabled.value
            ? widget.limitPrice.value
            : (widget.selectedPendingOrderType.value == 0
                ? currentBidPrice
                : currentAskPrice);

    if (entryPrice == null) return null;

    if (widget.selectedPendingOrderType.value == 0) {
      // Sell Limit - Stop Loss should be ABOVE entry price (safety net above)
      if (widget.stopLossPrice.value <= entryPrice) {
        return 'Stop Loss should be above entry price ${entryPrice.toStringAsFixed(currentDigits)}';
      }
    } else {
      // Buy Limit - Stop Loss should be BELOW entry price (safety net below)
      if (widget.stopLossPrice.value >= entryPrice) {
        return 'Stop Loss should be below entry price ${entryPrice.toStringAsFixed(currentDigits)}';
      }
    }

    return null;
  }

  // Validate Take Profit
  String? _validateTakeProfit() {
    if (!widget.takeProfitEnabled.value) return null;

    // Use limit price for limit orders, current market price for market orders
    final entryPrice =
        widget.whenPriceIsEnabled.value
            ? widget.limitPrice.value
            : (widget.selectedPendingOrderType.value == 0
                ? currentBidPrice
                : currentAskPrice);

    if (entryPrice == null) return null;

    if (widget.selectedPendingOrderType.value == 0) {
      // Sell Limit - Take Profit should be BELOW entry price (profit when price drops)
      if (widget.takeProfitPrice.value >= entryPrice) {
        return 'Take Profit should be below entry price ${entryPrice.toStringAsFixed(currentDigits)}';
      }
    } else {
      // Buy Limit - Take Profit should be ABOVE entry price (profit when price rises)
      if (widget.takeProfitPrice.value <= entryPrice) {
        return 'Take Profit should be above entry price ${entryPrice.toStringAsFixed(currentDigits)}';
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
        return 'Sell Limit price should be above ${currentPrice.toStringAsFixed(currentDigits)}';
      }
    } else {
      // Buy Limit - Limit price should be below current price
      if (widget.limitPrice.value >= currentPrice) {
        return 'Buy Limit price should be below ${currentPrice.toStringAsFixed(currentDigits)}';
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
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                            onTap:
                                () => widget.selectedPendingOrderType.value = 0,
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
                                    currentBidPrice?.toStringAsFixed(
                                          currentDigits,
                                        ) ??
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
                            onTap:
                                () => widget.selectedPendingOrderType.value = 1,
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
                                    currentAskPrice?.toStringAsFixed(
                                          currentDigits,
                                        ) ??
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
                  isManuallyEditingTakeProfit =
                      false; // Reset manual editing flag
                  // Allow both TP and SL to be enabled simultaneously
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
                        ],
                      ),
                      // Recalculate button and profit display
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
                  isManuallyEditingStopLoss =
                      false; // Reset manual editing flag
                  // Allow both TP and SL to be enabled simultaneously
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
                          // Container(
                          //   width: 96.w,
                          //   height: 48.h,
                          //   decoration: BoxDecoration(
                          //     color: Colors.white,
                          //     borderRadius: BorderRadius.circular(8.r),
                          //     border: Border.all(color: AppColors.border),
                          //   ),
                          //   alignment: Alignment.center,
                          //   child: _buildPriceTypeDropdown(),
                          // ),
                        ],
                      ),
                      // Recalculate button and loss display
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

              SizedBox(height: kBottomNavigationBarHeight.h),
            ],
          ),
        ),
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
                    widget.limitPriceController.text =
                        widget.limitPrice.value.toString();
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
                  widget.limitPriceController.text =
                      widget.limitPrice.value.toString();
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
      width: MediaQuery.of(context).size.width * 0.9,
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
                    controller.text = priceNotifier.value.toStringAsFixed(
                      currentDigits,
                    );

                    // Set manual editing flags based on which field is being edited
                    if (label == 'Take Profit') {
                      isManuallyEditingTakeProfit = true;
                    } else if (label == 'Stop Loss') {
                      isManuallyEditingStopLoss = true;
                    }
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

                            // Set manual editing flags based on which field is being edited
                            if (label == 'Take Profit') {
                              isManuallyEditingTakeProfit = true;
                            } else if (label == 'Stop Loss') {
                              isManuallyEditingStopLoss = true;
                            }
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
                  controller.text = priceNotifier.value.toString();

                  // Set manual editing flags based on which field is being edited
                  if (label == 'Take Profit') {
                    isManuallyEditingTakeProfit = true;
                  } else if (label == 'Stop Loss') {
                    isManuallyEditingStopLoss = true;
                  }
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
