import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/color.dart';
import '../../constants/text_styles.dart';
import '../../controllers/chart_socket_controller.dart';
import '../../controllers/account_controller.dart';
import '../../controllers/trading_controller.dart';
import '../../models/order_types.dart';
import '../../utils/precision_helper.dart';
import '../../services/symbol_details_cache_service.dart';
import 'package:get/get.dart';
import 'dart:async';

class PendingOrderContent extends StatefulWidget {
  final ValueNotifier<int> selectedPendingOrderType;
  final ValueNotifier<String> selectedOrderType;
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
  final TextEditingController openPriceController;
  final VoidCallback onPlaceOrder;
  final String selectedSymbol;
  final bool isLoading;
  final Function(double) onVolumeChanged;

  const PendingOrderContent({
    Key? key,
    required this.selectedPendingOrderType,
    required this.selectedOrderType,
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
    required this.openPriceController,
    required this.onPlaceOrder,
    required this.selectedSymbol,
    this.isLoading = false,
    required this.onVolumeChanged,
  }) : super(key: key);

  @override
  State<PendingOrderContent> createState() => _PendingOrderContentState();
}

class _PendingOrderContentState extends State<PendingOrderContent> {
  late ChartSocketController chartSocketController;
  late AccountController accountController;
  final TradingController tradingController = Get.find<TradingController>();

  double? currentBidPrice;
  double? currentAskPrice;
  double volume = 0.01;
  int currentDigits = 5;

  late TextEditingController volumeController;
  late FocusNode volumeFocusNode;

  bool isManuallyEditingPrice = false;
  bool isManuallyEditingTakeProfit = false;
  bool isManuallyEditingStopLoss = false;

  int _pnlCalculationKey = 0;
  Timer? _pnlUpdateTimer;

  final ValueNotifier<int> _tpPnLUpdateNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _slPnLUpdateNotifier = ValueNotifier<int>(0);

  Map<String, dynamic>? _lastTPPnL;
  Map<String, dynamic>? _lastSLPnL;

  int _getCurrentDigits() {
    final priceData = chartSocketController.getCurrentPrice();
    if (priceData != null && priceData.containsKey('digits')) {
      return int.tryParse(priceData['digits'].toString()) ?? 5;
    }
    return 5;
  }

  double get _minLot => 0.01;
  double get _maxLot => accountController.activeMT5Account?.maxLotSize ?? 100.0;
  /// Handles minus button tap: unfocuses keyboard without closing it, then adjusts price
  void _handleMinusTap(BuildContext context, VoidCallback adjustFn) {
    FocusScope.of(context).unfocus();
    adjustFn();
  }

  /// Handles plus button tap: unfocuses keyboard without closing it, then adjusts price
  void _handlePlusTap(BuildContext context, VoidCallback adjustFn) {
    FocusScope.of(context).unfocus();
    adjustFn();
  }



  void _adjustPrice(bool isIncrease) {
    tradingController.setCurrentSymbol(widget.selectedSymbol);

    currentBidPrice = chartSocketController.getBidPrice();
    currentAskPrice = chartSocketController.getAskPrice();

    if (currentBidPrice != null && currentAskPrice != null) {
      tradingController.updateMarketPrices(currentBidPrice!, currentAskPrice!);
    }

    OrderType orderType;
    final selectedOrderTypeStr = widget.selectedOrderType.value;
    switch (selectedOrderTypeStr) {
      case 'Buy Limit':
        orderType = OrderType.buyLimit;
        break;
      case 'Sell Limit':
        orderType = OrderType.sellLimit;
        break;
      case 'Buy Stop':
        orderType = OrderType.buyStop;
        break;
      case 'Sell Stop':
        orderType = OrderType.sellStop;
        break;
      case 'Buy Stop Limit':
        orderType = OrderType.buyStopLimit;
        break;
      case 'Sell Stop Limit':
        orderType = OrderType.sellStopLimit;
        break;
      default:
        orderType = OrderType.buyLimit;
        break;
    }

    final currentPrice = widget.limitPrice.value.toString();
    final newPrice = tradingController.adjustPriceByPip(
      currentPrice,
      isIncrease,
      orderType,
    );

    final newPriceValue = double.tryParse(newPrice) ?? widget.limitPrice.value;
    widget.limitPrice.value = newPriceValue;
    widget.limitPriceController.text = PrecisionHelper.formatPrice(
      newPriceValue,
      decimals: currentDigits,
    );

    isManuallyEditingPrice = true;
    _recalculateTPSL();
  }

