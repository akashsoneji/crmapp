import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/controllers/chart_socket_controller.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/constants/api_const.dart';
import 'dart:async';

class ClosePositionScreen extends StatefulWidget {
  final TradePosition position;

  const ClosePositionScreen({super.key, required this.position});

  @override
  State<ClosePositionScreen> createState() => _ClosePositionScreenState();
}

class _ClosePositionScreenState extends State<ClosePositionScreen> {
  // Controllers
  late final ChartSocketController chartSocketController;
  late final AccountController accountController;
  late final TradingController tradingController;

  // Position controls
  double closeVolume = 0.01;
  double? stopLossPrice;
  double? takeProfitPrice;

  // UI states
  bool isProcessing = false;
  bool stopLossEnabled = false;
  bool takeProfitEnabled = false;

  // Controllers for text fields
  late TextEditingController stopLossController;
  late TextEditingController takeProfitController;

  // Stream subscription for cleanup
  StreamSubscription<Map<String, dynamic>>? _priceStreamSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _initializeControllers();

    // Initialize position data
    closeVolume = widget.position.volume;

    // Initialize text controllers
    stopLossController = TextEditingController();
    takeProfitController = TextEditingController();

    // Listen to price updates
    _listenToPriceUpdates();

    // Change symbol to position's symbol
    _changeSymbolToPosition();
  }

  void _initializeControllers() {
    // Always use the existing ChartSocketController
    chartSocketController = Get.find<ChartSocketController>();

    // Always use the existing AccountController
    accountController = Get.find<AccountController>();

    // Always use the existing TradingController
    tradingController = Get.find<TradingController>();
  }

  void _listenToPriceUpdates() {
    print('ClosePositionScreen: Setting up price listener (new method)');
    _priceStreamSubscription = chartSocketController.priceStream.listen((
      priceData,
    ) {
      print('ClosePositionScreen: Received price data: $priceData');
      if (mounted) {
        setState(() {
          // Update TP/SL fields with current prices if enabled
          _updatePriceFieldsWithCurrentPrices();
        });
      }
    });
  }

  void _updatePriceFieldsWithCurrentPrices() {
    // Update text fields with current real-time prices if they're enabled
    final currentPrice = _getCurrentPrice();

    if (takeProfitEnabled && takeProfitController.text.isEmpty) {
      takeProfitController.text = currentPrice.toString();
      takeProfitPrice = currentPrice;
    }

    if (stopLossEnabled && stopLossController.text.isEmpty) {
      stopLossController.text = currentPrice.toString();
      stopLossPrice = currentPrice;
    }
  }

  void _changeSymbolToPosition() {
    // Change symbol to position's symbol using controller method
    chartSocketController.changeSymbol(widget.position.symbol);
  }

  double _getCurrentPrice() {
    // Use controller's getCurrentPrice method like chart screen
    final priceData = chartSocketController.getCurrentPrice();

    if (priceData != null) {
      final bid = chartSocketController.getBidPrice() ?? 0.0;
      final ask = chartSocketController.getAskPrice() ?? 0.0;

      // Return the appropriate price based on position action
      if (widget.position.action.toLowerCase() == 'buy') {
        return bid; // For buy positions, close at bid
      } else {
        return ask; // For sell positions, close at ask
      }
    }

    // Fallback to current price from position
    return double.tryParse(widget.position.currentPrice) ?? 0.0;
  }

  double _calculateProfitLoss() {
    final entryPrice = double.tryParse(widget.position.entryPrice) ?? 0.0;
    final currentPrice = _getCurrentPrice();
    final profitPerLot =
        widget.position.action.toLowerCase() == 'buy'
            ? currentPrice - entryPrice
            : entryPrice - currentPrice;

    final totalProfitLoss = profitPerLot * closeVolume;

    print('ClosePositionScreen: Profit/Loss Calculation:');
    print('  Entry Price: $entryPrice');
    print('  Current Price: $currentPrice');
    print('  Position Action: ${widget.position.action}');
    print('  Close Volume: $closeVolume');
    print('  Profit Per Lot: $profitPerLot');
    print('  Total Profit/Loss: $totalProfitLoss');

    return totalProfitLoss;
  }

  void _updateCloseVolume(double delta) {
    setState(() {
      final newVolume = (closeVolume + delta).clamp(
        0.01,
        widget.position.volume,
      );
      closeVolume = newVolume;
    });
  }

  Future<void> _closePosition() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final activeAccount = accountController.activeMT5Account;
      if (activeAccount == null) {
        CustomToastService.showError(
          title: 'Error',
          message: 'No active account found',
        );
        return;
      }

      // Prepare API payload
      final positionId = int.tryParse(widget.position.orderId) ?? 0;
      final payload = {
        'mt5_account': activeAccount.metaAccountNumber,
        'position_id': positionId,
        'volume': closeVolume,
      };

      // Add stop loss and take profit if enabled
      if (stopLossEnabled && stopLossPrice != null) {
        payload['stop_loss'] = stopLossPrice!;
      }
      if (takeProfitEnabled && takeProfitPrice != null) {
        payload['take_profit'] = takeProfitPrice!;
      }

      // Call API
      final response = await ApiService.post(
        endpoint: ApiConstants.closePositionByPositionId,
        data: payload,
      );

      if (response.success) {
        CustomToastService.showSuccess(
          title: 'Success',
          message: 'Position closed successfully',
        );
        Get.back();
      } else {
        throw Exception(response.message ?? 'Failed to close position');
      }
    } catch (e) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Failed to close position: $e',
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _priceStreamSubscription?.cancel();
    stopLossController.dispose();
    takeProfitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profitLoss = _calculateProfitLoss();
    final isPositive = profitLoss >= 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
        ),
        title: Text(
          'Close position #${widget.position.orderId}',
          style: AppTextStyles.heading.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Position Summary
              _buildPositionSummary(),
              SizedBox(height: 24.h),

              // Current Prices
              _buildCurrentPrices(),
              SizedBox(height: 24.h),

              // Volume Adjustment
              _buildVolumeAdjustment(),
              SizedBox(height: 24.h),

              // Stop Loss and Take Profit
              _buildStopLossTakeProfit(),
              SizedBox(height: 24.h),

              // Fill Policy
              _buildFillPolicy(),
              SizedBox(height: 24.h),

              // Warning Message
              _buildWarningMessage(),
              SizedBox(height: 24.h),
              Text(
                'Profit/Loss: \$${profitLoss.toStringAsFixed(2)}',
                style: AppTextStyles.label.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),

              // Close Button
              _buildCloseButton(profitLoss, isPositive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositionSummary() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Flag
              Container(
                width: 30.w,
                child:
                    widget.position.flag.startsWith('http')
                        ? Text('💱', style: TextStyle(fontSize: 24.sp))
                        : Text(
                          widget.position.flag,
                          style: TextStyle(fontSize: 24.sp),
                        ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.position.symbol,
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 16.sp,
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
                        SizedBox(width: 4.w),
                        Text(
                          '${widget.position.action} ${widget.position.volume} at ${widget.position.entryPrice}',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 14.sp,
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
        ],
      ),
    );
  }

  Widget _buildCurrentPrices() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bid Price
          Column(
            children: [
              Text(
                'Bid',
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                (chartSocketController.getBidPrice() ?? 0.0).toString(),
                style: AppTextStyles.heading.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          Container(width: 1.w, height: 40.h, color: AppColors.border),
          // Ask Price
          Column(
            children: [
              Text(
                'Ask',
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                (chartSocketController.getAskPrice() ?? 0.0).toString(),
                style: AppTextStyles.heading.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeAdjustment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity to close',
          style: AppTextStyles.label.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildVolumeButton('-0.5', -0.5),
            _buildVolumeButton('-0.1', -0.1),
            _buildVolumeButton('-0.01', -0.01),
            _buildVolumeButton('0.01', 0.01, isSelected: true),
            _buildVolumeButton('+0.01', 0.01),
            _buildVolumeButton('+0.1', 0.1),
            _buildVolumeButton('+0.5', 0.5),
          ],
        ),
        SizedBox(height: 12.h),
        Center(
          child: Text(
            'Selected: ${closeVolume.toString()} lots',
            style: AppTextStyles.label.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeButton(
    String label,
    double delta, {
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () => _updateCloseVolume(delta),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStopLossTakeProfit() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Take Profit
          _buildSwitchTile(
            'Take Profit',
            takeProfitEnabled,
            onChanged: (value) {
              setState(() {
                takeProfitEnabled = value;
                if (value) {
                  stopLossEnabled = false;
                  // Initialize with current real-time price
                  takeProfitPrice = _getCurrentPrice();
                  takeProfitController.text = takeProfitPrice.toString();
                } else {
                  takeProfitPrice = null;
                  takeProfitController.clear();
                }
              });
            },
          ),
          if (takeProfitEnabled)
            _buildPriceInput(
              'Take Profit',
              takeProfitController,
              _getCurrentPrice(),
            ),

          SizedBox(height: 16.h),

          // Stop Loss
          _buildSwitchTile(
            'Stop Loss',
            stopLossEnabled,
            onChanged: (value) {
              setState(() {
                stopLossEnabled = value;
                if (value) {
                  takeProfitEnabled = false;
                  // Initialize with current real-time price
                  stopLossPrice = _getCurrentPrice();
                  stopLossController.text = stopLossPrice.toString();
                } else {
                  stopLossPrice = null;
                  stopLossController.clear();
                }
              });
            },
          ),
          if (stopLossEnabled)
            _buildPriceInput(
              'Stop Loss',
              stopLossController,
              _getCurrentPrice(),
            ),
        ],
      ),
    );
  }

  Widget _buildFillPolicy() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Fill policy',
            style: AppTextStyles.label.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'Fill or Kill',
              style: AppTextStyles.label.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMessage() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Attention! The trade will be executed at market conditions, difference with requested price may be significant!',
              style: AppTextStyles.label.copyWith(
                fontSize: 12.sp,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(double profitLoss, bool isPositive) {
    // Format profit/loss to 2 decimal places with dollar sign
    final formattedProfitLoss = '\$${profitLoss.toStringAsFixed(2)}';

    final buttonText =
        isPositive
            ? 'CLOSE WITH PROFIT +$formattedProfitLoss'
            : 'CLOSE WITH LOSS $formattedProfitLoss';

    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: isProcessing ? null : _closePosition,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPositive ? AppColors.success : AppColors.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child:
            isProcessing
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Processing...',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                : Text(
                  buttonText,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  // Switch tile widget like chart screen
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
  }

  // Price input widget like chart screen
  Widget _buildPriceInput(
    String label,
    TextEditingController controller,
    double defaultValue,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: IconButton(
              onPressed: () {
                final currentValue =
                    double.tryParse(controller.text) ?? defaultValue;
                if (currentValue > 0.01) {
                  controller.text = (currentValue - 0.01).toString();
                }
              },
              icon: Icon(Icons.remove, size: 16.h, color: Colors.grey[600]),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ),
          Expanded(
            child: Center(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: (value) {
                  // Handle text change if needed
                },
              ),
            ),
          ),
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary),
            ),
            child: IconButton(
              onPressed: () {
                final currentValue =
                    double.tryParse(controller.text) ?? defaultValue;
                controller.text = (currentValue + 0.01).toString();
              },
              icon: Icon(Icons.add, size: 16.h, color: AppColors.primary),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
