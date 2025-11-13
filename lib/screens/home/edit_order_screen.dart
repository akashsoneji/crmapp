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
import 'package:pipze/widgets/common_loading_widget.dart';
import 'package:pipze/utils/precision_helper.dart';

class EditOrderScreen extends StatefulWidget {
  final TradePosition position;

  const EditOrderScreen({super.key, required this.position});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  int selectedTab = 0; // 0: Edit, 1: Partial close

  // Order type selection - removed for modify order functionality
  // int selectedOrderType = 0; // 0: Market, 1: Buy Limit, 2: Sell Limit

  // Toggle states
  bool takeProfitEnabled = false;
  bool stopLossEnabled = false;
  bool advanceSettingsExpanded = false;
  bool trailingStopEnabled = false;
  bool breakEvenEnabled = false;

  // Partial close volume
  double partialCloseVolume = 0.00;

  // Loading states
  bool isProcessingEdit = false;
  bool isProcessingPartialClose = false;

  // Current position data
  double totalVolume = 0.0;
  double remainingVolume = 0.0;
  double profitFromPartialClose = 0.0;

  // Controllers
  late TextEditingController takeProfitController;
  late TextEditingController stopLossController;
  late TextEditingController trailingStopController;
  late TextEditingController breakEvenController;
  late TextEditingController limitPriceController;
  late TextEditingController volumeController;

  // Real-time price data
  late final ChartSocketController chartSocketController;
  late final ChartController chartController;
  late final AccountController accountController;

  // Current market prices
  double? currentBidPrice;
  double? currentAskPrice;
  String? currentSymbol;

  // Real-time price data from socket
  Map<String, dynamic>? realTimePriceData;

  // Validation states
  String? limitPriceError;
  String? stopLossError;
  String? takeProfitError;
  String? volumeError;

  // Helper method to get symbol without .c suffix
  String _getDisplaySymbol(String symbol) {
    return symbol.replaceFirst('.c', '');
  }

  @override
  void initState() {
    super.initState();

    print('🚀 TradeScreen: Navigating to EditOrderScreen');
    print('🚀 TradeScreen: Position: ${widget.position.symbol}');
    print('🚀 TradeScreen: Position: ${widget.position.action}');
    print('🚀 TradeScreen: Position: ${widget.position.currentPrice}');
    print('🚀 TradeScreen: Position: ${widget.position.entryPrice}');
    print('🚀 TradeScreen: Position: ${widget.position.volume}');
    print('🚀 TradeScreen: Position: ${widget.position.profitLoss}');
    print('🚀 TradeScreen: Position: ${widget.position.orderId}');
    print('🚀 TradeScreen: Position: ${widget.position.openTime}');
    print('🚀 TradeScreen: Position: ${widget.position.closeTime}');
    print('🚀 TradeScreen: Position: ${widget.position.takeProfit}');
    print('🚀 TradeScreen: Position: ${widget.position.stopLoss}');
    print('🚀 TradeScreen: Position: ${widget.position.mt5Account}');
    print('🚀 TradeScreen: Position: ${widget.position.time}');
    print('🚀 TradeScreen: Position: ${widget.position.flag}');
    print('🚀 TradeScreen: Position: ${widget.position.accountId}');
    takeProfitController = TextEditingController();
    stopLossController = TextEditingController();
    trailingStopController = TextEditingController();
    breakEvenController = TextEditingController();
    limitPriceController = TextEditingController();
    volumeController = TextEditingController();

    // Initialize position data
    totalVolume = widget.position.volume;
    remainingVolume = totalVolume;
    partialCloseVolume = totalVolume * 0.5; // Default to 50% of total volume
    volumeController.text = PrecisionHelper.formatVolume(partialCloseVolume);
    _calculatePartialCloseProfit();

    // Initialize controllers
    _initializeControllers();

    // Initialize current symbol and prices
    currentSymbol = widget.position.symbol;
    // //print('🚀 EditOrderScreen: Position symbol: ${widget.position.symbol}');
    // //print('🚀 EditOrderScreen: Position action: ${widget.position.action}');
    // //print(
    //   '🚀 EditOrderScreen: Position current price: ${widget.position.currentPrice}',
    // );

    _initializePrices();
    _setupPriceListener();
    _initializeSocketForSymbol();
  }

