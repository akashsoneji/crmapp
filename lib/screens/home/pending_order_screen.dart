import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/trading_controller.dart';
import 'package:crm_app/controllers/chart_socket_controller.dart';
import 'package:crm_app/controllers/account_controller.dart';
import 'package:crm_app/widgets/app_switch_tile.dart';
import 'package:crm_app/widgets/app_svg_back_button.dart';
import 'package:crm_app/widgets/chart_inapp_webview.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/utils/precision_helper.dart';
import 'package:crm_app/models/order_types.dart';
import 'package:crm_app/services/trading_websocket_service.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/services/symbol_details_cache_service.dart';
import 'package:crm_app/models/mt5_account.dart';
import 'pending_order_content.dart';
import 'dart:async';

class PendingOrderScreen extends StatefulWidget {
  final String? symbol;
  final Function(int?)?
  onNavigateToTrade; // Optional tab parameter: null = Market (0), or specify tab index

  const PendingOrderScreen({super.key, this.symbol, this.onNavigateToTrade});

  @override
  State<PendingOrderScreen> createState() => _PendingOrderScreenState();
}

class _PendingOrderScreenState extends State<PendingOrderScreen> {
  // Controllers
  late final ChartSocketController chartSocketController;
  late final AccountController accountController;
  late final TradingController tradingController;

  // Order type selection (0: Sell Limit/Sell Stop, 1: Buy Limit/Buy Stop)
  // Default to 1 (Buy Limit) to match dropdown default
  final ValueNotifier<int> _selectedPendingOrderType = ValueNotifier(1);

  // Selected order type from dropdown (Buy Limit, Sell Limit, Buy Stop, Sell Stop)
  final ValueNotifier<String> _selectedOrderType = ValueNotifier('Buy Limit');

  // Price and distance
  final ValueNotifier<double> _limitPrice = ValueNotifier(1.15505);
  final ValueNotifier<double> _openPrice = ValueNotifier(1.15505);
  final ValueNotifier<double> _distance = ValueNotifier(0.0);

  // Toggle states
  final ValueNotifier<bool> _whenPriceIsEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _takeProfitEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _stopLossEnabled = ValueNotifier(false);

  // TP/SL prices
  final ValueNotifier<double> _takeProfitPrice = ValueNotifier(0.0);
  final ValueNotifier<double> _stopLossPrice = ValueNotifier(0.0);

  // Text controllers
  late TextEditingController _takeProfitController;
  late TextEditingController _stopLossController;
  late TextEditingController _limitPriceController;
  late TextEditingController _openPriceController;

  // Chart toggle
  bool showChart = false;

  // Selected symbol
  String selectedSymbol = 'EURUSD';

  // Used for chart backend feed mapping (`datafeed_symbol`).
  // Resolved via SymbolDetailsCacheService for the active account.
  String _datafeedSymbolForSelected = '';
  String _lastDatafeedLookupKey = '';
  bool _isResolvingDatafeedSymbol = false;

  // Listen for active account changes so chart mapping refreshes.
  Worker? _accountWorker;

  // Volume
  double volume = 0.01;

  // Stream subscription
  StreamSubscription<Map<String, dynamic>>? _priceStreamSubscription;

  // Loading state to prevent multiple clicks
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    chartSocketController = Get.find<ChartSocketController>();
    accountController = Get.find<AccountController>();
    tradingController = Get.find<TradingController>();

    // Initialize text controllers
    _takeProfitController = TextEditingController();
    _stopLossController = TextEditingController();
    _limitPriceController = TextEditingController();
    _openPriceController = TextEditingController();

    // Set symbol
    if (widget.symbol != null) {
      selectedSymbol = widget.symbol!;
      chartSocketController.changeSymbol(selectedSymbol);
    } else {
      // Try to get current symbol, default to EURUSD
      final currentSymbol = chartSocketController.currentSymbol.value;
      if (currentSymbol.isNotEmpty) {
        selectedSymbol = currentSymbol;
      }
    }

    // Initialize prices from chart socket
    _initializePrices();

    // Listen to price updates
    _listenToPriceUpdates();