  void _adjustSL(bool isIncrease) {
    if (!widget.stopLossEnabled.value) return;

    tradingController.setCurrentSymbol(widget.selectedSymbol);

    currentBidPrice = chartSocketController.getBidPrice();
    currentAskPrice = chartSocketController.getAskPrice();

    if (currentBidPrice != null && currentAskPrice != null) {
      tradingController.updateMarketPrices(currentBidPrice!, currentAskPrice!);
    }

    OrderType orderType;
    final selectedOrderTypeStr = widget.selectedOrderType.value;
    switch (selectedOrderTypeStr) {
      case 'Buy Limit':
        orderType = OrderType.buyLimit;
        break;
      case 'Sell Limit':
        orderType = OrderType.sellLimit;
        break;
      case 'Buy Stop':
        orderType = OrderType.buyStop;
        break;
      case 'Sell Stop':
        orderType = OrderType.sellStop;
        break;
      case 'Buy Stop Limit':
        orderType = OrderType.buyStopLimit;
        break;
      case 'Sell Stop Limit':
        orderType = OrderType.sellStopLimit;
        break;
      default:
        orderType = OrderType.buyLimit;
        break;
    }

    final currentSL = widget.stopLossPrice.value.toString();
    final entryPrice = widget.limitPrice.value.toString();
    final newSL = tradingController.adjustSLTPByPip(
      currentSL,
      isIncrease,
      orderType,
      entryPrice,
    );

    final newSLValue = double.tryParse(newSL) ?? widget.stopLossPrice.value;
    widget.stopLossPrice.value = newSLValue;
    widget.stopLossController.text = PrecisionHelper.formatPrice(
      newSLValue,
      decimals: currentDigits,
    );

    isManuallyEditingStopLoss = true;
  }


  void _adjustOpenPrice(bool isIncrease) {
    tradingController.setCurrentSymbol(widget.selectedSymbol);

    currentBidPrice = chartSocketController.getBidPrice();
    currentAskPrice = chartSocketController.getAskPrice();

    if (currentBidPrice != null && currentAskPrice != null) {
      tradingController.updateMarketPrices(currentBidPrice!, currentAskPrice!);
    }

    OrderType orderType;
    final selectedOrderTypeStr = widget.selectedOrderType.value;
    switch (selectedOrderTypeStr) {
      case 'Buy Stop Limit':
        orderType = OrderType.buyStopLimit;
        break;
      case 'Sell Stop Limit':
        orderType = OrderType.sellStopLimit;
        break;
      default:
        orderType = OrderType.buyStopLimit;
        break;
    }

    final currentPrice = widget.openPrice.value.toString();
    final newPrice = tradingController.adjustPriceByPip(
      currentPrice,
      isIncrease,
      orderType,
    );

    final newPriceValue = double.tryParse(newPrice) ?? widget.openPrice.value;
    widget.openPrice.value = newPriceValue;
    widget.openPriceController.text = PrecisionHelper.formatPrice(
      newPriceValue,
      decimals: currentDigits,
    );

    _recalculateTPSL();
  }
  void _adjustTP(bool isIncrease) {
    if (!widget.takeProfitEnabled.value) return;

    tradingController.setCurrentSymbol(widget.selectedSymbol);

    currentBidPrice = chartSocketController.getBidPrice();
    currentAskPrice = chartSocketController.getAskPrice();

    if (currentBidPrice != null && currentAskPrice != null) {
      tradingController.updateMarketPrices(currentBidPrice!, currentAskPrice!);
    }

    OrderType orderType;
    final selectedOrderTypeStr = widget.selectedOrderType.value;
    switch (selectedOrderTypeStr) {
      case 'Buy Limit':
        orderType = OrderType.buyLimit;
        break;
      case 'Sell Limit':
        orderType = OrderType.sellLimit;
        break;
      case 'Buy Stop':
        orderType = OrderType.buyStop;
        break;
      case 'Sell Stop':
        orderType = OrderType.sellStop;
        break;
      case 'Buy Stop Limit':
        orderType = OrderType.buyStopLimit;
        break;
      case 'Sell Stop Limit':
        orderType = OrderType.sellStopLimit;
        break;
      default:
        orderType = OrderType.buyLimit;
        break;
    }

    final currentTP = widget.takeProfitPrice.value.toString();
    final entryPrice = widget.limitPrice.value.toString();
    final newTP = tradingController.adjustSLTPByPip(
      currentTP,
      isIncrease,
      orderType,
      entryPrice,
    );

    final newTPValue = double.tryParse(newTP) ?? widget.takeProfitPrice.value;
    widget.takeProfitPrice.value = newTPValue;
    widget.takeProfitController.text = PrecisionHelper.formatPrice(
      newTPValue,
      decimals: currentDigits,
    );

    isManuallyEditingTakeProfit = true;
  }