  void _initializeControllers() {
    // Initialize ChartSocketController
    try {
      chartSocketController = Get.find<ChartSocketController>();
      //print('EditOrderScreen: ChartSocketController found');
    } catch (e) {
      //print(
      // 'EditOrderScreen: ChartSocketController not found, creating new one: $e',
      // );
      chartSocketController = ChartSocketController();
      Get.put(chartSocketController, permanent: true);
    }

    // Initialize ChartController
    try {
      chartController = Get.find<ChartController>();
      // //print('EditOrderScreen: ChartController found');
    } catch (e) {
      //print('EditOrderScreen: ChartController not found, creating new one: $e');
      chartController = ChartController();
      Get.put(chartController, permanent: true);
    }

    // Initialize AccountController
    try {
      accountController = Get.find<AccountController>();
      // //print('EditOrderScreen: AccountController found');
    } catch (e) {
      // //print('EditOrderScreen: AccountController not found: $e');
      // AccountController should always be available, but just in case
      // Get.snackbar('Error', 'Account controller not available');
    }

    // Initialize Take Profit and Stop Loss from position data
    final digits = _getDecimalDigitsForSymbol(widget.position.symbol);

    // Initialize Take Profit if it exists
    if (widget.position.takeProfit.isNotEmpty &&
        widget.position.takeProfit != '0' &&
        widget.position.takeProfit != '0.0' &&
        widget.position.takeProfit != '0.00000') {
      takeProfitEnabled = true;
      final tpValue = double.tryParse(widget.position.takeProfit) ?? 0.0;
      if (tpValue > 0) {
        takeProfitController.text = PrecisionHelper.formatPrice(
          tpValue,
          decimals: digits,
        );
      }
    }

    // Initialize Stop Loss if it exists
    if (widget.position.stopLoss.isNotEmpty &&
        widget.position.stopLoss != '0' &&
        widget.position.stopLoss != '0.0' &&
        widget.position.stopLoss != '0.00000') {
      stopLossEnabled = true;
      final slValue = double.tryParse(widget.position.stopLoss) ?? 0.0;
      if (slValue > 0) {
        stopLossController.text = PrecisionHelper.formatPrice(
          slValue,
          decimals: digits,
        );
      }
    }
  }

  // Helper method to get decimal digits for a symbol
  int _getDecimalDigitsForSymbol(String symbol) {
    final symbolUpper = symbol.toUpperCase();
    if (symbolUpper.contains('JPY')) {
      return 3;
    } else if (symbolUpper.contains('XAU') || symbolUpper.contains('GOLD')) {
      return 2;
    } else if (symbolUpper.contains('XAG') || symbolUpper.contains('SILVER')) {
      return 3;
    } else {
      // Default for major currency pairs
      return 5;
    }
  }

  // Helper method to get pip increment value for a symbol
  double _getPipIncrementForSymbol(String symbol) {
    final symbolUpper = symbol.toUpperCase();
    if (symbolUpper.contains('JPY')) {
      return 0.01;
    } else if (symbolUpper.contains('XAU') || symbolUpper.contains('GOLD')) {
      return 0.01;
    } else if (symbolUpper.contains('XAG') || symbolUpper.contains('SILVER')) {
      return 0.001;
    } else {
      // Default for major currency pairs
      return 0.0001;
    }
  }

  void _initializePrices() {
    // Get current prices from chart socket controller
    final priceData = chartSocketController.getCurrentPrice();
    if (priceData != null) {
      currentBidPrice = chartSocketController.getBidPrice();
      currentAskPrice = chartSocketController.getAskPrice();
    }
  }

