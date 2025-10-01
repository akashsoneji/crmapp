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
import 'package:pipze/widgets/fixed_size_webview.dart';
import 'dart:async';

class ClosePositionScreen extends StatefulWidget {
  final TradePosition position;

  const ClosePositionScreen({super.key, required this.position});

  @override
  State<ClosePositionScreen> createState() => _ClosePositionScreenState();
}

class _ClosePositionScreenState extends State<ClosePositionScreen> {
  // Controllers - Both Chart Socket and Trading Controller
  late final ChartSocketController chartSocketController;
  late final AccountController accountController;
  late final TradingController tradingController;

  // Position controls
  final closeVolume = 0.01.obs;
  double? stopLossPrice;
  double? takeProfitPrice;

  // UI states
  bool isProcessing = false;
  bool stopLossEnabled = false;
  bool takeProfitEnabled = false;
  bool showChart = true;

  // Controllers for text fields
  late TextEditingController stopLossController;
  late TextEditingController takeProfitController;

  // Stream subscription for cleanup
  StreamSubscription<Map<String, dynamic>>? _priceStreamSubscription;

  // Scroll controller for keyboard handling
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _initializeControllers();

    // Initialize position data
    closeVolume.value = widget.position.volume;

    // Initialize text controllers
    stopLossController = TextEditingController();
    takeProfitController = TextEditingController();

    // Initialize scroll controller
    _scrollController = ScrollController();

    // Listen to price updates from chart socket
    _listenToPriceUpdates();