  void _recalculateTPSL() {
    if (widget.limitPrice.value <= 0) return;

    final entryPrice = widget.limitPrice.value;
    final percentageValue = entryPrice * 0.0115;

    OrderType orderType;
    final selectedOrderTypeStr = widget.selectedOrderType.value;
    switch (selectedOrderTypeStr) {
      case 'Buy Limit':
        orderType = OrderType.buyLimit;
        break;
      case 'Sell Limit':
        orderType = OrderType.sellLimit;
        break;
      case 'Buy Stop':
        orderType = OrderType.buyStop;
        break;
      case 'Sell Stop':
        orderType = OrderType.sellStop;
        break;
      case 'Buy Stop Limit':
        orderType = OrderType.buyStopLimit;
        break;
      case 'Sell Stop Limit':
        orderType = OrderType.sellStopLimit;
        break;
      default:
        orderType = OrderType.buyLimit;
        break;
    }

    if (widget.takeProfitEnabled.value && !isManuallyEditingTakeProfit) {
      widget.takeProfitPrice.value = orderType.isBuyOrder
          ? entryPrice + percentageValue
          : entryPrice - percentageValue;
      widget.takeProfitController.text = PrecisionHelper.formatPrice(
        widget.takeProfitPrice.value,
        decimals: currentDigits,
      );
    }

    if (widget.stopLossEnabled.value && !isManuallyEditingStopLoss) {
      widget.stopLossPrice.value = orderType.isBuyOrder
          ? entryPrice - percentageValue
          : entryPrice + percentageValue;
      widget.stopLossController.text = PrecisionHelper.formatPrice(
        widget.stopLossPrice.value,
        decimals: currentDigits,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.whenPriceIsEnabled.value = true;
    });

    chartSocketController = Get.find<ChartSocketController>();
    accountController = Get.find<AccountController>();

    currentDigits = _getCurrentDigits();
    widget.limitPriceController.text = PrecisionHelper.formatPrice(
      widget.limitPrice.value,
      decimals: currentDigits,
    );
    widget.openPriceController.text = PrecisionHelper.formatPrice(
      widget.openPrice.value,
      decimals: currentDigits,
    );

    volumeController = TextEditingController(
      text: PrecisionHelper.formatVolume(volume),
    );
    volumeFocusNode = FocusNode();

    widget.limitPriceController.addListener(() {
      final text = widget.limitPriceController.text;
      if (text.isNotEmpty) {
        final newPrice = PrecisionHelper.parseDouble(text);
        if (newPrice > 0) {
          widget.limitPrice.value = newPrice;
          _recalculateTPSL();
        }
      }
    });

    widget.openPriceController.addListener(() {
      final text = widget.openPriceController.text;
      if (text.isNotEmpty) {
        final newPrice = PrecisionHelper.parseDouble(text);
        if (newPrice > 0) {
          widget.openPrice.value = newPrice;
          _recalculateTPSL();
        }
      }
    });

    _updatePrices();

    chartSocketController.priceStream.listen((priceData) {
      if (mounted) {
        setState(() => _updatePrices());
      }
    });

    widget.selectedPendingOrderType.addListener(() {
      if (mounted) {
        setState(() {
          isManuallyEditingPrice = false;
          isManuallyEditingTakeProfit = false;
          isManuallyEditingStopLoss = false;
          _updatePrices();
        });
      }
    });
  }