  void _setupPriceListener() {
    // Listen to real-time price updates
    chartSocketController.priceStream.listen((priceData) {
      if (mounted) {
        setState(() {
          realTimePriceData = priceData;
          currentBidPrice = chartSocketController.getBidPrice();
          currentAskPrice = chartSocketController.getAskPrice();
          _validateStopLoss();
          _validateTakeProfit();
          _updatePriceFieldsWithCurrentPrices();
        });
      }
    });
  }

  void _updatePriceFieldsWithCurrentPrices() {
    // Update text fields with current real-time prices if they're enabled
    final currentPrice = _getCurrentRealTimePriceAsDouble();
    final digits = _getDecimalDigitsForSymbol(widget.position.symbol);

    if (takeProfitEnabled && takeProfitController.text.isNotEmpty) {
      // Only update if the field is empty or if user hasn't manually edited it recently
      // This prevents overwriting user input
      final currentValue = PrecisionHelper.parseDouble(
        takeProfitController.text,
      );
      if (currentValue == 0.0) {
        takeProfitController.text = PrecisionHelper.formatPrice(
          currentPrice,
          decimals: digits,
        );
      }
    }

    if (stopLossEnabled && stopLossController.text.isNotEmpty) {
      // Only update if the field is empty or if user hasn't manually edited it recently
      final currentValue = PrecisionHelper.parseDouble(stopLossController.text);
      if (currentValue == 0.0) {
        stopLossController.text = PrecisionHelper.formatPrice(
          currentPrice,
          decimals: digits,
        );
      }
    }
  }

