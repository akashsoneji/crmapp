import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/controllers/chart_socket_controller.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/widgets/fixed_size_webview.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/utils/precision_helper.dart';
import 'package:pipze/models/order_types.dart';
import 'package:pipze/services/trading_websocket_service.dart';
import 'package:pipze/routes/app_pages.dart';
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

  // Order type selection (0: Sell Limit, 1: Buy Limit)
  final ValueNotifier<int> _selectedPendingOrderType = ValueNotifier(1);

  // Price and distance
  final ValueNotifier<double> _limitPrice = ValueNotifier(1.15505);
  final ValueNotifier<double> _openPrice = ValueNotifier(1.15505);
  final ValueNotifier<double> _distance = ValueNotifier(0.0);

  // Toggle states
  final ValueNotifier<bool> _whenPriceIsEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _takeProfitEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _stopLossEnabled = ValueNotifier(false);

  // TP/SL prices
  final ValueNotifier<double> _takeProfitPrice = ValueNotifier(0.0);
  final ValueNotifier<double> _stopLossPrice = ValueNotifier(0.0);

  // Text controllers
  late TextEditingController _takeProfitController;
  late TextEditingController _stopLossController;
  late TextEditingController _limitPriceController;

  // Chart toggle
  bool showChart = false;

  // Selected symbol
  String selectedSymbol = 'EURUSD';

  // Volume
  double volume = 0.01;

  // Stream subscription
  StreamSubscription<Map<String, dynamic>>? _priceStreamSubscription;

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

      // Determine order type
      OrderType orderType;
      if (_whenPriceIsEnabled.value) {
        // Conditional orders (Buy Limit/Sell Limit)
        if (_selectedPendingOrderType.value == 0) {
          orderType = OrderType.sellLimit; // Sell Limit
        } else {
          orderType = OrderType.buyLimit; // Buy Limit
        }
      } else {
        // Market orders
        if (_selectedPendingOrderType.value == 0) {
          orderType = OrderType.sellMarket; // Sell Market
        } else {
          orderType = OrderType.buyMarket; // Buy Market
        }
      }

      // Get decimal digits from price data
      final priceData = chartSocketController.getCurrentPrice();
      final decimals =
          priceData != null && priceData.containsKey('digits')
              ? (int.tryParse(priceData['digits'].toString()) ?? 5)
              : 5;

      // Format values properly
      final volumeStr = volume.toString();

      final limitPriceControllerValue = _limitPriceController.text.trim();
      final limitPriceFromController =
          limitPriceControllerValue.isNotEmpty
              ? double.tryParse(limitPriceControllerValue)
              : null;

      final price =
          _whenPriceIsEnabled.value
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
        mt5Account: activeAccount.metaAccountNumber,
      );

      if (success) {
        // Store the navigation callback before closing the screen
        final navigateCallback = widget.onNavigateToTrade;

        // Close the pending order screen first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Get.back();
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
    }
  }

  @override
  void dispose() {
    _priceStreamSubscription?.cancel();
    _takeProfitController.dispose();
    _stopLossController.dispose();
    _limitPriceController.dispose();
    _selectedPendingOrderType.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Pending order',
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
            // Chart Section with Toggle
            // _buildChartSection(),

            // Divider
            Divider(height: 1, color: AppColors.border),

            // Pending Order Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: PendingOrderContent(
                  selectedPendingOrderType: _selectedPendingOrderType,
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
                  onPlaceOrder: _placePendingOrder,
                  selectedSymbol: selectedSymbol,
                  onVolumeChanged: (newVolume) {
                    setState(() {
                      volume = newVolume;
                    });
                  },
                ),
              ),
            ),
          ],
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
                symbol: selectedSymbol.replaceFirst('.c', ''),
                url: '',
              ),
            ),
        ],
      ),
    );
  }
}