  void _updatePrices() {
    currentBidPrice = chartSocketController.getBidPrice();
    currentAskPrice = chartSocketController.getAskPrice();
    currentDigits = _getCurrentDigits();

    if (!isManuallyEditingPrice) {
      final orderType = widget.selectedOrderType.value;
      if (orderType.contains('Sell')) {
        widget.limitPrice.value = currentBidPrice ?? 3673.90;
        widget.limitPriceController.text = PrecisionHelper.formatPrice(
          widget.limitPrice.value,
          decimals: currentDigits,
        );
      } else {
        widget.limitPrice.value = currentAskPrice ?? 3674.16;
        widget.limitPriceController.text = PrecisionHelper.formatPrice(
          widget.limitPrice.value,
          decimals: currentDigits,
        );
      }
    }

    final entryPrice = widget.limitPrice.value;
    final orderType = widget.selectedOrderType.value;

    if (entryPrice <= 0) return;

    final percentageValue = entryPrice * 0.0115;

    if (widget.takeProfitEnabled.value && !isManuallyEditingTakeProfit) {
      widget.takeProfitPrice.value = orderType.contains('Sell')
          ? entryPrice - percentageValue
          : entryPrice + percentageValue;
      widget.takeProfitController.text = PrecisionHelper.formatPrice(
        widget.takeProfitPrice.value,
        decimals: currentDigits,
      );
    }

    if (widget.stopLossEnabled.value && !isManuallyEditingStopLoss) {
      widget.stopLossPrice.value = orderType.contains('Sell')
          ? entryPrice + percentageValue
          : entryPrice - percentageValue;
      widget.stopLossController.text = PrecisionHelper.formatPrice(
        widget.stopLossPrice.value,
        decimals: currentDigits,
      );
    }
  }

