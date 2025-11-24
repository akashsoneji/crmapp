import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/controllers/chart_socket_controller.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/flavor_config.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/widgets/fixed_size_webview.dart';
import 'package:pipze/widgets/common_loading_widget.dart';
import 'package:pipze/utils/precision_helper.dart';
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
  double closeVolume = 0.01;
  double? stopLossPrice;
  double? takeProfitPrice;

  // UI states
  bool isProcessing = false;
  bool stopLossEnabled = false;
  bool takeProfitEnabled = false;
  bool showChart = false; // Default chart switch OFF

  // Double-click prevention
  DateTime? _lastButtonClickTime;
  static const Duration _buttonClickDelay = Duration(milliseconds: 500);

  // Controllers for text fields
  late TextEditingController stopLossController;
  late TextEditingController takeProfitController;
  late TextEditingController volumeController;

  // Volume display controller (to avoid memory leaks)
  late TextEditingController _volumeDisplayController;

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
    closeVolume = _positionVolume;

    // Initialize text controllers
    stopLossController = TextEditingController();
    takeProfitController = TextEditingController();
    volumeController = TextEditingController();
    _volumeDisplayController = TextEditingController();

    // Initialize volume display
    _updateVolumeDisplay();

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
      takeProfitController.text =
          currentPrice.toString(); //PrecisionHelper.formatPrice(currentPrice);
      takeProfitPrice = currentPrice;
    }

    if (stopLossEnabled && stopLossController.text.isEmpty) {
      stopLossController.text =
          currentPrice.toString(); //PrecisionHelper.formatPrice(currentPrice);
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

  // Helper method to get position volume as double
  double get _positionVolume => widget.position.volume;

  // Helper method to get symbol without .c suffix
  String get _displaySymbol => widget.position.symbol.replaceFirst('.c', '');

  // Wrapper method for button press with debug logging
  void _onButtonPressed() {
    print('🚀 _onButtonPressed: Button pressed!');
    print('🚀 _onButtonPressed: isProcessing: $isProcessing');
    print(
      '🚀 _onButtonPressed: hasTPSL: ${takeProfitEnabled || stopLossEnabled}',
    );
    print('🚀 _onButtonPressed: takeProfitEnabled: $takeProfitEnabled');
    print('🚀 _onButtonPressed: stopLossEnabled: $stopLossEnabled');

    if (isProcessing) {
      print('🚀 _onButtonPressed: Blocked - isProcessing is true');
      return;
    }

    if (!_canClickButton()) {
      print('🚀 _onButtonPressed: Blocked - _canClickButton returned false');
      return;
    }

    _closePosition();
  }

  // Prevent double-click on buttons
  bool _canClickButton() {
    final now = DateTime.now();
    print('🚀 _canClickButton: Checking button click timing');
    print('🚀 _canClickButton: _lastButtonClickTime: $_lastButtonClickTime');

    if (_lastButtonClickTime == null) {
      _lastButtonClickTime = now;
      print('🚀 _canClickButton: First click - allowing');
      return true;
    }

    final timeDiff = now.difference(_lastButtonClickTime!);
    print('🚀 _canClickButton: Time difference: ${timeDiff.inMilliseconds}ms');
    print(
      '🚀 _canClickButton: Button delay: ${_buttonClickDelay.inMilliseconds}ms',
    );

    if (timeDiff > _buttonClickDelay) {
      _lastButtonClickTime = now;
      print('🚀 _canClickButton: Time passed - allowing click');
      return true;
    }

    print('🚀 _canClickButton: Too soon - blocking click');
    return false;
  }

  // Update volume display controller
  void _updateVolumeDisplay() {
    _volumeDisplayController.text = PrecisionHelper.formatVolume(closeVolume);
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
      final totalVolume = _positionVolume;
      final closeVolumeRatio =
          totalVolume > 0 ? closeVolume / totalVolume : 0.0;
      final proportionalProfit = realTimeProfit * closeVolumeRatio;

      return proportionalProfit;
    }

    // Fallback to static position profit if not found in real-time data
    final totalVolume = _positionVolume;
    final closeVolumeRatio = totalVolume > 0 ? closeVolume / totalVolume : 0.0;
    return widget.position.profitLoss * closeVolumeRatio;
  }

  Future<void> _editOrder() async {
    print('🚀 _editOrder: Starting edit order process');
    print('🚀 _editOrder: takeProfitEnabled: $takeProfitEnabled');
    print('🚀 _editOrder: stopLossEnabled: $stopLossEnabled');
    print('🚀 _editOrder: takeProfitPrice: $takeProfitPrice');
    print('🚀 _editOrder: stopLossPrice: $stopLossPrice');

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

      // Get position ID
      final positionId = int.tryParse(widget.position.orderId) ?? 0;
      print('🚀 _editOrder: positionId: $positionId');
      print('🚀 _editOrder: mt5Account: ${activeAccount.metaAccountNumber}');

      // Update TP/SL prices from text controllers before API call
      double? finalTakeProfit;
      double? finalStopLoss;

      if (takeProfitEnabled && takeProfitController.text.isNotEmpty) {
        finalTakeProfit = double.tryParse(takeProfitController.text);
        // PrecisionHelper.parseDouble(
        // takeProfitController.text,
        // );
        print(
          '🚀 _editOrder: Final takeProfit from controller: $finalTakeProfit',
        );
      }

      if (stopLossEnabled && stopLossController.text.isNotEmpty) {
        finalStopLoss = double.tryParse(stopLossController.text);
        // PrecisionHelper.parseDouble(stopLossController.text);
        print('🚀 _editOrder: Final stopLoss from controller: $finalStopLoss');
      }

      // Validate that at least one TP/SL value is provided
      if (finalTakeProfit == null && finalStopLoss == null) {
        CustomToastService.showError(
          title: 'Error',
          message: 'Please provide at least one Take Profit or Stop Loss value',
        );
        return;
      }

      print(
        '🚀 _editOrder: Calling API with TP: $finalTakeProfit, SL: $finalStopLoss',
      );

      // Call the updateTPSL method from trading controller
      final success = await tradingController.updateTPSL(
        mt5Account: activeAccount.metaAccountNumber,
        positionId: positionId,
        stopLoss: finalStopLoss,
        takeProfit: finalTakeProfit,
      );

      print('🚀 _editOrder: API call result: $success');

      // Navigate back on success (no toast)
      if (success) {
        _navigateToTradeScreen();
      }
    } catch (e) {
      print('🚀 _editOrder: Error: $e');
      CustomToastService.showError(
        title: 'Error',
        message: 'Failed to update order: ${e.toString()}',
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _closePosition() async {
    print('🚀 _closePosition: Button clicked!');
    print('🚀 _closePosition: isProcessing: $isProcessing');

    if (isProcessing) {
      print('🚀 _closePosition: Blocked by isProcessing');
      return;
    }

    // Check if TP or SL is enabled - if so, this is an EDIT ORDER action
    final hasTPSL = takeProfitEnabled || stopLossEnabled;
    print('🚀 _closePosition: hasTPSL: $hasTPSL');
    print('🚀 _closePosition: takeProfitEnabled: $takeProfitEnabled');
    print('🚀 _closePosition: stopLossEnabled: $stopLossEnabled');

    if (hasTPSL) {
      print('🚀 _closePosition: Calling _editOrder()');
      // Handle EDIT ORDER - modify existing position with TP/SL
      await _editOrder();
      return;
    }

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

      // Get position ID and volume
      final positionId = int.tryParse(widget.position.orderId) ?? 0;
      final totalVolume = _positionVolume;

      // Determine if this is a partial close
      final isPartialClose = closeVolume < totalVolume;
      final volumeToClose = isPartialClose ? closeVolume : null;

      // Call the closePositionById method from trading controller
      final success = await tradingController.closePositionById(
        mt5Account: activeAccount.metaAccountNumber,
        positionId: positionId,
        volume:
            volumeToClose, // null for full close, specific volume for partial
      );

      // Navigate back on success (no toast)
      if (success) {
        _navigateToTradeScreen();
      }
    } catch (e) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Failed to close position: ${e.toString()}',
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  /// Get the flag SVG path based on the instrument symbol
  /// Extracts currency code from symbol (e.g., EURUSD -> EUR)
  /// Returns path like 'assets/svg/flags/eurusd.svg'
  String _getFlagPath(String symbol) {
    // Remove suffix if present (e.g., EURUSD.c -> EURUSD)
    String cleanSymbol =
        symbol.contains('.')
            ? symbol.substring(0, symbol.lastIndexOf('.'))
            : symbol;

    // Return path with full symbol lowercase
    return 'assets/svg/flags/${cleanSymbol.toLowerCase()}.svg';
  }

  /// Build flag icon widget with error handling
  Widget _buildFlagIcon(String symbol, {double? size}) {
    final flagSize = size ?? 24.h;
    final containerSize = flagSize + 16.h; // Add padding for container
    final iconSize = flagSize; // Icon size stays the same
    final flagPath = _getFlagPath(symbol);

    return FutureBuilder<String?>(
      future: _checkAssetExists(flagPath),
      builder: (context, snapshot) {
        // If asset exists, show SVG
        if (snapshot.hasData && snapshot.data != null) {
          return Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: SvgPicture.asset(
                flagPath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        // If asset doesn't exist or error occurred, show fallback
        return _buildFallbackFlag(flagSize, containerSize, iconSize);
      },
    );
  }

  /// Check if asset exists by trying to load it
  Future<String?> _checkAssetExists(String assetPath) async {
    try {
      await DefaultAssetBundle.of(context).load(assetPath);
      return assetPath;
    } catch (e) {
      return null;
    }
  }

  /// Build fallback flag image widget
  Widget _buildFallbackFlag(
    double flagSize,
    double containerSize,
    double iconSize,
  ) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: Image.asset(
            'assets/image/noflag.jpeg',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Image.asset(
                  'assets/image/no_flag_icon.png',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _priceStreamSubscription?.cancel();
    stopLossController.dispose();
    takeProfitController.dispose();
    volumeController.dispose();
    _volumeDisplayController.dispose();
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
        toolbarHeight: 72.h, // a bit more height so 2 lines fit nicely
        centerTitle: false, // easier for layout; we’ll align manually
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset(
            'assets/svg/trade/arro_back.svg',
            width: 256.w,
            height: 30.h,
          ),
        ),
        titleSpacing: 0, // so title starts close to leading
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildFlagIcon(widget.position.symbol, size: 20.h),
                SizedBox(width: 8.w),
                Expanded(
                  // <-- let text flex in remaining space
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Close / Modify Position',
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis, // <-- no overflow, show "..."
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${widget.position.action} ${widget.position.volume} $_displaySymbol at ${widget.position.openPrice}',
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis, // <-- also protect second line
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(width: 16.w), // small padding instead of 56.w “fake” action
        ],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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

                        // Current Profit/Loss Display (Reactive to real-time updates)
                        Obx(() {
                          final profitLoss = _calculateProfitLoss();
                          final isPositive = profitLoss >= 0;
                          return _buildCurrentProfitLoss(
                            profitLoss,
                            isPositive,
                          );
                        }),
                        SizedBox(height: 12.h),

                        // Close Button (Reactive to real-time updates)
                        Obx(() {
                          final profitLoss = _calculateProfitLoss();
                          final isPositive = profitLoss >= 0;
                          return _buildCloseButton(profitLoss, isPositive);
                        }),

                        // Extra padding for keyboard
                        SizedBox(
                          height:
                              MediaQuery.of(context).viewInsets.bottom > 0
                                  ? MediaQuery.of(context).viewInsets.bottom +
                                      20.h
                                  : 20.h,
                        ),
                      ],
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
      height: showChart ? MediaQuery.of(context).size.height * 0.4 : 64.h,
      child: Column(
        children: [
          // Chart Header with Toggle
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
                symbol: '${widget.position.symbol.replaceFirst(".c", "")}',
                url: '',
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
                  // PrecisionHelper.formatPrice(bid),
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
                  // PrecisionHelper.formatPrice(ask),
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
    // Get lot size from position
    final lotSize = _positionVolume;
    final minVolume = 0.01;
    final maxVolume = lotSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with lot size info
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Text(
        //       'Quantity to close',
        //       style: AppTextStyles.label.copyWith(
        //         fontSize: 16.sp,
        //         fontWeight: FontWeight.w600,
        //         color: AppColors.textPrimary,
        //       ),
        //     ),
        //     Text(
        //       'Max: ${lotSize.toStringAsFixed(2)} lots',
        //       style: AppTextStyles.label.copyWith(
        //         fontSize: 12.sp,
        //         fontWeight: FontWeight.w500,
        //         color: AppColors.textGrey,
        //       ),
        //     ),
        //   ],
        // ),
        // SizedBox(height: 12.h),

        // // TextFormField for direct input
        // TextFormField(
        //   controller: volumeController,
        //   keyboardType: TextInputType.numberWithOptions(decimal: true),
        //   style: AppTextStyles.label.copyWith(
        //     fontSize: 16.sp,
        //     fontWeight: FontWeight.w600,
        //     color: AppColors.textPrimary,
        //   ),
        //   decoration: InputDecoration(
        //     hintText: 'Enter volume',
        //     hintStyle: AppTextStyles.label.copyWith(
        //       fontSize: 14.sp,
        //       color: AppColors.textGrey,
        //     ),
        //     prefixIcon: Icon(
        //       Icons.trending_up,
        //       color: AppColors.primary,
        //       size: 20.sp,
        //     ),
        //     suffixText: 'lots',
        //     suffixStyle: AppTextStyles.label.copyWith(
        //       fontSize: 12.sp,
        //       color: AppColors.textGrey,
        //     ),
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(8.r),
        //       borderSide: BorderSide(color: AppColors.border),
        //     ),
        //     enabledBorder: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(8.r),
        //       borderSide: BorderSide(color: AppColors.border),
        //     ),
        //     focusedBorder: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(8.r),
        //       borderSide: BorderSide(color: AppColors.primary, width: 2),
        //     ),
        //     errorBorder: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(8.r),
        //       borderSide: BorderSide(color: AppColors.error),
        //     ),
        //     contentPadding: EdgeInsets.symmetric(
        //       horizontal: 16.w,
        //       vertical: 12.h,
        //     ),
        //   ),
        //   onChanged: (value) {
        //     final newVolume = double.tryParse(value) ?? 0.0;
        //     if (newVolume >= minVolume && newVolume <= maxVolume) {
        //       setState(() {
        //         closeVolume = newVolume;
        //       });
        //     }
        //   },
        //   validator: (value) {
        //     if (value == null || value.isEmpty) {
        //       return 'Please enter volume';
        //     }
        //     final volume = double.tryParse(value);
        //     if (volume == null) {
        //       return 'Invalid volume format';
        //     }
        //     if (volume < minVolume) {
        //       return 'Minimum volume is ${minVolume.toStringAsFixed(2)} lots';
        //     }
        //     if (volume > maxVolume) {
        //       return 'Maximum volume is ${maxVolume.toStringAsFixed(2)} lots';
        //     }
        //     return null;
        //   },
        // ),

        // SizedBox(height: 12.h),

        // // Quick adjustment buttons
        // SingleChildScrollView(
        //   scrollDirection: Axis.horizontal,
        //   child: Row(
        //     children: [
        //       SizedBox(width: 8.w),
        //       _buildVolumeButton('-0.5', -0.5),
        //       SizedBox(width: 8.w),
        //       _buildVolumeButton('-0.1', -0.1),
        //       SizedBox(width: 8.w),
        //       _buildVolumeButton('-0.01', -0.01),
        //       SizedBox(width: 8.w),
        //       _buildVolumeButton('0.01', 0.01, isSelected: closeVolume == 0.01),
        //       SizedBox(width: 8.w),
        //       _buildVolumeButton('+0.01', 0.01),
        //       SizedBox(width: 8.w),
        //       _buildVolumeButton('+0.1', 0.1),
        //       SizedBox(width: 8.w),
        //       _buildVolumeButton('+0.5', 0.5),
        //       SizedBox(width: 8.w),
        //       // Max volume button
        //       _buildVolumeButton('MAX', 0, isMaxButton: true),
        //       SizedBox(width: 8.w),
        //     ],
        //   ),
        // ),

        // SizedBox(height: 12.h),

        // Close Partially Section with Heading
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Close Partially',
              style: AppTextStyles.label.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),

            // Compact switch container (like take profit style)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Partial Close',

                          style: AppTextStyles.label.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: closeVolume < lotSize,
                          onChanged: (value) {
                            if (value) {
                              // Enable partial close - set to half of lot size
                              setState(() {
                                closeVolume = PrecisionHelper.clamp(
                                  lotSize / 2,
                                  minVolume,
                                  maxVolume,
                                );
                                _volumeDisplayController.text = closeVolume
                                    .toStringAsFixed(2);
                              });
                            } else {
                              // Disable partial close - set to full lot size
                              setState(() {
                                closeVolume = PrecisionHelper.clamp(
                                  lotSize,
                                  minVolume,
                                  maxVolume,
                                );
                                _volumeDisplayController.text = closeVolume
                                    .toStringAsFixed(2);
                              });
                            }
                          },
                          activeColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withOpacity(0.3),
                          inactiveThumbColor: AppColors.whiteColor,
                          inactiveTrackColor: AppColors.icongrey.withAlpha(55),
                          trackOutlineColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),

                  // Show input field when partial close is enabled
                  if (closeVolume < lotSize) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 25.w,
                            height: 25.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: IconButton(
                              onPressed: () {
                                if (closeVolume > minVolume) {
                                  setState(() {
                                    closeVolume = PrecisionHelper.clamp(
                                      closeVolume - 0.01,
                                      minVolume,
                                      lotSize,
                                    );
                                    _volumeDisplayController.text = closeVolume
                                        .toStringAsFixed(2);
                                  });
                                }
                              },
                              icon: Icon(
                                Icons.remove,
                                size: 20.h,
                                color: Colors.grey[600],
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: TextField(
                                controller: _volumeDisplayController,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter lots',
                                  hintStyle: AppTextStyles.label.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.textGrey,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  // Allow empty value while user is typing
                                  if (value.isEmpty) {
                                    return; // Don't update, let user continue typing
                                  }

                                  final newVolume = double.tryParse(value);
                                  if (newVolume != null && newVolume > 0) {
                                    // Clamp to valid range
                                    final clampedVolume = PrecisionHelper.clamp(
                                      newVolume,
                                      minVolume,
                                      lotSize,
                                    );
                                    setState(() {
                                      closeVolume = clampedVolume;
                                      // Only update display if value changed (to avoid cursor jump)
                                      if (clampedVolume != newVolume) {
                                        _updateVolumeDisplay();
                                      }
                                    });
                                  }
                                },
                                onEditingComplete: () {
                                  // When keyboard is dismissed, validate and update
                                  final textValue =
                                      _volumeDisplayController.text;
                                  if (textValue.isEmpty) {
                                    // If empty, restore to current closeVolume
                                    _updateVolumeDisplay();
                                    FocusScope.of(context).unfocus();
                                    return;
                                  }

                                  final parsedVolume = double.tryParse(
                                    textValue,
                                  );
                                  if (parsedVolume != null &&
                                      parsedVolume > 0) {
                                    final validatedVolume =
                                        PrecisionHelper.clamp(
                                          parsedVolume,
                                          minVolume,
                                          lotSize,
                                        );
                                    setState(() {
                                      closeVolume = validatedVolume;
                                      _updateVolumeDisplay();
                                    });
                                  } else {
                                    // Invalid value, restore to current
                                    _updateVolumeDisplay();
                                  }
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: 25.w,
                            height: 25.h,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: IconButton(
                              onPressed: () {
                                if (closeVolume < lotSize) {
                                  setState(() {
                                    closeVolume = PrecisionHelper.clamp(
                                      closeVolume + 0.01,
                                      minVolume,
                                      lotSize,
                                    );
                                    _volumeDisplayController.text = closeVolume
                                        .toStringAsFixed(2);
                                  });
                                }
                              },
                              icon: Icon(
                                Icons.add,
                                size: 20.h,
                                color: AppColors.primary,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 8.h),

        // Current selection display
        Center(
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              'Selected: ${PrecisionHelper.formatVolume(closeVolume)} lots (${PrecisionHelper.calculatePercentage(closeVolume, lotSize)}%)',
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
                  takeProfitPrice = _getCurrentPrice();
                  takeProfitController.text = takeProfitPrice!.toString();
                  // PrecisionHelper.formatPrice(
                  // takeProfitPrice!,
                  // );
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
                  stopLossPrice = _getCurrentPrice();
                  stopLossController.text = stopLossPrice!.toString();

                  // PrecisionHelper.formatPrice(
                  // stopLossPrice!,
                  // );
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
                'Current P&L: \$${PrecisionHelper.formatPnL(profitLoss)}',
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
                '\$${PrecisionHelper.formatPnL(fullPositionProfit)}',
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
                '${PrecisionHelper.formatVolume(closeVolume)} lots',
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
    final formattedProfitLoss = '\$${PrecisionHelper.formatPnL(profitLoss)}';

    // Check if TP or SL is enabled
    final hasTPSL = takeProfitEnabled || stopLossEnabled;

    // Get lot size for partial close check
    final lotSize = _positionVolume;
    final isPartialClose = closeVolume < lotSize;

    // Dynamic button text based on conditions
    String buttonText;
    if (hasTPSL) {
      buttonText = 'MODIFY ORDER';
    } else if (isPartialClose) {
      buttonText =
          isPositive
              ? 'CLOSE ${PrecisionHelper.formatVolume(closeVolume)} LOTS WITH PROFIT +$formattedProfitLoss'
              : 'CLOSE ${PrecisionHelper.formatVolume(closeVolume)} LOTS WITH LOSS $formattedProfitLoss';
    } else {
      buttonText =
          isPositive
              ? 'CLOSE ALL WITH PROFIT +$formattedProfitLoss'
              : 'CLOSE ALL WITH LOSS $formattedProfitLoss';
    }

    return SizedBox(
      width: double.infinity,
      height: 40.h,
      child: ElevatedButton(
        onPressed: isProcessing ? null : _onButtonPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor:
              hasTPSL
                  ? AppColors.primary
                  : (isPositive ? AppColors.success : AppColors.error),
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
                    ButtonLoadingWidget(size: 20.0, color: Colors.white),
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
                final currentValue = PrecisionHelper.parseDouble(
                  controller.text,
                );
                if (currentValue > 0.01) {
                  controller.text = PrecisionHelper.formatPrice(
                    currentValue - 0.01,
                  );
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
                  final price = PrecisionHelper.parseDouble(value);
                  if (price > 0) {
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
                final currentValue = PrecisionHelper.parseDouble(
                  controller.text,
                );
                controller.text = PrecisionHelper.formatPrice(
                  currentValue + 0.01,
                );
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

  // Navigate back to trade screen using bottom navigation
  void _navigateToTradeScreen() {
    // Simply go back to previous screen
    // The trading controller will handle UI updates
    Get.back();
  }
}