  void _initializeSocketForSymbol() {
    // Initialize socket for the current symbol to get real-time price updates
    if (currentSymbol != null) {
      // //print(
      //   '🚀 EditOrderScreen: Initializing socket for symbol: $currentSymbol',
      // );
      // //print(
      //   '🚀 EditOrderScreen: Initializing socket for symbol position: ${widget.position.symbol}',
      // );
      // Use the symbol as-is since it already has .c suffix
      String formattedSymbol = currentSymbol!;

      //print('🚀 EditOrderScreen: Original symbol: $currentSymbol');
      //print(
      // '🚀 EditOrderScreen: Formatted symbol for socket: $formattedSymbol',
      // );
      //print(
      // '🚀 EditOrderScreen: Socket connected: ${chartSocketController.isConnected.value}',
      // );

      // Change symbol in chart socket controller to get real-time updates
      chartSocketController.changeSymbol(formattedSymbol);

      // Wait a bit for socket to be ready, then request data
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted && chartSocketController.isConnected.value) {
          chartSocketController.getSocketData();
        } else {
          // Retry after another delay
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              chartSocketController.getSocketData();
            }
          });
        }
      });
    }
  }

  // Validation methods - limit price validation removed for modify order
  // void _validateLimitPrice() {
  //   // Limit price validation removed for modify order functionality
  // }

  void _validateStopLoss() {
    if (!stopLossEnabled) return;

    final stopLossPrice = PrecisionHelper.parseDouble(stopLossController.text);
    if (stopLossPrice == 0.0) {
      stopLossError = 'Invalid price format';
      return;
    }

    // Basic validation for stop loss - can be enhanced based on position type
    stopLossError = null;
  }

  void _validateTakeProfit() {
    if (!takeProfitEnabled) return;

    final takeProfitPrice = PrecisionHelper.parseDouble(
      takeProfitController.text,
    );
    if (takeProfitPrice == 0.0) {
      takeProfitError = 'Invalid price format';
      return;
    }

    // Basic validation for take profit - can be enhanced based on position type
    takeProfitError = null;
  }

  // Modify order method - using update-tp-sl API
  Future<void> _modifyOrder() async {
    // Check if both take profit and stop loss are empty
    if (takeProfitController.text.isEmpty && stopLossController.text.isEmpty) {
      return;
    }

    setState(() {
      isProcessingEdit = true;
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

      // Parse TP/SL values
      double? takeProfit;
      double? stopLoss;

      if (takeProfitController.text.isNotEmpty) {
        takeProfit = double.tryParse(takeProfitController.text);
      }

      if (stopLossController.text.isNotEmpty) {
        stopLoss = double.tryParse(stopLossController.text);
      }

      // Get trading controller
      final tradingController = Get.find<TradingController>();

      // Call the updateTPSL method from trading controller
      final success = await tradingController.updateTPSL(
        mt5Account: activeAccount.metaAccountNumber,
        positionId: positionId,
        stopLoss: stopLoss,
        takeProfit: takeProfit,
      );

      // Navigate back on success (no toast)
      if (success) {
        Get.back();
      }
    } catch (e) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Failed to modify order: ${e.toString()}',
      );
    } finally {
      setState(() {
        isProcessingEdit = false;
      });
    }
  }

  bool _isOrderValid() {
    _validateStopLoss();
    _validateTakeProfit();

    if (stopLossEnabled && stopLossError != null) return false;
    if (takeProfitEnabled && takeProfitError != null) return false;

    return true;
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
  Widget _buildFallbackFlag(double flagSize, double containerSize, double iconSize) {
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
    takeProfitController.dispose();
    stopLossController.dispose();
    trailingStopController.dispose();
    breakEvenController.dispose();
    limitPriceController.dispose();

    // Clean up socket connection
    //print('🚀 EditOrderScreen: Disposing and cleaning up socket');

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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Order Overview Section
              _buildOrderSummary(widget.position, isPositive),
              _buildOrderDetailsList(),

              // Tabs
              _buildTabs(),

              SizedBox(height: 8.h),

              // Content
              selectedTab == 0
                  ? _buildEditContent()
                  : _buildPartialCloseContent(),

              // Bottom Action Buttons

              // Add extra padding at bottom for better scrolling
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
        child: _buildSimpleButton(),
      ),
    );
  }

  Widget _buildOrderSummary(TradePosition position, bool isPositive) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Flag and Symbol
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Flag icon
                    Container(
                      height: 44.h,
                      alignment: Alignment.centerLeft,
                      child: _buildFlagIcon(position.symbol, size: 28.h),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDisplaySymbol(position.symbol),
                            style: AppTextStyles.black14500.copyWith(
                              fontSize: 16.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                              Flexible(
                                child: RichText(
                                  overflow: TextOverflow.ellipsis,
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
          ),

          SizedBox(width: 8.w),

          // Profit/Loss and Price
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${PrecisionHelper.formatPnL(position.profitLoss)}',
                  style: AppTextStyles.black14500.copyWith(
                    color: isPositive ? AppColors.success : AppColors.error,
                    height: 1.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Current real-time price display
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Current: ', style: AppTextStyles.grey10400),
                        Text(
                          _getCurrentRealTimePrice(),
                          style: AppTextStyles.grey10400.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_isRealTimeDataActive()) ...[
                          SizedBox(width: 4.w),
                          Container(
                            width: 6.w,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    // Entry price display
                    Text(
                      'Entry: ${position.entryPrice}',
                      style: AppTextStyles.grey10400.copyWith(fontSize: 9.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Take Profit
          _buildSwitchTile(
            'Take Profit',
            takeProfitEnabled,
            onChanged: (value) {
              setState(() {
                takeProfitEnabled = value;
                if (value) {
                  trailingStopEnabled = false;
                  breakEvenEnabled = false;
                  // Initialize with current real-time price
                  final digits = _getDecimalDigitsForSymbol(
                    widget.position.symbol,
                  );
                  final currentPrice = _getCurrentRealTimePriceAsDouble();
                  takeProfitController.text = PrecisionHelper.formatPrice(
                    currentPrice,
                    decimals: digits,
                  );
                }
                _validateTakeProfit();
              });
            },
          ),
          if (takeProfitEnabled)
            _buildPriceInput(
              'Take Profit',
              takeProfitController,
              _getCurrentRealTimePriceAsDouble(),
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
                  trailingStopEnabled = false;
                  breakEvenEnabled = false;
                  // Initialize with current real-time price
                  final digits = _getDecimalDigitsForSymbol(
                    widget.position.symbol,
                  );
                  final currentPrice = _getCurrentRealTimePriceAsDouble();
                  stopLossController.text = PrecisionHelper.formatPrice(
                    currentPrice,
                    decimals: digits,
                  );
                }
                _validateStopLoss();
              });
            },
          ),
          if (stopLossEnabled)
            _buildPriceInput(
              'Stop Loss',
              stopLossController,
              _getCurrentRealTimePriceAsDouble(),
              error: stopLossError,
            ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildPartialCloseContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Volume to Close Input
          _buildVolumeToCloseInput(),
          SizedBox(height: 24.h),

          // Partial Close Summary
          _buildPartialCloseSummary(),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildVolumeToCloseInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volume to close',
          style: AppTextStyles.label.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: volumeError != null ? AppColors.error : AppColors.border,
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
                    final currentVolume = PrecisionHelper.parseDouble(
                      volumeController.text,
                    );
                    if (currentVolume > 0.01) {
                      final newVolume = (currentVolume - 0.01).clamp(
                        0.01,
                        totalVolume,
                      );
                      volumeController.text = PrecisionHelper.formatVolume(
                        newVolume,
                      );
                      _validateAndUpdateVolume(volumeController.text);
                    }
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
                child: TextFormField(
                  controller: volumeController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: AppTextStyles.label.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGrey,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 12.h,
                    ),
                    errorText: null, // We'll show error below the container
                  ),
                  onChanged: (value) {
                    _validateAndUpdateVolume(value);
                  },
                  onFieldSubmitted: (value) {
                    _validateAndUpdateVolume(value);
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
                    final currentVolume = PrecisionHelper.parseDouble(
                      volumeController.text,
                    );
                    if (currentVolume < totalVolume) {
                      final newVolume = (currentVolume + 0.01).clamp(
                        0.01,
                        totalVolume,
                      );
                      volumeController.text = PrecisionHelper.formatVolume(
                        newVolume,
                      );
                      _validateAndUpdateVolume(volumeController.text);
                    }
                  },
                  icon: Icon(Icons.add, size: 10.h, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
        if (volumeError != null) ...[
          SizedBox(height: 4.h),
          Text(
            volumeError!,
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.error,
            ),
          ),
        ],
        SizedBox(height: 8.h),
        Text(
          'Total volume: ${totalVolume.toStringAsFixed(2)} lots',
          style: AppTextStyles.label.copyWith(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.textGrey,
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
          _buildSummaryRow('Total volume', totalVolume.toStringAsFixed(2)),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            'Remaining volume',
            remainingVolume.toStringAsFixed(2),
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            'Profit from partial close',
            '${profitFromPartialClose >= 0 ? '+' : ''}\$${profitFromPartialClose.toStringAsFixed(2)}',
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

  Widget _buildPriceInput(
    String label,
    TextEditingController controller,
    double defaultValue, {
    String? error,
  }) {
    // Initialize controller with current real-time price if empty
    if (controller.text.isEmpty) {
      final digits = _getDecimalDigitsForSymbol(widget.position.symbol);
      final currentPrice = _getCurrentRealTimePriceAsDouble();
      controller.text = PrecisionHelper.formatPrice(
        currentPrice,
        decimals: digits,
      );
    }

    return Column(
      children: [
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.88,
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
                          final digits = _getDecimalDigitsForSymbol(
                            widget.position.symbol,
                          );
                          final pipIncrement = _getPipIncrementForSymbol(
                            widget.position.symbol,
                          );
                          final currentValue =
                              double.tryParse(controller.text) ?? defaultValue;
                          if (currentValue > pipIncrement) {
                            final newValue = currentValue - pipIncrement;
                            controller.text = PrecisionHelper.formatPrice(
                              newValue,
                              decimals: digits,
                            );
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
                          final digits = _getDecimalDigitsForSymbol(
                            widget.position.symbol,
                          );
                          final pipIncrement = _getPipIncrementForSymbol(
                            widget.position.symbol,
                          );
                          final currentValue =
                              double.tryParse(controller.text) ?? defaultValue;
                          final newValue = currentValue + pipIncrement;
                          controller.text = PrecisionHelper.formatPrice(
                            newValue,
                            decimals: digits,
                          );
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
            // Container(
            //   width: 96.w,
            //   height: 48.h,
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(8.r),
            //     border: Border.all(color: AppColors.border),
            //   ),
            //   alignment: Alignment.center,
            //   child: Text(
            //     'Points',
            //     style: AppTextStyles.label.copyWith(
            //       fontSize: 12.sp,
            //       fontWeight: FontWeight.w500,
            //       color: AppColors.textGrey,
            //     ),
            //   ),
            // ),
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
        // Text(
        //   '68 points | Profit +4.08 USD | +0.08% of balance',
        //   style: AppTextStyles.label.copyWith(
        //     fontSize: 12.sp,
        //     color: AppColors.textGrey,
        //   ),
        // ),
      ],
    );
  }

  // Bottom action buttons
  Widget _buildSimpleButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          if (selectedTab == 0) ...[
            // Discard Button
            Expanded(
              child: SizedBox(
                height: 44.h,
                child: OutlinedButton(
                  onPressed: () {
                    Get.back();
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
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Confirm Button
            Expanded(
              child: SizedBox(
                height: 44.h,
                child: OutlinedButton(
                  onPressed:
                      (_isOrderValid() && !isProcessingEdit)
                          ? _modifyOrder
                          : null,
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
                  child:
                      isProcessingEdit
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ButtonLoadingWidget(
                                size: 16.0,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Processing...',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.whiteColor,
                                ),
                              ),
                            ],
                          )
                          : Text(
                            'Confirm',
                            style: AppTextStyles.label.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.whiteColor,
                            ),
                          ),
                ),
              ),
            ),
          ],

          if (selectedTab == 1) ...[
            Expanded(
              child: SizedBox(
                height: 44.h,
                child: OutlinedButton(
                  onPressed:
                      (isProcessingPartialClose || volumeError != null)
                          ? null
                          : _handlePartialClose,
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        (isProcessingPartialClose || volumeError != null)
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child:
                      isProcessingPartialClose
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ButtonLoadingWidget(
                                size: 16.0,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Processing...',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.whiteColor,
                                ),
                              ),
                            ],
                          )
                          : Text(
                            'Close ${partialCloseVolume.toStringAsFixed(2)} lots',
                            style: AppTextStyles.label.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.whiteColor,
                            ),
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

  void _calculatePartialCloseProfit() {
    // Calculate profit from partial close based on current price vs entry price
    final entryPrice = double.tryParse(widget.position.entryPrice) ?? 0.0;
    final currentPrice = _getCurrentPrice();
    final profitPerLot =
        widget.position.action.toLowerCase() == 'buy'
            ? currentPrice - entryPrice
            : entryPrice - currentPrice;

    profitFromPartialClose = profitPerLot * partialCloseVolume;
  }

  void _validateAndUpdateVolume(String value) {
    setState(() {
      volumeError = null;

      if (value.isEmpty) {
        volumeError = 'Volume is required';
        return;
      }

      final volume = double.tryParse(value);
      if (volume == null) {
        volumeError = 'Please enter a valid number';
        return;
      }

      if (volume <= 0) {
        volumeError = 'Volume must be greater than 0';
        return;
      }

      if (volume > totalVolume) {
        volumeError =
            'Volume cannot exceed total volume (${totalVolume.toStringAsFixed(2)})';
        return;
      }

      if (volume < 0.01) {
        volumeError = 'Minimum volume is 0.01';
        return;
      }

      // Update volume and recalculate
      partialCloseVolume = volume;
      remainingVolume = totalVolume - partialCloseVolume;
      _calculatePartialCloseProfit();
    });
  }

  double _getCurrentPrice() {
    if (currentSymbol == null) return 0.0;

    final priceData = chartSocketController.getCurrentPrice();
    if (priceData != null && priceData['symbol'] == currentSymbol) {
      return widget.position.action.toLowerCase() == 'buy'
          ? priceData['bid'] ?? 0.0
          : priceData['ask'] ?? 0.0;
    }

    // Fallback to entry price if no real-time data
    return double.tryParse(widget.position.entryPrice) ?? 0.0;
  }

  String _getCurrentRealTimePrice() {
    // Get real-time price from socket data
    if (realTimePriceData != null) {
      final socketSymbol = realTimePriceData!['symbol']?.toString() ?? '';
      final originalSymbol = currentSymbol ?? '';

      // Check if symbols match (with or without .c suffix)
      bool symbolsMatch =
          socketSymbol == originalSymbol ||
          socketSymbol == '$originalSymbol.c' ||
          socketSymbol.replaceAll('.c', '') == originalSymbol;

      if (symbolsMatch) {
        final bid = realTimePriceData!['bid']?.toString() ?? '0';
        final ask = realTimePriceData!['ask']?.toString() ?? '0';

        // Return the appropriate price based on position action
        if (widget.position.action.toLowerCase() == 'buy') {
          return ask;
        } else {
          return bid;
        }
      }
    }

    // Fallback to current price from position

    return widget.position.currentPrice;
  }

  bool _isRealTimeDataActive() {
    if (realTimePriceData != null) {
      final socketSymbol = realTimePriceData!['symbol']?.toString() ?? '';
      final originalSymbol = currentSymbol ?? '';

      // Check if symbols match (with or without .c suffix)
      return socketSymbol == originalSymbol ||
          socketSymbol == '$originalSymbol.c' ||
          socketSymbol.replaceAll('.c', '') == originalSymbol;
    }
    return false;
  }

  double _getCurrentRealTimePriceAsDouble() {
    if (realTimePriceData != null) {
      final socketSymbol = realTimePriceData!['symbol']?.toString() ?? '';
      final originalSymbol = currentSymbol ?? '';

      // Check if symbols match (with or without .c suffix)
      bool symbolsMatch =
          socketSymbol == originalSymbol ||
          socketSymbol == '$originalSymbol.c' ||
          socketSymbol.replaceAll('.c', '') == originalSymbol;

      if (symbolsMatch) {
        final bid =
            double.tryParse(realTimePriceData!['bid']?.toString() ?? '0') ??
            0.0;
        final ask =
            double.tryParse(realTimePriceData!['ask']?.toString() ?? '0') ??
            0.0;

        // Return the appropriate price based on position action
        if (widget.position.action.toLowerCase() == 'buy') {
          return ask;
        } else {
          return bid;
        }
      }
    }

    // Fallback to current price from position
    return double.tryParse(widget.position.currentPrice) ?? 0.0;
  }

  Future<void> _handlePartialClose() async {
    if (isProcessingPartialClose) return;

    setState(() {
      isProcessingPartialClose = true;
    });

    try {
      // Get account controller for MT5 account
      final accountController = Get.find<AccountController>();
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

      // Get trading controller
      final tradingController = Get.find<TradingController>();

      // Call the closePositionById method from trading controller
      final success = await tradingController.closePositionById(
        mt5Account: activeAccount.metaAccountNumber,
        positionId: positionId,
        volume: partialCloseVolume, // Partial close volume
      );

      // Navigate back on success (no toast)
      if (success) {
        Get.back();
      }
    } catch (e) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Failed to close position: $e',
      );
    } finally {
      setState(() {
        isProcessingPartialClose = false;
      });
    }
  }
}