    // When user switches MT5 account, the mapping for `datafeed_symbol`
    // may change. Clear it so the chart resolves it again.
    _accountWorker = ever<MT5Account?>(accountController.activeMT5AccountRx, (
      _,
    ) {
      if (!mounted) return;
      setState(() {
        _datafeedSymbolForSelected = '';
        _lastDatafeedLookupKey = '';
      });
    });
  }

  void _initializePrices() {
    final bid = chartSocketController.getBidPrice() ?? 1.15505;
    final ask = chartSocketController.getAskPrice() ?? 1.15510;

    // Set initial prices based on selected order type
    if (_selectedPendingOrderType.value == 0) {
      // Sell Limit - use bid price
      _limitPrice.value = bid;
      _openPrice.value = bid;
    } else {
      // Buy Limit - use ask price
      _limitPrice.value = ask;
      _openPrice.value = ask;
    }

    _limitPriceController.text = _limitPrice.value.toString();
    _openPriceController.text = _openPrice.value.toString();
  }

  void _listenToPriceUpdates() {
    _priceStreamSubscription = chartSocketController.priceStream.listen((
      priceData,
    ) {
      if (mounted) {
        final bid = chartSocketController.getBidPrice();
        final ask = chartSocketController.getAskPrice();

        if (bid != null && ask != null) {
          // Update prices based on selected order type
          if (_selectedPendingOrderType.value == 0) {
            // Sell Limit
            _openPrice.value = bid;
          } else {
            // Buy Limit
            _openPrice.value = ask;
          }
        }
      }
    });
  }

  Future<void> _placePendingOrder() async {
    // Prevent multiple clicks - set loading state immediately
    if (_isPlacingOrder) return;

    // Silently clamp volume to account limits before placing order.
    // User requested 0.01 min lot floor.
    final minLot = 0.01;
    final maxLot = accountController.activeMT5Account?.maxLotSize ?? 100.0;
    volume = volume.clamp(minLot, maxLot);

    setState(() {
      _isPlacingOrder = true;
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

      // Set current symbol
      tradingController.setCurrentSymbol(selectedSymbol);

      // Determine order type from dropdown selection
      OrderType orderType;
      final selectedOrderTypeStr = _selectedOrderType.value;

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
          // Fallback to Buy Limit if somehow invalid
          orderType = OrderType.buyLimit;
          break;
      }

      // Get decimal digits from price data
      final priceData = chartSocketController.getCurrentPrice();
      final decimals =
          priceData != null && (priceData.containsKey('digits') || priceData.containsKey('Digits'))
              ? (int.tryParse((priceData['digits'] ?? priceData['Digits']).toString()) ?? 5)
              : 5;

      // Format values properly
      final rawVolumeStr = volume.toString(); // e.g. "0.1", "0.001", "1.0"
      final dotIndex = rawVolumeStr.indexOf('.');
      final actualDecimals =
          dotIndex == -1 ? 0 : rawVolumeStr.length - dotIndex - 1;
      final volumeDecimals = actualDecimals < 2 ? 2 : actualDecimals;
      final volumeStr = volume.toStringAsFixed(volumeDecimals);

      final limitPriceControllerValue = _limitPriceController.text.trim();
      final limitPriceFromController =
          limitPriceControllerValue.isNotEmpty
              ? double.tryParse(limitPriceControllerValue)
              : null;

      // All dropdown order types require a price
      final requiresPrice = true;

      final price =
          requiresPrice
              ? PrecisionHelper.formatPrice(
                PrecisionHelper.parseDouble(
                  orderType.isStopLimit
                      ? (_openPriceController.text.isNotEmpty
                          ? _openPriceController.text
                          : _openPrice.value.toString())
                      : (limitPriceFromController != null &&
                          limitPriceFromController > 0)
                      ? limitPriceControllerValue
                      : _limitPrice.value.toString(),
                  decimals: decimals,
                ),
                decimals: decimals,
              )
              : null;

      final stopLimitPrice =
          orderType.isStopLimit
              ? PrecisionHelper.formatPrice(
                PrecisionHelper.parseDouble(
                  (limitPriceFromController != null &&
                          limitPriceFromController > 0)
                      ? limitPriceControllerValue
                      : _limitPrice.value.toString(),
                  decimals: decimals,
                ),
                decimals: decimals,
              )
              : null;

      final takeProfit =
          _takeProfitEnabled.value
              ? PrecisionHelper.formatPrice(
                PrecisionHelper.parseDouble(
                  _takeProfitPrice.value.toString(),
                  decimals: decimals,
                ),
                decimals: decimals,
              )
              : null;

      final stopLoss =
          _stopLossEnabled.value
              ? PrecisionHelper.formatPrice(
                PrecisionHelper.parseDouble(
                  _stopLossPrice.value.toString(),
                  decimals: decimals,
                ),
                decimals: decimals,
              )
              : null;

      // Place the order using TradingController
      final success = await tradingController.placeTradeOrder(
        symbol: selectedSymbol,
        volume: volumeStr,
        orderType: orderType,
        price: price,
        takeProfit: takeProfit,
        stopLoss: stopLoss,
        stopLimitPrice: stopLimitPrice,
        mt5Account: activeAccount.metaAccountNumber,
      );

      if (success) {
        // Store the navigation callback before closing the screen
        final navigateCallback = widget.onNavigateToTrade;

        // Close the pending order screen first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          print('GO BACKKKKKKKKKKK');
          Get.back(closeOverlays: true);
        }

        // Construct minimal order data from available context
        // Since TradingController.placeTradeOrder() only returns boolean,
        // we construct order data from the placement context
        final orderData = {
          'status': true,
          'message': 'Order placed successfully',
          'data': {
            'order_id': null, // Will be populated by WebSocket
            'position_id': null, // Will be populated by WebSocket
            'price': price,
          },
        };

        // Navigate to order confirmation screen with tab index 1 (Pending tab)
        Get.toNamed(
          Routes.ORDER_CONFIRMATION,
          arguments: {
            'orderData': orderData,
            'symbol': selectedSymbol,
            'orderType': orderType.value.toString(),
            'volume': volume,
            'price': price != null ? double.tryParse(price) : null,
            'executionPrice': price,
            'positionId': null,
            'orderId': null,
            'tabIndex': 1, // Pending tab
            'onNavigateToTrade': navigateCallback,
            'isPlacing': false,
          },
        );

        // After 30ms, navigate to trade screen with Pending tab
        await Future.delayed(const Duration(milliseconds: 30));

        if (navigateCallback != null) {
          // Pass tab index 1 (Pending) to show the newly placed order
          navigateCallback(1);
        }

        // Pre-connect WebSocket in background (non-blocking, fire and forget)
        // This ensures instant pending order updates when user switches to Pending tab
        if (Get.isRegistered<TradingWebSocketService>()) {
          final wsService = Get.find<TradingWebSocketService>();
          wsService.ensurePendingOrdersConnection().catchError((e) {
            if (kDebugMode) {
              print(
                'Pending Order Screen: Error ensuring pending orders connection: $e',
              );
            }
          });
        }

        // Return immediately
        return;
      } else {
        CustomToastService.showError(
          title: 'Error',
          message:
              tradingController.errorMessage.isNotEmpty
                  ? tradingController.errorMessage
                  : 'Failed to place order',
        );
      }
    } catch (e) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Failed to place order: $e',
      );
    } finally {
      // Always re-enable button after order placement completes
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _priceStreamSubscription?.cancel();
    _accountWorker?.dispose();
    _takeProfitController.dispose();
    _stopLossController.dispose();
    _limitPriceController.dispose();
    _openPriceController.dispose();
    _selectedPendingOrderType.dispose();
    _selectedOrderType.dispose();
    _limitPrice.dispose();
    _openPrice.dispose();
    _distance.dispose();
    _whenPriceIsEnabled.dispose();
    _takeProfitEnabled.dispose();
    _stopLossEnabled.dispose();
    _takeProfitPrice.dispose();
    _stopLossPrice.dispose();
    super.dispose();
  }

  /// Get the flag SVG path based on the instrument symbol
  String _getFlagPath(String symbol) {
    String cleanSymbol =
        symbol.contains('.')
            ? symbol.substring(0, symbol.lastIndexOf('.'))
            : symbol;
    return 'assets/svg/flags/${cleanSymbol.toLowerCase()}.svg';
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

  /// Build flag icon widget with error handling
  Widget _buildFlagIcon(String symbol, {double? size}) {
    final flagSize = size ?? 24.h;
    final containerSize = flagSize + 16.h;
    final iconSize = flagSize;
    final flagPath = _getFlagPath(symbol);

    return FutureBuilder<String?>(
      future: _checkAssetExists(flagPath),
      builder: (context, snapshot) {
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
        return _buildFallbackFlag(flagSize, containerSize, iconSize);
      },
    );
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
                  color: AppColors.border,
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

  // Helper method to get symbol without .c suffix
  String get _displaySymbol => selectedSymbol.replaceFirst('.c', '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 72.h,
        centerTitle: false,
        leading: AppSvgBackButton(
          onPressed: () => Get.back(closeOverlays: true),
          iconWidth: 30.w,
          iconHeight: 30.h,
        ),
        //we give extrawidth
        titleSpacing: 0,
        title: ValueListenableBuilder<String>(
          valueListenable: _selectedOrderType,
          builder: (context, orderType, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildFlagIcon(selectedSymbol, size: 20.h),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Order',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '$orderType $_displaySymbol',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
            );
          },
        ),
        actions: [SizedBox(width: 16.w)],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Current Prices (Bid/Ask) - Above Chart
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: _buildCurrentPrices(),
                ),

                // Chart Section
                _buildChartSection(),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: PendingOrderContent(
                      selectedPendingOrderType: _selectedPendingOrderType,
                      selectedOrderType: _selectedOrderType,
                      limitPrice: _limitPrice,
                      openPrice: _openPrice,
                      distance: _distance,
                      whenPriceIsEnabled: _whenPriceIsEnabled,
                      takeProfitEnabled: _takeProfitEnabled,
                      stopLossEnabled: _stopLossEnabled,
                      takeProfitPrice: _takeProfitPrice,
                      stopLossPrice: _stopLossPrice,
                      takeProfitController: _takeProfitController,
                      stopLossController: _stopLossController,
                      limitPriceController: _limitPriceController,
                      openPriceController: _openPriceController,
                      onPlaceOrder: _placePendingOrder,
                      selectedSymbol: selectedSymbol,
                      isLoading: _isPlacingOrder,
                      onVolumeChanged: (newVolume) {
                        setState(() {
                          volume = newVolume;
                        });
                      },
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

  Widget _buildCurrentPrices() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
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

  Widget _buildChartSection() {
    // Start (non-blocking) resolution of `datafeed_symbol` for the active account.
    _resolveDatafeedSymbolIfNeeded();

    return Container(
      height: showChart ? MediaQuery.of(context).size.height * 0.4 : 64.h,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.border),
              ),
              child: AppSwitchTile(
                title: 'Chart',
                value: showChart,
                onChanged: (value) {
                  setState(() {
                    showChart = value;
                  });
                },
              ),
            ),
          ),
          // Chart WebView (only when chart is enabled)
          if (showChart)
            Expanded(
              child: ChartInAppWebView(
                key: ValueKey(
                  '${selectedSymbol}|${accountController.activeMT5Account?.metaAccountNumber ?? ''}|${_datafeedSymbolForSelected.isNotEmpty ? _datafeedSymbolForSelected : selectedSymbol}',
                ), // Force update when symbol/account changes
                symbol:
                    _datafeedSymbolForSelected.isNotEmpty
                        ? _datafeedSymbolForSelected
                        : _removeSymbolSuffixForDisplay(selectedSymbol),
                url: _buildChartUrlWithDatafeedSymbol(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PendingOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent passes a new symbol, reset mapping so we re-resolve for chart.
    if (widget.symbol != null && widget.symbol != oldWidget.symbol) {
      setState(() {
        selectedSymbol = widget.symbol!;
        _datafeedSymbolForSelected = '';
        _lastDatafeedLookupKey = '';
      });
      // Also update socket symbol used for price calculations/orders.
      chartSocketController.changeSymbol(selectedSymbol);
    }
  }

  /// Resolve `datafeed_symbol` in background for the active account.
  /// This must be non-blocking and safe if symbol/account changes quickly.
  void _resolveDatafeedSymbolIfNeeded() {
    if (!showChart) return;
    if (selectedSymbol.isEmpty) return;

    final accountNumber = accountController.activeMT5Account?.metaAccountNumber;
    if (accountNumber == null) return;

    final accountNumberStr = accountNumber.toString();
    final lookupKey = '$accountNumberStr|$selectedSymbol';

    if (_isResolvingDatafeedSymbol || lookupKey == _lastDatafeedLookupKey) {
      return;
    }

    _lastDatafeedLookupKey = lookupKey;
    _datafeedSymbolForSelected = '';
    _isResolvingDatafeedSymbol = true;

    Future(() async {
      final ok = await SymbolDetailsCacheService.ensureCached(accountNumberStr);
      if (!mounted) return;

      if (!ok) {
        if (lookupKey != _lastDatafeedLookupKey) return;
        setState(() {
          _datafeedSymbolForSelected = '';
          _isResolvingDatafeedSymbol = false;
        });
        return;
      }

      final details = await SymbolDetailsCacheService.getSymbolDetails(
        selectedSymbol,
        accountNumberStr,
      );
      if (!mounted) return;

      final resolved = (details?['datafeed_symbol'] ?? '').toString().trim();

      if (lookupKey != _lastDatafeedLookupKey) return;

      setState(() {
        _datafeedSymbolForSelected = resolved.isNotEmpty ? resolved : '';
        _isResolvingDatafeedSymbol = false;
      });
    });
  }

  String _removeSymbolSuffixForDisplay(String symbol) {
    // If symbol has suffix (contains '.'), remove it for display.
    // If symbol has no suffix, return as-is.
    if (symbol.contains('.')) {
      return symbol.substring(0, symbol.lastIndexOf('.'));
    }
    return symbol;
  }

  String _buildChartUrlWithDatafeedSymbol() {
    final displaySymbol = _removeSymbolSuffixForDisplay(selectedSymbol);
    final effectiveDatafeedSymbol =
        _datafeedSymbolForSelected.isNotEmpty
            ? _datafeedSymbolForSelected
            : displaySymbol;

    return '${FlavorConfig.instance.chartBaseUrl}/mobile-chart?symbol=$effectiveDatafeedSymbol&theme=${AppColors.chartTheme}';
  }
}