    // Change symbol to position's symbol for chart socket
    _changeSymbolToPosition();
  }

  void _initializeControllers() {
    // Chart Socket Controller for real-time price data
    chartSocketController = Get.find<ChartSocketController>();

    // Account Controller for account info
    accountController = Get.find<AccountController>();

    // Trading Controller for profit data (like trade screen)
    tradingController = Get.find<TradingController>();
  }

  void _listenToPriceUpdates() {
    // Listen to chart socket for real-time price updates
    _priceStreamSubscription = chartSocketController.priceStream.listen((
      priceData,
    ) {
      if (mounted) {
        // Update TP/SL fields with current prices if enabled
        _updatePriceFieldsWithCurrentPrices();
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
    // Change chart socket symbol to position's symbol for real-time prices
    chartSocketController.changeSymbol(widget.position.symbol);
  }

  double _getCurrentPrice() {
    // Get real-time price from chart socket controller
    final bid = chartSocketController.getBidPrice() ?? 0.0;
    final ask = chartSocketController.getAskPrice() ?? 0.0;

    // Return the appropriate price based on position action
    if (widget.position.action.toLowerCase() == 'buy') {
      return bid; // For buy positions, close at bid
    } else {
      return ask; // For sell positions, close at ask
    }
  }

  double _calculateProfitLoss() {
    // Get real-time profit from TradingController like trade screen
    final positions = tradingController.marketPositions;
    final position = positions.firstWhereOrNull(
      (p) => p.orderId == widget.position.orderId,
    );

    if (position != null) {
      // Use real-time profit from WebSocket data
      final realTimeProfit = position.profitLoss;

      // Calculate proportional profit based on close volume
      final totalVolume = widget.position.volume;
      final closeVolumeRatio = closeVolume.value / totalVolume;
      final proportionalProfit = realTimeProfit * closeVolumeRatio;

      return proportionalProfit;
    }

    // Fallback to static position profit if not found in real-time data
    final totalVolume = widget.position.volume;
    final closeVolumeRatio = closeVolume.value / totalVolume;
    return widget.position.profitLoss * closeVolumeRatio;
  }

  void _updateCloseVolume(double delta) {
    final currentVolume = closeVolume.value;
    final newVolume = currentVolume + delta;

    // Ensure minimum volume is 0.01 lots
    final minVolume = 0.01;
    // Maximum volume is the position's total volume
    final maxVolume = widget.position.volume;

    // Clamp the volume between minimum and maximum
    final clampedVolume = newVolume.clamp(minVolume, maxVolume);

    // Only update if the new volume is valid
    if (clampedVolume >= minVolume && clampedVolume <= maxVolume) {
      closeVolume.value = clampedVolume;
    }
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
        'volume': closeVolume.value,
      };

      // Add stop loss and take profit if switches are enabled
      if (stopLossEnabled && stopLossPrice != null) {
        payload['stop_loss'] = stopLossPrice!;
      }
      if (takeProfitEnabled && takeProfitPrice != null) {
        payload['take_profit'] = takeProfitPrice!;
      }

      // Choose API endpoint based on close type
      String endpoint;
      if (closeVolume.value < widget.position.volume) {
        endpoint = ApiConstants.closePositionByPositionId; // Partial close
      } else {
        endpoint = ApiConstants.closePositions; // Full close
      }

      // Call API
      final response = await ApiService.post(endpoint: endpoint, data: payload);

      if (response.success) {
        CustomToastService.showSuccess(
          title: 'Success',
          message:
              closeVolume.value < widget.position.volume
                  ? 'Position partially closed successfully'
                  : 'Position closed successfully',
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
        ),
        title: Column(
          children: [
            Text(
              'Close Position',
              style: AppTextStyles.heading.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${widget.position.action} ${widget.position.volume} ${widget.position.symbol} at ${widget.position.openPrice}',
              style: AppTextStyles.label.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Chart Section
                _buildChartSection(),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 200.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current Prices (from Chart Socket)
                          _buildCurrentPrices(),
                          SizedBox(height: 12.h),

                          // Volume Adjustment
                          _buildVolumeAdjustment(),
                          SizedBox(height: 12.h),

                          // Stop Loss and Take Profit with Switches
                          _buildStopLossTakeProfitWithSwitches(),
                          SizedBox(height: 12.h),

                          // Current Profit/Loss Display - Reactive with TradingController like trade screen
                          Obx(() {
                            // Access trading controller data for reactivity (like trade screen)
                            // ignore: unused_local_variable
                            final marketPositions =
                                tradingController.marketPositions;
                            // ignore: unused_local_variable
                            final currentCloseVolume = closeVolume.value;
                            final profitLoss = _calculateProfitLoss();
                            final isPositive = profitLoss >= 0;
                            return _buildCurrentProfitLoss(
                              profitLoss,
                              isPositive,
                            );
                          }),
                          SizedBox(height: 12.h),

                          // Close Button - Reactive with TradingController like trade screen
                          Obx(() {
                            // Access trading controller data for reactivity (like trade screen)
                            // ignore: unused_local_variable
                            final marketPositions =
                                tradingController.marketPositions;
                            // ignore: unused_local_variable
                            final currentCloseVolume = closeVolume.value;
                            final profitLoss = _calculateProfitLoss();
                            final isPositive = profitLoss >= 0;
                            return _buildCloseButton(profitLoss, isPositive);
                          }),

                          // Extra padding for keyboard
                          SizedBox(
                            height:
                                MediaQuery.of(context).viewInsets.bottom + 50.h,
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
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: showChart ? MediaQuery.of(context).size.height * 0.4 : 55.h,
      child: Column(
        children: [
          // Chart Header with Toggle
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chart',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    // Chart On/Off Toggle
                    Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: showChart,
                        onChanged: (value) {
                          setState(() {
                            showChart = value;
                          });
                        },
                        activeColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withOpacity(0.3),
                        inactiveThumbColor: AppColors.whiteColor,
                        inactiveTrackColor: AppColors.icongrey.withAlpha(55),
                        trackOutlineColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chart WebView (only when chart is enabled)
          if (showChart)
            Expanded(
              child: FixedSizeWebView(
                url:
                    'https://my.pipze.com/user/chart/${widget.position.symbol.replaceFirst(".c", "")}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentPrices() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bid Price (from Chart Socket)
          Column(
            children: [
              Text(
                'Bid',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10.sp,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Obx(() {
                final bid = chartSocketController.getBidPrice() ?? 0.0;
                return Text(
                  bid.toString(),
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                );
              }),
            ],
          ),
          Container(width: 2.w, height: 30.h, color: AppColors.border),
          // Ask Price (from Chart Socket)
          Column(
            children: [
              Text(
                'Ask',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10.sp,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Obx(() {
                final ask = chartSocketController.getAskPrice() ?? 0.0;
                return Text(
                  ask.toString(),
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                );
              }),
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
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: 8.w),
              _buildVolumeButton('-0.5', -0.5),
              SizedBox(width: 8.w),
              _buildVolumeButton('-0.1', -0.1),
              SizedBox(width: 8.w),
              _buildVolumeButton('-0.01', -0.01),
              SizedBox(width: 8.w),
              _buildVolumeButton(
                '0.01',
                0.01,
                isSelected: closeVolume.value == 0.01,
              ),
              SizedBox(width: 8.w),
              _buildVolumeButton('+0.01', 0.01),
              SizedBox(width: 8.w),
              _buildVolumeButton('+0.1', 0.1),
              SizedBox(width: 8.w),
              _buildVolumeButton('+0.5', 0.5),
              SizedBox(width: 8.w),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Center(
          child: Obx(
            () => Text(
              'Selected: ${closeVolume.value.toString()} lots',
              style: AppTextStyles.label.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
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
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStopLossTakeProfitWithSwitches() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Take Profit with Switch
          _buildSwitchTile(
            'Take Profit',
            takeProfitEnabled,
            onChanged: (value) {
              setState(() {
                takeProfitEnabled = value;
                if (value) {
                  stopLossEnabled = false;
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

          SizedBox(height: 4.h),

          // Stop Loss with Switch
          _buildSwitchTile(
            'Stop Loss',
            stopLossEnabled,
            onChanged: (value) {
              setState(() {
                stopLossEnabled = value;
                if (value) {
                  takeProfitEnabled = false;
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

  Widget _buildSwitchTile(
    String title,
    bool value, {
    required Function(bool) onChanged,
  }) {
    return Container(
      height: 35,
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            style: AppTextStyles.label.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.3),
              inactiveThumbColor: AppColors.whiteColor,
              inactiveTrackColor: AppColors.icongrey.withAlpha(55),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentProfitLoss(double profitLoss, bool isPositive) {
    // Get real-time full position profit from TradingController like trade screen
    final positions = tradingController.marketPositions;
    final position = positions.firstWhereOrNull(
      (p) => p.orderId == widget.position.orderId,
    );

    double fullPositionProfit;
    if (position != null) {
      // Use real-time profit from WebSocket data
      fullPositionProfit = position.profitLoss;
    } else {
      // Fallback to static position profit
      fullPositionProfit = widget.position.profitLoss;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            isPositive
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color:
              isPositive
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? AppColors.success : AppColors.error,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Current P&L: \$${profitLoss.toStringAsFixed(2)}',
                style: AppTextStyles.label.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Full Position:',
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                '\$${fullPositionProfit.toStringAsFixed(2)}',
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color:
                      fullPositionProfit >= 0
                          ? AppColors.success
                          : AppColors.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Closing:',
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                '${closeVolume.value} lots',
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
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
      height: 56.h,
      child: ElevatedButton(
        onPressed: isProcessing ? null : _closePosition,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPositive ? AppColors.success : AppColors.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
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
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                : Text(
                  buttonText,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 20.w,
            height: 20.h,
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
              icon: Icon(Icons.remove, size: 10.h, color: Colors.grey[600]),
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
                  fontSize: 16.sp,
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
                  // Update the price value when text changes
                  final price = double.tryParse(value);
                  if (price != null) {
                    if (label == 'Take Profit') {
                      takeProfitPrice = price;
                    } else if (label == 'Stop Loss') {
                      stopLossPrice = price;
                    }
                  }
                },
                onTap: () {
                  // Scroll to make input field visible when keyboard appears
                  Future.delayed(Duration(milliseconds: 100), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent * 0.8,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                },
              ),
            ),
          ),
          Container(
            width: 20.w,
            height: 20.h,
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
              icon: Icon(Icons.add, size: 10.h, color: AppColors.primary),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