  Future<Map<String, dynamic>?> _getSymbolDetails(String symbol) async {
    try {
      final activeAccount = accountController.activeMT5Account;
      final accountNumber = activeAccount?.metaAccountNumber ?? '0';
      return await SymbolDetailsCacheService.getSymbolDetails(symbol, accountNumber);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _calculateTakeProfitPnL() async {
    if (!widget.takeProfitEnabled.value || widget.takeProfitController.text.isEmpty) return null;
    final tpPrice = PrecisionHelper.parseDouble(widget.takeProfitController.text);
    if (tpPrice <= 0) return null;
    final entryPrice = widget.limitPrice.value;
    if (entryPrice <= 0) return null;
    final symbolDetails = await _getSymbolDetails(widget.selectedSymbol);
    if (symbolDetails == null) return null;
    final contractSize = (symbolDetails['contract_size'] as num?)?.toDouble();
    if (contractSize == null || contractSize <= 0) return null;
    final isBuy = widget.selectedOrderType.value.contains('Buy');
    final priceDiff = isBuy ? tpPrice - entryPrice : entryPrice - tpPrice;
    final pnl = priceDiff * volume * contractSize;
    final digits = (symbolDetails['digits'] as num?)?.toInt() ?? 2;
    return {'pnl': pnl, 'digits': digits};
  }

  Future<Map<String, dynamic>?> _calculateStopLossPnL() async {
    if (!widget.stopLossEnabled.value || widget.stopLossController.text.isEmpty) return null;
    final slPrice = PrecisionHelper.parseDouble(widget.stopLossController.text);
    if (slPrice <= 0) return null;
    final entryPrice = widget.limitPrice.value;
    if (entryPrice <= 0) return null;
    final symbolDetails = await _getSymbolDetails(widget.selectedSymbol);
    if (symbolDetails == null) return null;
    final contractSize = (symbolDetails['contract_size'] as num?)?.toDouble();
    if (contractSize == null || contractSize <= 0) return null;
    final isBuy = widget.selectedOrderType.value.contains('Buy');
    final priceDiff = isBuy ? entryPrice - slPrice : slPrice - entryPrice;
    final pnl = priceDiff * volume * contractSize;
    final digits = (symbolDetails['digits'] as num?)?.toInt() ?? 2;
    return {'pnl': pnl, 'digits': digits};
  }

  bool _isOrderValid() {
    if (widget.limitPrice.value <= 0) return false;
    final orderTypeStr = widget.selectedOrderType.value;
    if (orderTypeStr.contains('Stop Limit') && widget.openPrice.value <= 0) return false;
    if (volume <= 0) return false;
    return true;
  }

  String? _validateTriggerPrice() {
    if (!widget.selectedOrderType.value.contains('Stop Limit')) return null;
    if (widget.openPrice.value <= 0) return null;
    final currentAsk = currentAskPrice ?? 0;
    final currentBid = currentBidPrice ?? 0;
    if (currentAsk <= 0 && currentBid <= 0) return null;
    final orderType = widget.selectedOrderType.value;
    if (orderType == 'Buy Stop Limit') {
      if (widget.openPrice.value <= currentAsk) {
        return 'Trigger price should be above ${PrecisionHelper.formatPrice(currentAsk, decimals: currentDigits)}';
      }
    } else if (orderType == 'Sell Stop Limit') {
      if (widget.openPrice.value >= currentBid) {
        return 'Trigger price should be below ${PrecisionHelper.formatPrice(currentBid, decimals: currentDigits)}';
      }
    }
    return null;
  }

  String? _validateLimitPrice() {
    if (widget.limitPrice.value <= 0) return null;
    final currentAsk = currentAskPrice ?? 0;
    final currentBid = currentBidPrice ?? 0;
    if (currentAsk <= 0 && currentBid <= 0) return null;
    final orderType = widget.selectedOrderType.value;
    if (orderType == 'Sell Limit' || orderType == 'Buy Stop') {
      if (widget.limitPrice.value <= currentAsk) {
        return 'Price should be above ${PrecisionHelper.formatPrice(currentAsk, decimals: currentDigits)}';
      }
    } else if (orderType == 'Buy Limit' || orderType == 'Sell Stop') {
      if (widget.limitPrice.value >= currentBid) {
        return 'Price should be below ${PrecisionHelper.formatPrice(currentBid, decimals: currentDigits)}';
      }
    } else if (orderType == 'Buy Stop Limit' || orderType == 'Sell Stop Limit') {
      final triggerPrice = widget.openPrice.value;
      if (triggerPrice > 0) {
        if (orderType == 'Buy Stop Limit') {
          if (widget.limitPrice.value <= triggerPrice) {
            return 'Limit price should be above trigger price';
          }
        } else {
          if (widget.limitPrice.value >= triggerPrice) {
            return 'Limit price should be below trigger price';
          }
        }
      }
    }
    return null;
  }


  @override
  void dispose() {
    _pnlUpdateTimer?.cancel();
    _tpPnLUpdateNotifier.dispose();
    _slPnLUpdateNotifier.dispose();
    widget.selectedPendingOrderType.removeListener(() {});
    volumeController.dispose();
    volumeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Type Dropdown
              _buildOrderTypeDropdown(),
              SizedBox(height: 14.h),
              // Enter Price & Volume
              _buildPriceAndVolumeSection(),
              SizedBox(height: 12.h),
              // Quick Volume Selectors
              _buildQuickVolumeSelectors(),
              SizedBox(height: 16.h),
              // TP / SL Section
              _buildStopLossTakeProfitWithSwitches(),
              SizedBox(height: 16.h),
              // Place Order Buttons
              _buildPlaceOrderButtons(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeDropdown() {
    return GestureDetector(
      onTap: () => _showOrderTypeBottomSheet(),
      child: Container(
        height: 46.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.border),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder<String>(
              valueListenable: widget.selectedOrderType,
              builder: (context, orderType, _) {
                return Text(
                  orderType,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                );
              },
            ),
            Icon(Icons.keyboard_arrow_down, color: AppColors.icongrey, size: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceAndVolumeSection() {
    return ValueListenableBuilder<String>(
      valueListenable: widget.selectedOrderType,
      builder: (context, orderTypeStr, _) {
        final isStopLimit = orderTypeStr.contains('Stop Limit');
        return Column(
          children: [
            // Trigger Price row (only for Stop Limit)
            if (isStopLimit) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trigger Price',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  _buildPriceInputField(
                    controller: widget.openPriceController,
                    onDecrease: () => _adjustOpenPrice(false),
                    onIncrease: () => _adjustOpenPrice(true),
                    onChanged: (value) {
                      final newPrice = PrecisionHelper.parseDouble(value);
                      if (newPrice > 0) {
                        widget.openPrice.value = newPrice;
                        setState(() {});
                      }
                    },
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ],
            // Limit Price + Volume row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStopLimit ? 'Limit Price' : 'Enter Price',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      _buildPriceInputField(
                        controller: widget.limitPriceController,
                        onDecrease: () => _adjustPrice(false),
                        onIncrease: () => _adjustPrice(true),
                        onChanged: (value) {
                          isManuallyEditingPrice = true;
                          final newPrice = PrecisionHelper.parseDouble(value);
                          if (newPrice > 0) {
                            widget.limitPrice.value = newPrice;
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volume (Lots)',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      _buildVolumeInputField(),
                    ],
                  ),
                ),
              ],
            ),
            // Validation messages
            if (_validateTriggerPrice() != null || _validateLimitPrice() != null) ...[
              SizedBox(height: 8.h),
              _buildValidationMessages(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildValidationMessages() {
    final triggerMsg = _validateTriggerPrice();
    final limitMsg = _validateLimitPrice();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (triggerMsg != null)
          _buildValidationRow(Icons.warning_amber_outlined, triggerMsg, AppColors.warning),
        if (limitMsg != null)
          _buildValidationRow(Icons.warning_amber_outlined, limitMsg, AppColors.warning),
      ],
    );
  }

  Widget _buildValidationRow(IconData icon, String message, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 14.h, color: color),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.label.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInputField({
    required TextEditingController controller,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration:  BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: IconButton(
              onPressed: () => _handleMinusTap(context, onDecrease),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.remove, size: 14.h, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: IconButton(
              onPressed: () => _handlePlusTap(context, onIncrease),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.add, size: 14.h, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeInputField() {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration:  BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: IconButton(
              onPressed: () => _handleMinusTap(context, () {
                final next = double.parse((volume - 0.01).toStringAsFixed(2));
                volume = next < _minLot ? _minLot : next;
                volumeController.text = PrecisionHelper.formatVolume(volume);
                widget.onVolumeChanged(volume);
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.remove, size: 14.h, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: TextField(
              controller: volumeController,
              focusNode: volumeFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (value) {
                if (value.isEmpty) return;
                final newVolume = PrecisionHelper.parseDouble(value);
                if (newVolume > 0) {
                  setState(() {
                    volume = newVolume;
                    widget.onVolumeChanged(volume);
                  });
                }
              },
              onEditingComplete: () {
                final parsed = double.tryParse(volumeController.text);
                final clamped = (parsed == null || parsed <= 0)
                    ? _minLot
                    : parsed.clamp(_minLot, _maxLot);
                setState(() {
                  volume = double.parse(clamped.toStringAsFixed(2));
                  widget.onVolumeChanged(volume);
                });
                volumeController.text = volume.toStringAsFixed(2);
                volumeFocusNode.unfocus();
              },
            ),
          ),
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: IconButton(
              onPressed: () => _handlePlusTap(context, () {
                final next = double.parse((volume + 0.01).toStringAsFixed(2));
                volume = next > _maxLot ? _maxLot : next;
                volumeController.text = volume.toStringAsFixed(2);
                widget.onVolumeChanged(volume);
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.add, size: 14.h, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickVolumeSelectors() {
    const quickVolumes = [0.01, 0.05, 0.10, 0.50, 1.00];
    return Row(
      children: quickVolumes.map((v) {
        final isSelected = volume == v;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                volume = v;
                volumeController.text = PrecisionHelper.formatVolume(volume);
                widget.onVolumeChanged(volume);
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: v != 1.00 ? 6.w : 0),
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.whiteColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  v.toString(),
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.onColoredBackground : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStopLossTakeProfitWithSwitches() {
    return Column(
      children: [
        // Header row for TP and SL
        Row(
          children: [
            Expanded(child: _buildTPHeader()),
            SizedBox(width: 10.w),
            Expanded(child: _buildSLHeader()),
          ],
        ),
        SizedBox(height: 10.h),
        // Content row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.takeProfitEnabled,
                builder: (context, tpEnabled, _) => tpEnabled ? _buildTPPanel(tpEnabled) : const SizedBox.shrink(),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.stopLossEnabled,
                builder: (context, slEnabled, _) => slEnabled ? _buildSLPanel(slEnabled) : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTPHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.track_changes, size: 16.h, color: AppColors.textGrey),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              'Take Profit',
              style: AppTextStyles.label.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: widget.takeProfitEnabled,
            builder: (context, enabled, _) => _buildToggle(
              enabled: enabled,
              activeColor: AppColors.success,
              onToggle: () {
                final newValue = !enabled;
                widget.takeProfitEnabled.value = newValue;
                if (newValue) {
                  isManuallyEditingTakeProfit = false;
                  _recalculateTPSL();
                } else {
                  widget.takeProfitController.clear();
                  widget.takeProfitPrice.value = 0.0;
                }
                if (mounted) setState(() => _pnlCalculationKey++);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSLHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 16.h, color: AppColors.textGrey),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              'Stop Loss',
              style: AppTextStyles.label.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: widget.stopLossEnabled,
            builder: (context, enabled, _) => _buildToggle(
              enabled: enabled,
              activeColor: AppColors.error,
              onToggle: () {
                final newValue = !enabled;
                widget.stopLossEnabled.value = newValue;
                if (newValue) {
                  isManuallyEditingStopLoss = false;
                  _recalculateTPSL();
                } else {
                  widget.stopLossController.clear();
                  widget.stopLossPrice.value = 0.0;
                }
                if (mounted) setState(() => _pnlCalculationKey++);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required bool enabled,
    required Color activeColor,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 40.w,
        height: 22.h,
        decoration: BoxDecoration(
          color: enabled ? activeColor : AppColors.switchTrackOff,
          borderRadius: BorderRadius.circular(11.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18.w,
            height: 18.h,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration:  BoxDecoration(
              color: AppColors.whiteColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTPPanel(bool enabled) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildPnLPriceRow(
            controller: widget.takeProfitController,
            onDecrease: () => _adjustTP(false),
            onIncrease: () => _adjustTP(true),
            onChanged: (value) {
              isManuallyEditingTakeProfit = true;
              final price = double.tryParse(value) ?? 0.0;
              if (price > 0) widget.takeProfitPrice.value = price;
              _pnlUpdateTimer?.cancel();
              _pnlUpdateTimer = Timer(const Duration(milliseconds: 100), () {
                if (mounted) _tpPnLUpdateNotifier.value++;
              });
            },
            enabled: enabled,
          ),
          if (enabled) ...[
            SizedBox(height: 8.h),
            ValueListenableBuilder<int>(
              valueListenable: _tpPnLUpdateNotifier,
              builder: (context, _, __) {
                return FutureBuilder<Map<String, dynamic>?>(
                  key: ValueKey('tp_pnl_$_pnlCalculationKey'),
                  future: _calculateTakeProfitPnL(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildPnLInfoRow(_lastTPPnL, isProfit: true);
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      _lastTPPnL = snapshot.data;
                    }
                    return _buildPnLInfoRow(snapshot.data ?? _lastTPPnL, isProfit: true);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSLPanel(bool enabled) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildPnLPriceRow(
            controller: widget.stopLossController,
            onDecrease: () => _adjustSL(false),
            onIncrease: () => _adjustSL(true),
            onChanged: (value) {
              isManuallyEditingStopLoss = true;
              final price = double.tryParse(value) ?? 0.0;
              if (price > 0) widget.stopLossPrice.value = price;
              _pnlUpdateTimer?.cancel();
              _pnlUpdateTimer = Timer(const Duration(milliseconds: 100), () {
                if (mounted) _slPnLUpdateNotifier.value++;
              });
            },
            enabled: enabled,
          ),
          if (enabled) ...[
            SizedBox(height: 8.h),
            ValueListenableBuilder<int>(
              valueListenable: _slPnLUpdateNotifier,
              builder: (context, _, __) {
                return FutureBuilder<Map<String, dynamic>?>(
                  key: ValueKey('sl_pnl_$_pnlCalculationKey'),
                  future: _calculateStopLossPnL(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildPnLInfoRow(_lastSLPnL, isProfit: false);
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      _lastSLPnL = snapshot.data;
                    }
                    return _buildPnLInfoRow(snapshot.data ?? _lastSLPnL, isProfit: false);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPnLPriceRow({
    required TextEditingController controller,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
    required Function(String) onChanged,
    required bool enabled,
  }) {
    return Row(
      children: [
        Container(
          width: 28.w,
          height: 28.h,
          decoration:  BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
          ),
          child: IconButton(
            onPressed: enabled ? () => _handleMinusTap(context, onDecrease) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.remove, size: 12.h, color: AppColors.textGrey),
          ),
        ),
        Expanded(
          child: Container(
            height: 36.h,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
        ),
        Container(
          width: 28.w,
          height: 28.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: IconButton(
            onPressed: enabled ? () => _handlePlusTap(context, onIncrease) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.add, size: 12.h, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPnLInfoRow(Map<String, dynamic>? pnlData, {required bool isProfit}) {
    double pips = 0;
    final pnl = pnlData?['pnl'] as num?;

    if (pnlData != null && pnl != null && pnl.toDouble() != 0) {
      final entryPrice = widget.limitPrice.value;
      final targetPrice = isProfit
          ? PrecisionHelper.parseDouble(widget.takeProfitController.text)
          : PrecisionHelper.parseDouble(widget.stopLossController.text);
      if (entryPrice > 0 && targetPrice > 0) {
        pips = (targetPrice - entryPrice).abs() * 10000;
      }
    }

    return Column(
      children: [
        Text(
          'Pips ${pips > 0 ? (isProfit ? '+' : '') : ''}${pips.toStringAsFixed(1)}',
          style: AppTextStyles.label.copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          pnl != null
              ? 'Est. ${isProfit ? 'Profit' : 'Loss'} ${isProfit ? '+' : '-'}\$${_formatPnL(pnl.toDouble())}'
              : 'Est. ${isProfit ? 'Profit' : 'Loss'} --',
          style: AppTextStyles.label.copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: isProfit ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }

  String _formatPnL(double value) {
    if (value.abs() >= 1) return value.toStringAsFixed(2);
    if (value.abs() >= 0.01) return value.toStringAsFixed(4);
    return value.toStringAsFixed(6);
  }

  Widget _buildPlaceOrderButtons() {
    final isBuy = widget.selectedOrderType.value.contains('Buy');
    final isSell = widget.selectedOrderType.value.contains('Sell');
    final isValid = _isOrderValid();
    final lots = '${volume.toStringAsFixed(2)} Lots';

    return Column(
      children: [
        if (isSell || !isBuy)
          _buildOrderButton(
            label: 'Place Sell ${_getShortOrderType()}',
            lots: lots,
            isBuy: false,
            isEnabled: isValid && !widget.isLoading,
          ),
        if (isSell || !isBuy) SizedBox(height: 10.h),
        if (isBuy || !isSell)
          _buildOrderButton(
            label: 'Place Buy ${_getShortOrderType()}',
            lots: lots,
            isBuy: true,
            isEnabled: isValid && !widget.isLoading,
          ),
      ],
    );
  }

  String _getShortOrderType() {
    final orderType = widget.selectedOrderType.value;
    if (orderType.contains('Limit')) return 'Limit';
    if (orderType.contains('Stop Limit')) return 'Stop Limit';
    if (orderType.contains('Stop')) return 'Stop';
    return '';
  }

  Widget _buildOrderButton({
    required String label,
    required String lots,
    required bool isBuy,
    required bool isEnabled,
  }) {
    final btnColor = isBuy ? AppColors.success : AppColors.error;
    return GestureDetector(
      onTap: isEnabled ? widget.onPlaceOrder : null,
      child: Container(
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          color: isEnabled ? btnColor : AppColors.switchTrackOff,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: btnColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: widget.isLoading
            ? Center(
                child: SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.whiteColor),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBuy ? Icons.trending_up : Icons.trending_down,
                    color: AppColors.whiteColor,
                    size: 20.h,
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.whiteColor,
                        ),
                      ),
                      Text(
                        lots,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.whiteColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  void _showOrderTypeBottomSheet() {
    final List<Map<String, dynamic>> options = [
      {
        'type': 'Buy Limit',
        'color': AppColors.success,
        'description': 'Buy at a lower price',
        'icon': Icons.add_chart_outlined,
      },
      {
        'type': 'Sell Limit',
        'color': AppColors.error,
        'description': 'Sell at a higher price',
        'icon': Icons.remove_circle_outline,
      },
      {
        'type': 'Buy Stop',
        'color': AppColors.success,
        'description': 'Buy at a higher price',
        'icon': Icons.trending_up,
      },
      {
        'type': 'Sell Stop',
        'color': AppColors.error,
        'description': 'Sell at a lower price',
        'icon': Icons.trending_down,
      },
      {
        'type': 'Buy Stop Limit',
        'color': AppColors.success,
        'description': 'Buy stop limit order',
        'icon': Icons.show_chart,
      },
      {
        'type': 'Sell Stop Limit',
        'color': AppColors.error,
        'description': 'Sell stop limit order',
        'icon': Icons.area_chart,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Select Order Type',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                ...options.map((option) {
                  final isSelected = widget.selectedOrderType.value == option['type'];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            widget.selectedOrderType.value = option['type'];
                            if ((option['type'] as String).contains('Buy')) {
                              widget.selectedPendingOrderType.value = 1;
                            } else {
                              widget.selectedPendingOrderType.value = 0;
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (option['color'] as Color).withValues(alpha: 0.08)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isSelected ? option['color'] as Color : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40.w,
                                  height: 40.h,
                                  decoration: BoxDecoration(
                                    color: (option['color'] as Color).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    option['icon'] as IconData,
                                    color: option['color'] as Color,
                                    size: 22.h,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['type'] as String,
                                        style: AppTextStyles.label.copyWith(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? option['color'] as Color
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        option['description'] as String,
                                        style: AppTextStyles.label.copyWith(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle, color: option['color'] as Color, size: 22.h),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  );
                }).toList(),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

