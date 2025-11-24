import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/services/language_service.dart';
import '../../constants/color.dart';
import '../../constants/text_styles.dart';
import '../../controllers/chart_socket_controller.dart';
import '../../controllers/account_controller.dart';
import '../../controllers/trading_controller.dart';
import '../../models/order_types.dart';
import '../../utils/trl_helper.dart';
import '../../utils/precision_helper.dart';
import '../../utils/app_logger.dart';
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
  final TradingController tradingController = Get.find<TradingController>();

  // Live price data
  double? currentBidPrice;
  double? currentAskPrice;
  double volume = 0.01;
  int currentDigits = 5; // Default to 5 decimal places

  // Dropdown selection state
  String selectedOrderType = 'Buy Stop'; // Default selection

  // TextEditingController for volume input
  late TextEditingController volumeController;
  late FocusNode volumeFocusNode;

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

  // Android-style price adjustment using pip values
  void _adjustPrice(bool isIncrease) {
    // Set current symbol and update pip values
    tradingController.setCurrentSymbol(widget.selectedSymbol);

    // Get current market prices
    currentBidPrice = chartSocketController.getBidPrice();
    currentAskPrice = chartSocketController.getAskPrice();

    if (currentBidPrice != null && currentAskPrice != null) {
      tradingController.updateMarketPrices(currentBidPrice!, currentAskPrice!);
    }

    // Convert old order type to new OrderType enum
    OrderType orderType;
    if (widget.whenPriceIsEnabled.value) {
      // Conditional orders (Buy Limit/Sell Limit)
      if (widget.selectedPendingOrderType.value == 0) {
        orderType = OrderType.sellLimit; // Sell Limit
      } else {
        orderType = OrderType.buyLimit; // Buy Limit
      }
    } else {
      // Market orders
      if (widget.selectedPendingOrderType.value == 0) {
        orderType = OrderType.sellMarket; // Sell Market
      } else {
        orderType = OrderType.buyMarket; // Buy Market
      }
    }

    // Log price adjustment
    AppLogger.trading(
      'Price adjustment: ${isIncrease ? '+' : '-'} pip for ${orderType.displayName}',
    );

    // Use Android-style price adjustment
    final currentPrice = widget.limitPrice.value.toString();
    final newPrice = tradingController.adjustPriceByPip(
      currentPrice,
      isIncrease,
      orderType,
    );

    // Update the price
    final newPriceValue = double.tryParse(newPrice) ?? widget.limitPrice.value;
    widget.limitPrice.value = newPriceValue;
    widget.limitPriceController.text = newPriceValue.toString();
    // widget.limitPriceController.text = PrecisionHelper.formatPrice(
    //   newPriceValue,
    //   decimals: currentDigits,
    // );

    isManuallyEditingPrice = true;

    // Recalculate SL/TP based on new price
    _recalculateTPSL();
  }

  // Android-style SL adjustment using pip values
  void _adjustSL(bool isIncrease) {
    if (!widget.stopLossEnabled.value) return;

    // Set current symbol and update pip values
    tradingController.setCurrentSymbol(widget.selectedSymbol);

    // Get current market prices
    currentBidPrice = chartSocketController.getBidPrice();
    currentAskPrice = chartSocketController.getAskPrice();

    if (currentBidPrice != null && currentAskPrice != null) {
      tradingController.updateMarketPrices(currentBidPrice!, currentAskPrice!);
    }

    // Convert old order type to new OrderType enum
    OrderType orderType;
    if (widget.whenPriceIsEnabled.value) {
      if (widget.selectedPendingOrderType.value == 0) {
        orderType = OrderType.sellLimit;
      } else {
        orderType = OrderType.buyLimit;
      }
    } else {
      if (widget.selectedPendingOrderType.value == 0) {
        orderType = OrderType.sellMarket;
      } else {
        orderType = OrderType.buyMarket;
      }
    }

    // Use Android-style SL adjustment
    final currentSL = widget.stopLossPrice.value.toString();
    final entryPrice = widget.limitPrice.value.toString();
    final newSL = tradingController.adjustSLTPByPip(
      currentSL,
      isIncrease,
      orderType,
      entryPrice,
    );

    // Update the SL
    final newSLValue = double.tryParse(newSL) ?? widget.stopLossPrice.value;
    widget.stopLossPrice.value = newSLValue;
    widget.stopLossController.text = PrecisionHelper.formatPrice(
      newSLValue,
      decimals: currentDigits,
    );

    isManuallyEditingStopLoss = true;
  }

  // Android-style TP adjustment using pip values
  void _adjustTP(bool isIncrease) {
    if (!widget.takeProfitEnabled.value) return;

    // Set current symbol and update pip values
    tradingController.setCurrentSymbol(widget.selectedSymbol);

    // Get current market prices
    currentBidPrice = chartSocketController.getBidPrice();
    currentAskPrice = chartSocketController.getAskPrice();

    if (currentBidPrice != null && currentAskPrice != null) {
      tradingController.updateMarketPrices(currentBidPrice!, currentAskPrice!);
    }

    // Convert old order type to new OrderType enum
    OrderType orderType;
    if (widget.whenPriceIsEnabled.value) {
      if (widget.selectedPendingOrderType.value == 0) {
        orderType = OrderType.sellLimit;
      } else {
        orderType = OrderType.buyLimit;
      }
    } else {
      if (widget.selectedPendingOrderType.value == 0) {
        orderType = OrderType.sellMarket;
      } else {
        orderType = OrderType.buyMarket;
      }
    }

    // Use Android-style TP adjustment
    final currentTP = widget.takeProfitPrice.value.toString();
    final entryPrice = widget.limitPrice.value.toString();
    final newTP = tradingController.adjustSLTPByPip(
      currentTP,
      isIncrease,
      orderType,
      entryPrice,
    );

    // Update the TP
    final newTPValue = double.tryParse(newTP) ?? widget.takeProfitPrice.value;
    widget.takeProfitPrice.value = newTPValue;
    widget.takeProfitController.text = PrecisionHelper.formatPrice(
      newTPValue,
      decimals: currentDigits,
    );

    isManuallyEditingTakeProfit = true;
  }

  void _recalculateTPSL() {
    if (widget.limitPrice.value > 0) {
      final entryPrice = widget.limitPrice.value;
      final percentageValue = entryPrice * 0.0115; // 1.15% - Android default

      // Convert old order type to new OrderType enum
      OrderType orderType;
      if (widget.whenPriceIsEnabled.value) {
        // Conditional orders (Buy Limit/Sell Limit)
        if (widget.selectedPendingOrderType.value == 0) {
          orderType = OrderType.sellLimit; // Sell Limit
        } else {
          orderType = OrderType.buyLimit; // Buy Limit
        }
      } else {
        // Market orders
        if (widget.selectedPendingOrderType.value == 0) {
          orderType = OrderType.sellMarket; // Sell Market
        } else {
          orderType = OrderType.buyMarket; // Buy Market
        }
      }

      // Only update Take Profit if user hasn't manually edited it
      if (widget.takeProfitEnabled.value && !isManuallyEditingTakeProfit) {
        if (orderType.isBuyOrder) {
          // Buy orders - Take Profit ABOVE entry price
          widget.takeProfitPrice.value = entryPrice + percentageValue;
        } else {
          // Sell orders - Take Profit BELOW entry price
          widget.takeProfitPrice.value = entryPrice - percentageValue;
        }
        widget.takeProfitController.text = PrecisionHelper.formatPrice(
          widget.takeProfitPrice.value,
          decimals: currentDigits,
        );
      }

      // Only update Stop Loss if user hasn't manually edited it
      if (widget.stopLossEnabled.value && !isManuallyEditingStopLoss) {
        if (orderType.isBuyOrder) {
          // Buy orders - Stop Loss BELOW entry price
          widget.stopLossPrice.value = entryPrice - percentageValue;
        } else {
          // Sell orders - Stop Loss ABOVE entry price
          widget.stopLossPrice.value = entryPrice + percentageValue;
        }
        widget.stopLossController.text = PrecisionHelper.formatPrice(
          widget.stopLossPrice.value,
          decimals: currentDigits,
        );
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
    widget.limitPriceController.text = PrecisionHelper.formatPrice(
      widget.limitPrice.value,
      decimals: 5,
    );

    // Initialize volume controller
    volumeController = TextEditingController(
      text: PrecisionHelper.formatVolume(volume),
    );
    volumeFocusNode = FocusNode();

    // Add listener to limit price controller for real-time TP/SL recalculation
    widget.limitPriceController.addListener(() {
      final text = widget.limitPriceController.text;
      if (text.isNotEmpty) {
        final newPrice = PrecisionHelper.parseDouble(text);
        if (newPrice > 0) {
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
        widget.limitPriceController.text = PrecisionHelper.formatPrice(
          widget.limitPrice.value,
          decimals: currentDigits,
        );
      } else {
        // Buy Limit - use ask price
        widget.limitPrice.value = currentAskPrice ?? 3674.16;
        widget.limitPriceController.text = PrecisionHelper.formatPrice(
          widget.limitPrice.value,
          decimals: currentDigits,
        );
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
        widget.takeProfitController.text = PrecisionHelper.formatPrice(
          widget.takeProfitPrice.value,
          decimals: currentDigits,
        );
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
        widget.stopLossController.text = PrecisionHelper.formatPrice(
          widget.stopLossPrice.value,
          decimals: currentDigits,
        );
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
    // print(
    // 'TP Calculation: TP=${widget.takeProfitPrice.value}, Entry=$entryPrice, Diff=$priceDiff, Volume=$currentVolume, Symbol=${widget.selectedSymbol}',
    // );

    // For EURUSD: 1 pip = 0.0001, 1 lot = 100,000 units
    // For XAUUSD: 1 pip = 0.01, 1 lot = 100 ounces
    double result;
    if (widget.selectedSymbol.contains('EUR') ||
        widget.selectedSymbol.contains('USD')) {
      result = priceDiff * currentVolume * 100000; // EURUSD calculation
    } else {
      result = priceDiff * currentVolume * 100; // XAUUSD calculation
    }

    // print('TP Result: $result');
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
    // print(
    // 'SL Calculation: SL=${widget.stopLossPrice.value}, Entry=$entryPrice, Diff=$priceDiff, Volume=$currentVolume, Symbol=${widget.selectedSymbol}',
    // );

    // For EURUSD: 1 pip = 0.0001, 1 lot = 100,000 units
    // For XAUUSD: 1 pip = 0.01, 1 lot = 100 ounces
    double result;
    if (widget.selectedSymbol.contains('EUR') ||
        widget.selectedSymbol.contains('USD')) {
      result = priceDiff * currentVolume * 100000; // EURUSD calculation
    } else {
      result = priceDiff * currentVolume * 100; // XAUUSD calculation
    }

    // print('SL Result: $result');
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
        return 'Stop Loss should be above entry price ${PrecisionHelper.formatPrice(entryPrice, decimals: currentDigits)}';
      }
    } else {
      // Buy Limit - Stop Loss should be BELOW entry price (safety net below)
      if (widget.stopLossPrice.value >= entryPrice) {
        return 'Stop Loss should be below entry price ${PrecisionHelper.formatPrice(entryPrice, decimals: currentDigits)}';
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
        return 'Take Profit should be below entry price ${PrecisionHelper.formatPrice(entryPrice, decimals: currentDigits)}';
      }
    } else {
      // Buy Limit - Take Profit should be ABOVE entry price (profit when price rises)
      if (widget.takeProfitPrice.value <= entryPrice) {
        return 'Take Profit should be above entry price ${PrecisionHelper.formatPrice(entryPrice, decimals: currentDigits)}';
      }
    }

    return null;
  }

  // Validate Limit Price
  // Note: Basic validation only - backend will handle strict validation and return errors
  String? _validateLimitPrice() {
    // Only validate if "When price is" toggle is ON
    if (!widget.whenPriceIsEnabled.value) return null;

    final currentPrice =
        widget.selectedPendingOrderType.value == 0
            ? currentBidPrice
            : currentAskPrice;

    if (currentPrice == null) return null;

    // Round both prices to currentDigits precision for accurate comparison
    final roundedLimitPrice = PrecisionHelper.round(
      widget.limitPrice.value,
      decimals: currentDigits,
    );
    final roundedCurrentPrice = PrecisionHelper.round(
      currentPrice,
      decimals: currentDigits,
    );

    if (widget.selectedPendingOrderType.value == 0) {
      // Sell Limit - Limit price should be above current price
      if (roundedLimitPrice <= roundedCurrentPrice) {
        return 'Sell Limit price should be above ${PrecisionHelper.formatPrice(currentPrice, decimals: currentDigits)}';
      }
    } else {
      // Buy Limit - Limit price should be below current price
      if (roundedLimitPrice >= roundedCurrentPrice) {
        return 'Buy Limit price should be below ${PrecisionHelper.formatPrice(currentPrice, decimals: currentDigits)}';
      }
    }

    return null;
  }

  // Check if order is valid for placement
  // Note: Price validation is shown as warning but doesn't block button - backend will validate
  bool _isOrderValid() {
    // Basic checks: price and volume must be positive
    if (widget.limitPrice.value <= 0) return false;
    if (volume <= 0) return false;

    // For market orders (toggle OFF), only check SL/TP validation if enabled
    if (!widget.whenPriceIsEnabled.value) {
      // Market orders - only validate SL/TP if enabled (but don't block, just warn)
      // Backend will handle validation
      return true;
    }

    // For limit orders (toggle ON), allow placement - backend will validate
    // Price validation message is shown but doesn't block the button
    // Only validate SL/TP if enabled (but don't block, backend will handle)
    return true;
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    widget.selectedPendingOrderType.removeListener(() {});
    volumeController.dispose();
    volumeFocusNode.dispose();
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
                // padding: EdgeInsets.all(10.spMax),
                decoration: BoxDecoration(
                  // color: AppColors.whiteColor,
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
                                vertical: 6.h,
                                horizontal: 12.w,
                              ),
                              height: 55.h,
                              constraints: BoxConstraints(
                                minHeight: 55.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    selectedType == 0
                                        ? AppColors.red
                                        : AppColors.cardBackGround,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Sell Limit',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color:
                                          selectedType == 0
                                              ? AppColors.whiteColor
                                              : AppColors.textGrey,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    currentBidPrice != null
                                        ? PrecisionHelper.formatPrice(
                                          currentBidPrice!,
                                          decimals: currentDigits,
                                        )
                                        : '0',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 11.sp,
                                      fontWeight:
                                          selectedType == 0
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                      color:
                                          selectedType == 0
                                              ? AppColors.whiteColor
                                              : AppColors.textGrey,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                vertical: 6.h,
                                horizontal: 12.w,
                              ),
                              height: 55.h,
                              constraints: BoxConstraints(
                                minHeight: 55.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    selectedType == 1
                                        ? AppColors.green
                                        : AppColors.cardBackGround,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Buy Limit',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color:
                                          selectedType == 1
                                              ? AppColors.whiteColor
                                              : AppColors.textPrimary,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    currentAskPrice != null
                                        ? PrecisionHelper.formatPrice(
                                          currentAskPrice!,
                                          decimals: currentDigits,
                                        )
                                        : '3674.16',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 11.sp,
                                      fontWeight:
                                          selectedType == 1
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                      color:
                                          selectedType == 1
                                              ? AppColors.whiteColor
                                              : AppColors.textGrey,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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

              // Order Type Dropdown
              _buildOrderTypeDropdown(),

              SizedBox(height: 14.h),

              // Quantity Section
              _buildQuantitySection(),

              SizedBox(height: 8.h),

              // Monetary Equivalent
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       'Monetary equivalent',
              //       style: AppTextStyles.label.copyWith(
              //         fontSize: 14.sp,
              //         fontWeight: FontWeight.w400,
              //         color: AppColors.textGrey,
              //       ),
              //     ),
              //     ValueListenableBuilder<double>(
              //       valueListenable: widget.openPrice,
              //       builder: (context, price, child) {
              //         return Text(
              //           '\$${PrecisionHelper.formatPnL(price)}',
              //           style: AppTextStyles.label.copyWith(
              //             fontSize: 14.sp,
              //             fontWeight: FontWeight.w400,
              //           ),
              //         );
              //       },
              //     ),
              //   ],
              // ),

              // SizedBox(height: 16.h),

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
                      // Error message for Limit Price - wrapped in ValueListenableBuilder for real-time updates
                      // ValueListenableBuilder<double>(
                      //   valueListenable: widget.limitPrice,
                      //   builder: (context, price, child) {
                      //     final validationError = _validateLimitPrice();
                      //     if (validationError == null) return SizedBox.shrink();
                      //     return Padding(
                      //       padding: EdgeInsets.symmetric(
                      //         horizontal: 16.w,
                      //         vertical: 4.h,
                      //       ),
                      //       child: Text(
                      //         validationError,
                      //         style: AppTextStyles.label.copyWith(
                      //           fontSize: 12.sp,
                      //           color: AppColors.red,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  );
                },
              ),

              // SizedBox(height: 16.h),

              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       'Distance',
              //       style: AppTextStyles.label.copyWith(
              //         fontSize: 14.sp,
              //         fontWeight: FontWeight.w400,
              //         color: AppColors.textGrey,
              //       ),
              //     ),
              //     ValueListenableBuilder<double>(
              //       valueListenable: widget.distance,
              //       builder: (context, distanceValue, child) {
              //         return Text(
              //           '${PrecisionHelper.formatPrice(distanceValue)} points',
              //           style: AppTextStyles.label.copyWith(
              //             fontSize: 14.sp,
              //             fontWeight: FontWeight.w400,
              //           ),
              //         );
              //       },
              //     ),
              //   ],
              // ),
              // SizedBox(height: 16.h),

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
                      // Padding(
                      //   padding: EdgeInsets.symmetric(horizontal: 16.w),
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //     children: [
                      //       Text(
                      //         'Profit: \$${PrecisionHelper.formatPnL(_calculateTakeProfitValue())}',
                      //         style: AppTextStyles.label.copyWith(
                      //           fontSize: 12.sp,
                      //           color: AppColors.green,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
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
                      // Padding(
                      //   padding: EdgeInsets.symmetric(horizontal: 16.w),
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //     children: [
                      //       Text(
                      //         'Loss: \$${PrecisionHelper.formatPnL(_calculateStopLossValue())}',
                      //         style: AppTextStyles.label.copyWith(
                      //           fontSize: 12.sp,
                      //           color: AppColors.red,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
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

              // Confirm Button - wrapped in ValueListenableBuilder for real-time validation
              // Listen to all values that affect validation: limitPrice, stopLossPrice, takeProfitPrice, and their enabled flags
              ValueListenableBuilder<double>(
                valueListenable: widget.limitPrice,
                builder: (context, price, child) {
                  return ValueListenableBuilder<double>(
                    valueListenable: widget.stopLossPrice,
                    builder: (context, slPrice, child) {
                      return ValueListenableBuilder<double>(
                        valueListenable: widget.takeProfitPrice,
                        builder: (context, tpPrice, child) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: widget.stopLossEnabled,
                            builder: (context, slEnabled, child) {
                              return ValueListenableBuilder<bool>(
                                valueListenable: widget.takeProfitEnabled,
                                builder: (context, tpEnabled, child) {
                                  final isValid = _isOrderValid();
                                  return GestureDetector(
                                    onTap: isValid ? widget.onPlaceOrder : null,
                                    child: Container(
                                      width: double.infinity,
                                      height: 44.h,
                                      decoration: BoxDecoration(
                                        color:
                                            isValid
                                                ? AppColors.primary
                                                : AppColors.primary.withOpacity(
                                                  0.5,
                                                ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: ValueListenableBuilder<int>(
                                        valueListenable:
                                            widget.selectedPendingOrderType,
                                        builder: (context, orderType, child) {
                                          return ValueListenableBuilder<bool>(
                                            valueListenable:
                                                widget.whenPriceIsEnabled,
                                            builder: (
                                              context,
                                              isConditional,
                                              child,
                                            ) {
                                              final isValid = _isOrderValid();
                                              return Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    isValid
                                                        ? 'Place pending order'
                                                        : 'Fix validation errors',
                                                    style: AppTextStyles.button
                                                        .copyWith(
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              isValid
                                                                  ? Colors.white
                                                                  : Colors.white
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                        ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
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
      height: 55.h,
      width: 343.w,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Quantity input row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 0.h),
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
                          volumeController.text = PrecisionHelper.formatVolume(
                            volume,
                          );
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
                // SizedBox(width: 8.w),
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
                      // SizedBox(height: 4.h),
                      SizedBox(
                        height: 26.h,
                        child: TextFormField(
                          controller: volumeController,
                          focusNode: volumeFocusNode,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          textDirection: RTLHelper.textDirection,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            final newVolume = PrecisionHelper.parseDouble(
                              value,
                            );
                            if (newVolume >= 0.0) {
                              setState(() {
                                volume = newVolume;
                                widget.onVolumeChanged(volume);
                              });
                            }
                          },
                          onTap: () {
                            // Ensure keyboard opens in full screen
                            volumeFocusNode.requestFocus();
                          },
                          onFieldSubmitted: (value) {
                            // Dismiss keyboard when user presses enter/done
                            volumeFocusNode.unfocus();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // SizedBox(width: 8.w),
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
                        volumeController.text = volume.toStringAsFixed(2);
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
          // Container(width: double.maxFinite, height: 2, color: AppColors.grey),
          // SizedBox(height: 6.h),

          // Required Margin
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 11.w),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Row(
          //         children: [
          //           Text(
          //             "Required Margin",
          //             style: AppTextStyles.labelOnChartPendingOrder,
          //           ),
          //           SizedBox(width: 4.w),
          //           Icon(Icons.info_outline_rounded, size: 16.h),
          //         ],
          //       ),
          //       Text(
          //         "\$${PrecisionHelper.formatPnL(_calculateRequiredMargin())}",
          //         style: AppTextStyles.labelOnChartPendingOrderBold,
          //       ),
          //     ],
          //   ),
          // ),
          // SizedBox(height: 6.h),

          // Free Margin
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 11.w),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Text(
          //         "Free margin",
          //         style: AppTextStyles.labelOnChartPendingOrder,
          //       ),
          //       Text(
          //         "\$${PrecisionHelper.formatPnL(_getFreeMargin())}",
          //         style: AppTextStyles.labelOnChartPendingOrder,
          //       ),
          //     ],
          //   ),
          // ),
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
                  _adjustPrice(false); // Decrease price by pip
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
                  Text(
                    Get.find<LanguageService>().tr('pending_order_price'),
                    style: AppTextStyles.labelOnTradeQuantity,
                  ),
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
                      final newPrice = PrecisionHelper.parseDouble(value);
                      if (newPrice > 0) {
                        widget.limitPrice.value = newPrice;
                        // Trigger setState to ensure UI rebuilds for real-time validation
                        setState(() {});
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
                  _adjustPrice(true); // Increase price by pip
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
                  if (label == 'Take Profit') {
                    _adjustTP(false); // Decrease TP by pip
                  } else if (label == 'Stop Loss') {
                    _adjustSL(false); // Decrease SL by pip
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
                          final newPrice = PrecisionHelper.parseDouble(value);
                          if (newPrice > 0) {
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
                  if (label == 'Take Profit') {
                    _adjustTP(true); // Increase TP by pip
                  } else if (label == 'Stop Loss') {
                    _adjustSL(true); // Increase SL by pip
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

  Widget _buildOrderTypeDropdown() {
    return GestureDetector(
      onTap: () => _showOrderTypeBottomSheet(),
      child: Container(
        height: 55.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.border),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedOrderType,
              style: AppTextStyles.label.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.icongrey,
              size: 24.h,
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderTypeBottomSheet() {
    final List<String> options = ['Buy Stop', 'Sell Stop'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              top: 24.h,
              left: 24.w,
              right: 24.w,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Select Order Type',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = selectedOrderType == option;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedOrderType = option;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 16.h,
                          horizontal: 16.w,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 16.sp,
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                color: AppColors.primary,
                                size: 20.h,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
    );
  }
}
