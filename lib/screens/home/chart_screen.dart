import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/controllers/chart_controller.dart';
import 'package:pipze/models/instrument.dart';
import 'package:pipze/models/socket_response.dart';
import 'package:pipze/widgets/fixed_size_webview.dart';

import 'package:intl/intl.dart';
import '../../constants/color.dart';
import '../../constants/text_styles.dart';
import '../../controllers/account_controller.dart';
import '../../controllers/instruments_controller.dart';
import '../../controllers/chart_socket_controller.dart';
import '../../controllers/trading_controller.dart';
import '../../widgets/price_alert_dialog.dart';
import '../../widgets/account_header_widget.dart';
import '../../services/price_alert_service.dart';
import '../../services/price_alert_monitor_service.dart';
import '../../utils/precision_helper.dart';
import '../../models/order_types.dart';
import '../../utils/app_logger.dart';
import 'pending_order_content.dart';

class ChartScreen extends StatefulWidget {
  final Function()? onNavigateToTrade;

  const ChartScreen({super.key, this.onNavigateToTrade});

  // Static method to set symbol from instruments screen
  static void setSelectedSymbol(String symbol) {
    print("🚀 ChartScreen: setSelectedSymbol called with: $symbol");
    try {
      _selectedSymbolNotifier.value = symbol;
      print("🚀 ChartScreen: Symbol successfully set to: $symbol");
    } catch (e) {
      print("🚨 ChartScreen: Error setting symbol: $e");
    }
  }

  // Static ValueNotifier to handle symbol changes
  static final ValueNotifier<String> _selectedSymbolNotifier = ValueNotifier(
    'EURUSD',
  );

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> with WidgetsBindingObserver {
  double volume = 0.01;
  String selectedTimeframe = '15s';
  String selectedChartType = 'Candlestick';
  String selectedSymbol =
      'XAUUSD.c'; // Default symbol, will be updated from socket data

  bool useTradingView = true;
  final ValueNotifier<String> selectedPriceType = ValueNotifier('Asset Price');

  late TextEditingController _volumeController;
  late TextEditingController _takeProfitController;
  late TextEditingController _stopLossController;
  late TextEditingController _limitPriceController;
  late TextEditingController distanceController;
  VoidCallback? _distanceListener;

  // Get controllers
  final AccountController accountController = Get.find<AccountController>();
  final InstrumentsController instrumentsController =
      Get.find<InstrumentsController>();
  late ChartSocketController chartSocketController;
  late ChartController chartController;

  // Mock chart data for now
  List<Map<String, dynamic>> _chartData = [];
  Map<String, dynamic>? realTimePrice;
  bool isLoading = true;
  String? errorMessage;
  bool _isModalOpen = false; // Flag to track if modal is open

  // Trading Order Bottom Sheet State with ValueNotifier
  final ValueNotifier<int> _selectedOrderTab = ValueNotifier(
    0,
  ); // 0: Market Order, 1: Pending Order
  final ValueNotifier<int> _selectedPendingOrderType = ValueNotifier(
    1,
  ); // 0: Sell Limit, 1: Buy Limit

  final ValueNotifier<double> _openPrice = ValueNotifier(1.15505);
  final ValueNotifier<double> _distance = ValueNotifier(40.0);
  final ValueNotifier<bool> _takeProfitEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _stopLossEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _advanceSettingsEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _trailingStopEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _orderExpirationEnabled = ValueNotifier(false);
  final ValueNotifier<DateTime> _orderExpirationDate = ValueNotifier(
    DateTime.now(),
  );
  final ValueNotifier<DateTime> _orderExpirationTime = ValueNotifier(
    DateTime.now(),
  );
  final ValueNotifier<bool> _breakEvenEnabled = ValueNotifier(false);
  final ValueNotifier<double> _takeProfitPrice = ValueNotifier(1.15550);
  final ValueNotifier<double> _stopLossPrice = ValueNotifier(1.15448);
  final ValueNotifier<bool> _whenPriceIsEnabled = ValueNotifier(false);

  // Real-time price validation
  final ValueNotifier<String?> _limitPriceError = ValueNotifier(null);
  final ValueNotifier<String?> _stopLossError = ValueNotifier(null);
  final ValueNotifier<String?> _takeProfitError = ValueNotifier(null);
  final ValueNotifier<double> _limitPrice = ValueNotifier(1.15505);

  // Current market prices
  double? currentBidPrice;
  double? currentAskPrice;

  @override
  void initState() {
    super.initState();

    try {
      print('🚀 ChartScreen: Initializing...');

      // Add lifecycle observer
      WidgetsBinding.instance.addObserver(this);

      // Initialize chart socket controller (like instrument controller)
      if (Get.isRegistered<ChartSocketController>()) {
        chartSocketController = Get.find<ChartSocketController>();
        print('🚀 ChartScreen: Using existing ChartSocketController');
      } else {
        chartSocketController = Get.put(ChartSocketController());
        print('🚀 ChartScreen: Created new ChartSocketController');
      }

      // Initialize chart controller (like instrument controller)
      if (Get.isRegistered<ChartController>()) {
        chartController = Get.find<ChartController>();
        print('🚀 ChartScreen: Using existing ChartController');
      } else {
        chartController = Get.put(ChartController());
        print('🚀 ChartScreen: Created new ChartController');
      }

      // Listen to symbol changes from instruments screen
      ChartScreen._selectedSymbolNotifier.addListener(
        _onSymbolChangedFromInstruments,
      );

      // Listen to price stream updates
      _listenToPriceUpdates();

      // Initialize with first available instrument from socket data
      _initializeWithFirstInstrument();

      _volumeController = TextEditingController(
        text: PrecisionHelper.formatVolume(volume),
      );
      _takeProfitController = TextEditingController(
        text: PrecisionHelper.formatPrice(_takeProfitPrice.value),
      );
      _stopLossController = TextEditingController(
        text: PrecisionHelper.formatPrice(_stopLossPrice.value),
      );
      _limitPriceController = TextEditingController(
        text: PrecisionHelper.formatPrice(_limitPrice.value, decimals: 5),
      );
      distanceController = TextEditingController(
        text: PrecisionHelper.formatPrice(_distance.value),
      );

      // Add listener to sync distance controller with value notifier
      _distanceListener = () {
        if (distanceController.text !=
            PrecisionHelper.formatPrice(_distance.value)) {
          distanceController.text = PrecisionHelper.formatPrice(
            _distance.value,
          );
        }
      };
      _distance.addListener(_distanceListener!);

      _loadMockData();
      _initializePriceAlertService();

      // Initialize real-time price data
      _initializePrices();
      _setupPriceListener();
    } catch (e) {
      print('🚀 ChartScreen: Error in initState: $e');
      // Fallback initialization
      _volumeController = TextEditingController(text: '0.02');
      _takeProfitController = TextEditingController(text: '0.00');
      _stopLossController = TextEditingController(text: '0.00');
      _limitPriceController = TextEditingController(text: '0.00000');
      distanceController = TextEditingController(text: '0.00');

      // Set default symbol
      setState(() {
        selectedSymbol = 'EURUSD.c';
      });

      // Initialize socket with default symbol
      if (Get.isRegistered<ChartSocketController>()) {
        chartSocketController = Get.find<ChartSocketController>();
        chartSocketController.initializeSocketForSymbol(selectedSymbol);
      }
    }
  }

  // Initialize real-time prices
  void _initializePrices() {
    final priceData = chartSocketController.getCurrentPrice();
    if (priceData != null) {
      currentBidPrice = chartSocketController.getBidPrice();
      currentAskPrice = chartSocketController.getAskPrice();

      // Initialize limit price based on current order type
      if (_selectedPendingOrderType.value == 0) {
        // Sell Limit
        _limitPrice.value = currentBidPrice ?? 1.15498;
      } else {
        // Buy Limit
        _limitPrice.value = currentAskPrice ?? 1.15514;
      }
    }
  }

  // Setup price listener for real-time updates
  void _setupPriceListener() {
    chartSocketController.priceStream.listen((priceData) {
      if (mounted) {
        setState(() {
          currentBidPrice = chartSocketController.getBidPrice();
          currentAskPrice = chartSocketController.getAskPrice();
          _validateLimitPrice();
          _validateStopLoss();
          _validateTakeProfit();
        });
      }
    });
  }

  // Validation methods
  void _validateLimitPrice() {
    final limitPrice = _limitPrice.value;
    final selectedType = _selectedPendingOrderType.value;

    if (selectedType == 0) {
      // Sell Limit
      if (currentBidPrice != null && limitPrice <= currentBidPrice!) {
        _limitPriceError.value =
            'Sell Limit should be above current price ${PrecisionHelper.formatPrice(currentBidPrice!, decimals: 5)}';
      } else {
        _limitPriceError.value = null;
      }
    } else {
      // Buy Limit
      if (currentAskPrice != null && limitPrice >= currentAskPrice!) {
        _limitPriceError.value =
            'Buy Limit should be below current price ${PrecisionHelper.formatPrice(currentAskPrice!, decimals: 5)}';
      } else {
        _limitPriceError.value = null;
      }
    }
  }

  void _validateStopLoss() {
    if (!_stopLossEnabled.value) return;

    final stopLossPrice = _stopLossPrice.value;
    final selectedType = _selectedPendingOrderType.value;

    if (selectedType == 0) {
      // Sell Limit
      if (currentBidPrice != null && stopLossPrice <= currentBidPrice!) {
        _stopLossError.value =
            'Stop Loss should be above current price ${currentBidPrice!.toStringAsFixed(5)}';
      } else {
        _stopLossError.value = null;
      }
    } else {
      // Buy Limit
      if (currentAskPrice != null && stopLossPrice >= currentAskPrice!) {
        _stopLossError.value =
            'Stop Loss should be below current price ${currentAskPrice!.toStringAsFixed(5)}';
      } else {
        _stopLossError.value = null;
      }
    }
  }

  void _validateTakeProfit() {
    if (!_takeProfitEnabled.value) return;

    final takeProfitPrice = _takeProfitPrice.value;
    final selectedType = _selectedPendingOrderType.value;

    if (selectedType == 0) {
      // Sell Limit
      if (currentAskPrice != null && takeProfitPrice >= currentAskPrice!) {
        _takeProfitError.value =
            'Take Profit should be below current price ${currentAskPrice!.toStringAsFixed(5)}';
      } else {
        _takeProfitError.value = null;
      }
    } else {
      // Buy Limit
      if (currentBidPrice != null && takeProfitPrice <= currentBidPrice!) {
        _takeProfitError.value =
            'Take Profit should be above current price ${currentBidPrice!.toStringAsFixed(5)}';
      } else {
        _takeProfitError.value = null;
      }
    }
  }

  // Order placement method
  Future<void> _placePendingOrder() async {
    final activeAccount = accountController.activeMT5Account;
    if (activeAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No active account found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get the trading controller
      final TradingController tradingController = Get.find<TradingController>();

      // Set current symbol and prices
      tradingController.setCurrentSymbol(selectedSymbol);

      // Determine order type based on current selection
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

      // Prepare order parameters
      final volumeStr = volume.toString();
      final price =
          _whenPriceIsEnabled.value ? _limitPrice.value.toString() : null;
      final takeProfit =
          _takeProfitEnabled.value ? _takeProfitPrice.value.toString() : null;
      final stopLoss =
          _stopLossEnabled.value ? _stopLossPrice.value.toString() : null;

      // Log the order attempt
      AppLogger.order('''
Placing Order:
- Symbol: $selectedSymbol
- Type: ${orderType.value}
- Volume: $volumeStr
- Price: ${price ?? 'Market'}
- Take Profit: ${takeProfit ?? 'None'}
- Stop Loss: ${stopLoss ?? 'None'}
- MT5 Account: ${activeAccount.metaAccountNumber}
      ''');

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
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Close the bottom sheet
        Navigator.pop(context);

        // Refresh the chart data
        chartSocketController.forceReconnect();
      } else {
        // Show error message from TradingController
        final errorMessage = tradingController.errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.isNotEmpty ? errorMessage : 'Failed to place order',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Exception in _placePendingOrder: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isPendingOrderValid() {
    _validateLimitPrice();
    _validateStopLoss();
    _validateTakeProfit();

    if (_limitPriceError.value != null) return false;
    if (_stopLossEnabled.value && _stopLossError.value != null) return false;
    if (_takeProfitEnabled.value && _takeProfitError.value != null)
      return false;

    return true;
  }

  void _onSymbolChangedFromInstruments() {
    final newSymbol = ChartScreen._selectedSymbolNotifier.value;
    //dev.log('ChartScreen: Symbol changed from $selectedSymbol to $newSymbol');

    if (newSymbol != selectedSymbol && mounted) {
      //dev.log('🔄 CHART SYMBOL CHANGE PROCESS:');
      //dev.log('🎯 New Symbol: $newSymbol');
      //dev.log('📡 Current Symbol: $selectedSymbol');
      //dev.log(
      // '🔌 Socket Connected: ${chartSocketController.isConnected.value}',
      // );

      setState(() {
        selectedSymbol = newSymbol;
      });

      // Change symbol in socket controller (this will handle disconnect/reconnect)
      _changeChartSymbol(newSymbol);

      //dev.log('ChartScreen: Updated selectedSymbol to $selectedSymbol');
    }
  }

  // Listen to price updates from socket
  void _listenToPriceUpdates() {
    chartSocketController.priceStream.listen((priceData) {
      if (mounted) {
        //dev.log('Chart: Received price update: $priceData');
        setState(() {
          realTimePrice = priceData;
        });
      }
    });
  }

  // Change chart symbol and update socket
  Future<void> _changeChartSymbol(String newSymbol) async {
    try {
      //dev.log('🔄 CHANGING CHART SYMBOL:');
      //dev.log('🎯 New Symbol: $newSymbol');
      //dev.log(
      // '📡 Current Connection: ${chartSocketController.isConnected.value}',
      // );
      //dev.log(
      // '📊 Current Symbol in Controller: ${chartSocketController.currentSymbol.value}',
      // );

      // Use the improved changeSymbol method
      await chartSocketController.changeSymbol(newSymbol);

      //dev.log('✅ Chart symbol changed successfully to $newSymbol');
      //dev.log(
      // '📡 New Connection Status: ${chartSocketController.isConnected.value}',
      // );
      //dev.log(
      // '📊 New Symbol in Controller: ${chartSocketController.currentSymbol.value}',
      // );
    } catch (e) {
      //dev.log('❌ Chart: Error changing symbol: $e');
      //dev.log('🔍 Error details: ${e.toString()}');
    }
  }

  Future<void> _initializePriceAlertService() async {
    try {
      await PriceAlertService().initialize();
      // Initialize the monitoring service
      Get.put(PriceAlertMonitorService());
    } catch (e) {
      print('Failed to initialize price alert service: $e');
    }
  }

  void _loadMockData() {
    // Generate mock chart data
    _chartData = List.generate(50, (index) {
      final date = DateTime.now().subtract(Duration(days: 50 - index));
      final basePrice = 1.1550;
      final randomChange = (index % 10 - 5) * 0.001;
      final open = basePrice + randomChange;
      final close = open + (index % 3 - 1) * 0.0005;
      final high = open > close ? open + 0.002 : close + 0.002;
      final low = open > close ? close - 0.001 : open - 0.001;

      return {
        'date': date,
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': 1000 + (index * 100),
      };
    });

    setState(() {
      isLoading = false;
    });
  }

  void _showPriceAlertDialog() {
    final currentPrice = chartSocketController.getMarketPrice() ?? 1.14252;

    print(
      "Chart: Showing price alert dialog for ${selectedSymbol} at price ${currentPrice}",
    );

    // Hide keyboard first to prevent dialog visibility issues
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true, // Ensure dialog is visible above keyboard
      builder:
          (context) => PriceAlertDialog(
            symbol: selectedSymbol,
            currentPrice: currentPrice,
          ),
    );
  }

  void _showPriceDebugInfo() {
    try {
      final bidPrice = chartSocketController.getBidPrice() ?? 0.0;
      final askPrice = chartSocketController.getAskPrice() ?? 0.0;
      final marketPrice = chartSocketController.getMarketPrice() ?? 0.0;
      final monitorService = Get.find<PriceAlertMonitorService>();
      final status = monitorService.getMonitoringStatus();

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Price Debug Info'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Symbol: $selectedSymbol',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Bid Price (SELL): ${bidPrice.toStringAsFixed(5)}'),
                    Text('Ask Price (BUY): ${askPrice.toStringAsFixed(5)}'),
                    Text(
                      'Market Price (Alert): ${marketPrice.toStringAsFixed(5)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Monitoring Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Active: ${status['isMonitoring']}'),
                    Text('Active Alerts: ${status['activeAlertsCount']}'),
                    SizedBox(height: 16),
                    if (status['alerts'] != null &&
                        (status['alerts'] as List).isNotEmpty) ...[
                      Text(
                        'Active Alerts:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...(status['alerts'] as List).map(
                        (alert) => Padding(
                          padding: EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            '${alert['symbol']} ${alert['condition']} ${alert['targetPrice'].toStringAsFixed(5)}',
                          ),
                        ),
                      ),
                    ] else
                      Text(
                        'No active alerts',
                        style: TextStyle(color: Colors.grey),
                      ),
                    SizedBox(height: 16),
                    Text(
                      'Test Actions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final monitorService =
                                  Get.find<PriceAlertMonitorService>();
                              await monitorService.addTestAlert(
                                selectedSymbol,
                                1.80950,
                                'above',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Test alert added: $selectedSymbol above 1.80950',
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: Text(
                              'Add Test Alert\n(1.80950 above)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final monitorService =
                                  Get.find<PriceAlertMonitorService>();
                              await monitorService.testTriggerAlert(
                                selectedSymbol,
                                marketPrice,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: Text(
                              'Test Trigger\nNow',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final monitorService =
                                  Get.find<PriceAlertMonitorService>();
                              await monitorService.testNotificationSystem();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Test notification sent!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: Text(
                              'Test Notification\nSystem',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final monitorService =
                                  Get.find<PriceAlertMonitorService>();
                              await monitorService.ensureChartSocketConnected(
                                selectedSymbol,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'ChartSocket connection checked!',
                                  ),
                                  backgroundColor: Colors.purple,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                            child: Text(
                              'Fix WebSocket\nConnection',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug info error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testPriceAlert() async {
    try {
      final currentPrice = chartSocketController.getMarketPrice() ?? 1.14252;
      final monitorService = Get.find<PriceAlertMonitorService>();

      // Show current status
      final status = monitorService.getMonitoringStatus();
      print('📊 Current Status: $status');

      // Test trigger alert
      await monitorService.testTriggerAlert(selectedSymbol, currentPrice);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test alert triggered! Check notifications. Current: $selectedSymbol at \$${currentPrice.toStringAsFixed(5)}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print('Error testing price alert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _onSymbolChanged(String newSymbol) {
    print('ChartScreen: _onSymbolChanged called with $newSymbol');
    setState(() {
      selectedSymbol = newSymbol;
    });
    _changeChartSymbol(newSymbol);

    // Update chart socket controller with new symbol
    chartSocketController.changeSymbol(newSymbol);

    print('ChartScreen: Updated selectedSymbol to $selectedSymbol');
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Remove symbol change listener
    ChartScreen._selectedSymbolNotifier.removeListener(
      _onSymbolChangedFromInstruments,
    );

    // Dispose controllers
    _volumeController.dispose();
    _takeProfitController.dispose();
    _stopLossController.dispose();
    _limitPriceController.dispose();
    distanceController.dispose();

    // Remove distance listener
    if (_distanceListener != null) {
      _distance.removeListener(_distanceListener!);
    }

    // Note: Don't delete ChartSocketController here as it might be used elsewhere
    // The controller will be automatically disposed when no longer referenced

    super.dispose();
  }

  // Handle app lifecycle changes (simplified like instrument controller)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        //dev.log('Chart Screen: App resumed - checking socket connection');
        if (!chartSocketController.isConnected.value) {
          //dev.log('Chart Screen: Reconnecting socket on app resume');
          chartSocketController.handleAppRestart();
        }
        break;
      case AppLifecycleState.paused:
        //dev.log('Chart Screen: App paused - socket may disconnect');
        break;
      case AppLifecycleState.detached:
        //dev.log('Chart Screen: App detached - closing socket');
        chartSocketController.resetController();
        break;
      case AppLifecycleState.inactive:
        //dev.log('Chart Screen: App inactive');
        break;
      case AppLifecycleState.hidden:
        //dev.log('Chart Screen: App hidden');
        break;
    }
  }

  // Handle when screen becomes visible (when navigating back to chart screen)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //dev.log(
    // 'Chart Screen: Dependencies changed - checking WebSocket connection',
    // );

    // Ensure WebSocket is connected when screen becomes visible
    if (selectedSymbol.isNotEmpty) {
      chartSocketController.initializeSocketForSymbol(selectedSymbol);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Fixed height
            _buildHeader(context),

            // Chart Area - Responsive height
            Expanded(
              flex:
                  isSmallScreen
                      ? 3
                      : isLargeScreen
                      ? 4
                      : 3,
              child: _buildChartArea(),
            ),

            // Interactive Icons - Fixed height
            _buildVolumeInputScreen(context, true),

            // Trading Controls - Fixed height
            _buildTradingControls(),
            _buildInteractiveIcons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    // Create the symbol selector widget with connection status
    final symbolSelector = GestureDetector(
      onTap: () => _showSymbolSelector(),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8.w : 12.w,
          vertical: isSmallScreen ? 6.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackGround,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Text(
              selectedSymbol.substring(0, selectedSymbol.lastIndexOf(".")),
              style: AppTextStyles.label.copyWith(
                fontSize: isSmallScreen ? 12.sp : 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            // // Chart socket connection status indicator
            // Obx(() {
            //   if (chartSocketController.isReconnecting.value) {
            //     return SizedBox(
            //       width: 12.w,
            //       height: 12.h,
            //       child: CircularProgressIndicator(
            //         strokeWidth: 2,
            //         valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            //       ),
            //     );
            //   } else if (chartSocketController.isConnected.value) {
            //     return Container(
            //       width: 8.w,
            //       height: 8.h,
            //       decoration: BoxDecoration(
            //         color: AppColors.green,
            //         shape: BoxShape.circle,
            //       ),
            //     );
            //   } else {
            //     return GestureDetector(
            //       onTap: () => chartSocketController.manualReconnect(),
            //       child: Container(
            //         width: 8.w,
            //         height: 8.h,
            //         decoration: BoxDecoration(
            //           color: AppColors.red,
            //           shape: BoxShape.circle,
            //         ),
            //       ),
            //     );
            //   }
            // }),
            // SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down,
              size: isSmallScreen ? 14.h : 16.h,
              color: AppColors.textGrey,
            ),
          ],
        ),
      ),
    );

    return AccountHeaderWidget(
      showSearchIcon: false,
      rightWidget: symbolSelector,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12.w : 16.w,
        vertical: isSmallScreen ? 6.h : 8.h,
      ),
    );
  }

  Widget _buildAssetDetails() {
    if (_chartData.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            Text(
              'Loading...',
              style: AppTextStyles.label.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    final latestCandle = _chartData.last;
    final firstCandle = _chartData.first;
    final change = latestCandle['close'] - firstCandle['open'];
    final changePercent = (change / firstCandle['open']) * 100;
    final isPositive = change >= 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Text(
            'Change: ${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            'Low: ${firstCandle['low']?.toStringAsFixed(5) ?? '0.00000'}',
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            'High: ${firstCandle['high']?.toStringAsFixed(5) ?? '0.00000'}',
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          const Spacer(),
          Container(
            width: 20.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: AppColors.textGrey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              size: 14.h,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartArea() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.4, // Responsive height
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,

      // margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: FixedSizeWebView(
        key: ValueKey(selectedSymbol), // Force rebuild when symbol changes
        url:
            'https://my.pipze.com/user/chart/${selectedSymbol.replaceFirst(".c", "")}', // Responsive height
      ),
    );
  }

  // Initialize chart with first available instrument from socket data
  void _initializeWithFirstInstrument() {
    final instrumentsController = Get.find<InstrumentsController>();

    //dev.log('🔵 INITIALIZING CHART WITH FIRST INSTRUMENT:');
    //dev.log(
    // '📊 Available instruments: ${instrumentsController.allInstruments.length}',
    // );
    //dev.log(
    // '📋 Instruments list: ${instrumentsController.allInstruments.map((e) => e.symbol).toList()}',
    // );

    // Wait for instruments data to be available
    if (instrumentsController.allInstruments.isNotEmpty) {
      final firstInstrument = instrumentsController.allInstruments.first;
      //dev.log('🎯 First instrument: ${firstInstrument.symbol}');
      //dev.log('💰 First instrument bid: ${firstInstrument.bid}');
      //dev.log('💰 First instrument ask: ${firstInstrument.ask}');

      setState(() {
        selectedSymbol = firstInstrument.symbol;
      });

      //dev.log('✅ Selected symbol set to: $selectedSymbol');

      // Initialize socket for the first instrument
      //dev.log('🔌 Initializing socket for first instrument: $selectedSymbol');
      chartSocketController.initializeSocketForSymbol(selectedSymbol);
    } else {
      //dev.log('⏳ No instruments available yet, waiting...');
      //dev.log('🔄 Setting up listener for instruments updates...');

      // If no instruments available yet, listen for updates
      ever(instrumentsController.allInstruments, (
        List<ListElement> instruments,
      ) {
        //dev.log(
        // '🔄 Instruments list updated: ${instruments.length} instruments',
        // );
        //dev.log(
        // '📋 New instruments: ${instruments.map((e) => e.symbol).toList()}',
        // );

        if (instruments.isNotEmpty && selectedSymbol == 'EURUSD') {
          final firstInstrument = instruments.first;
          //dev.log(
          // '🎯 Instruments loaded, using first: ${firstInstrument.symbol}',
          // );
          //dev.log('💰 First instrument bid: ${firstInstrument.bid}');
          //dev.log('💰 First instrument ask: ${firstInstrument.ask}');

          setState(() {
            selectedSymbol = firstInstrument.symbol;
          });

          //dev.log('✅ Selected symbol set to: $selectedSymbol');

          // Initialize socket for the first instrument
          //dev.log(
          // '🔌 Initializing socket for first instrument: $selectedSymbol',
          // );
          chartSocketController.initializeSocketForSymbol(selectedSymbol);
        }
      });
    }
  }

  // Helper function to convert ListElement to Instrument format
  List<Instrument> _convertListElementsToInstruments(
    List<ListElement> listElements,
  ) {
    return listElements.map((element) {
      //dev.log(
      // '🔍 Converting ListElement to Instrument element: ${element.ask}',
      // );
      // Get group name for category
      final instrumentsController = Get.find<InstrumentsController>();
      final groupName = instrumentsController.getGroupNameForSymbol(
        element.symbol,
      );

      // Generate flag based on symbol
      // String flag = _getFlagForSymbol(element.symbol);

      // Generate status based on spreadDiff
      String status = element.spreadDiff > 0 ? 'Active' : 'Market closed';

      return Instrument(
        name: element.symbol,
        flag: element.logo,
        status: status,
        bidPrice: element.bid.toStringAsFixed(element.digits),
        askPrice: element.ask.toStringAsFixed(element.digits),
        lowPrice: (element.bid - element.spreadDiff).toStringAsFixed(
          element.digits,
        ),
        highPrice: (element.ask + element.spreadDiff).toStringAsFixed(
          element.digits,
        ),
        category: groupName,
        isFavorite: false, // You can implement favorites later
      );
    }).toList();
  }

  // Helper function to get flag emoji for symbol
  // String _getFlagForSymbol(String symbol) {
  //   // Currency pairs
  //   if (symbol.contains('EUR')) return '🇪🇺';
  //   if (symbol.contains('USD')) return '🇺🇸';
  //   if (symbol.contains('GBP')) return '🇬🇧';
  //   if (symbol.contains('JPY')) return '🇯🇵';
  //   if (symbol.contains('CHF')) return '🇨🇭';
  //   if (symbol.contains('CAD')) return '🇨🇦';
  //   if (symbol.contains('AUD')) return '🇦🇺';
  //   if (symbol.contains('NZD')) return '🇳🇿';

  //   // Metals
  //   if (symbol.contains('XAU')) return '🥇';
  //   if (symbol.contains('XAG')) return '🥈';

  //   // Indices
  //   if (symbol.contains('AU200')) return '🇦🇺';
  //   if (symbol.contains('DE40')) return '🇩🇪';
  //   if (symbol.contains('ES35')) return '🇪🇸';
  //   if (symbol.contains('EU50')) return '🇪🇺';
  //   if (symbol.contains('FR40')) return '🇫🇷';
  //   if (symbol.contains('HK50')) return '🇭🇰';

  //   // Crypto
  //   if (symbol.contains('BTC')) return '₿';
  //   if (symbol.contains('ETH')) return 'Ξ';

  //   // Default
  //   return '📈';
  // }

  void _showSymbolSelector() {
    // Use the real instruments data from instruments controller
    final instrumentsController = Get.find<InstrumentsController>();
    final instruments = _convertListElementsToInstruments(
      instrumentsController.allInstruments,
    );

    final TextEditingController searchController = TextEditingController();
    final List<String> filters = [
      'All',
      'Favorites',
      'Currency',
      'Metals',
      'Indices Spot',
    ];
    String currentFilter = 'All';
    List<Instrument> filteredInstruments = List.from(instruments);

    // Observable map to store real-time prices for each symbol
    final RxMap<String, Map<String, dynamic>> realTimePrices =
        <String, Map<String, dynamic>>{}.obs;

    // Set modal flag to true
    _isModalOpen = true;
    print('🚪 Modal opened - setting up real-time price updates');

    // Listen to price updates from chart socket controller
    StreamSubscription? priceSubscription;
    priceSubscription = chartSocketController.priceStream.listen((priceData) {
      if (priceData['symbol'] != null) {
        final symbol = priceData['symbol'].toString();
        realTimePrices[symbol] = priceData;
        print(
          '📊 Symbol Selector: Updated price for $symbol: ${priceData['bid']}/${priceData['ask']}',
        );
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Get keyboard height and screen dimensions
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final screenHeight = MediaQuery.of(context).size.height;
            final availableHeight = screenHeight - keyboardHeight;

            // Calculate modal height - use more space when keyboard is visible
            double modalHeight;
            if (keyboardHeight > 0) {
              // When keyboard is visible, use most of available space
              modalHeight = availableHeight * 0.9;
            } else {
              // When keyboard is hidden, use 90% of screen
              modalHeight = screenHeight * 0.9;
            }

            // Ensure minimum and maximum bounds
            modalHeight = modalHeight.clamp(
              screenHeight * 0.9, // Minimum 70% of screen
              screenHeight * 0.95, // Maximum 95% of screen
            );

            // Filter instruments based on current filter and search
            void updateFilteredInstruments() {
              List<Instrument> filtered = instruments;

              // Apply category filter
              if (currentFilter == 'Favorites') {
                filtered =
                    instruments
                        .where((instrument) => instrument.isFavorite)
                        .toList();
              } else if (currentFilter != 'All') {
                filtered =
                    instruments
                        .where(
                          (instrument) => instrument.category == currentFilter,
                        )
                        .toList();
              }

              // Apply search filter
              if (searchController.text.isNotEmpty) {
                filtered =
                    filtered
                        .where(
                          (instrument) => instrument.name
                              .toLowerCase()
                              .contains(searchController.text.toLowerCase()),
                        )
                        .toList();
              }

              setState(() {
                filteredInstruments = filtered;
              });
            }

            return Container(
              height: modalHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title with Socket Status
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Symbol',
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Socket connection status indicator with refresh button
                        // Obx(() {
                        //   final isConnected =
                        //       instrumentsController.isConnected.value;
                        //   final isReconnecting =
                        //       instrumentsController.isReconnecting.value;

                        //   return Row(
                        //     children: [
                        //       if (isReconnecting) ...[
                        //         SizedBox(
                        //           width: 12.w,
                        //           height: 12.h,
                        //           child: CircularProgressIndicator(
                        //             strokeWidth: 2,
                        //             valueColor: AlwaysStoppedAnimation<Color>(
                        //               AppColors.primary,
                        //             ),
                        //           ),
                        //         ),
                        //         SizedBox(width: 8.w),
                        //         Text(
                        //           'Reconnecting...',
                        //           style: AppTextStyles.subheading.copyWith(
                        //             fontSize: 12.sp,
                        //             color: AppColors.textGrey,
                        //           ),
                        //         ),
                        //       ] else if (isConnected) ...[
                        //         Container(
                        //           width: 8.w,
                        //           height: 8.h,
                        //           decoration: BoxDecoration(
                        //             color: AppColors.success,
                        //             shape: BoxShape.circle,
                        //           ),
                        //         ),
                        //         SizedBox(width: 8.w),
                        //         Text(
                        //           'Live Prices',
                        //           style: AppTextStyles.subheading.copyWith(
                        //             fontSize: 12.sp,
                        //             color: AppColors.success,
                        //             fontWeight: FontWeight.w500,
                        //           ),
                        //         ),
                        //       ] else ...[
                        //         Container(
                        //           width: 8.w,
                        //           height: 8.h,
                        //           decoration: BoxDecoration(
                        //             color: AppColors.red,
                        //             shape: BoxShape.circle,
                        //           ),
                        //         ),
                        //         SizedBox(width: 8.w),
                        //         Text(
                        //           'Offline',
                        //           style: AppTextStyles.subheading.copyWith(
                        //             fontSize: 12.sp,
                        //             color: AppColors.red,
                        //             fontWeight: FontWeight.w500,
                        //           ),
                        //         ),
                        //       ],
                        //       SizedBox(width: 12.w),
                        //       // Refresh button
                        //       GestureDetector(
                        //         onTap: () {
                        //           print(
                        //             '🔄 Symbol Selector: Manual refresh requested',
                        //           );
                        //           instrumentsController.manualReconnect();
                        //         },
                        //         child: Container(
                        //           padding: EdgeInsets.all(6.w),
                        //           decoration: BoxDecoration(
                        //             color: AppColors.primary.withOpacity(0.1),
                        //             borderRadius: BorderRadius.circular(6.r),
                        //           ),
                        //           child: Icon(
                        //             Icons.refresh,
                        //             size: 16.w,
                        //             color: AppColors.primary,
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   );
                        // }),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (value) {
                        updateFilteredInstruments();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search instruments',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textGrey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Filter buttons - same as instruments screen
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            filters.map((filter) {
                              final isSelected = filter == currentFilter;
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentFilter = filter;
                                    });
                                    updateFilteredInstruments();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : AppColors.primary,
                                      ),
                                    ),
                                    child: Text(
                                      filter,
                                      style: AppTextStyles.input.copyWith(
                                        fontSize: 14.sp,
                                        height: 22 / 15,
                                        color:
                                            isSelected
                                                ? AppColors.whiteColor
                                                : AppColors.primary,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Instruments list with same layout as instruments screen
                  Expanded(
                    child:
                        filteredInstruments.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48.h,
                                    color: AppColors.textGrey,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'No symbols found',
                                    style: AppTextStyles.subheading.copyWith(
                                      color: AppColors.textGrey,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  if (searchController.text.isNotEmpty)
                                    Text(
                                      'Try a different search term',
                                      style: AppTextStyles.subheading.copyWith(
                                        color: AppColors.textGrey,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              itemCount: filteredInstruments.length,
                              itemBuilder: (context, index) {
                                final instrument = filteredInstruments[index];
                                final isSelected =
                                    instrument.name == selectedSymbol;

                                return GestureDetector(
                                  onTap: () {
                                    // Reset modal flag and close modal
                                    _isModalOpen = false;
                                    print(
                                      '🚪 Modal closed - resuming price updates',
                                    );
                                    Navigator.pop(context);
                                    _onSymbolChanged(instrument.name);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: AppColors.border.withOpacity(
                                            0.3,
                                          ),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Flag and Name - same layout as instruments screen
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              // Flags container
                                              Container(
                                                width: 40.w,
                                                height: 24.h,
                                                child: Container(
                                                  width: 40.w,
                                                  height: 24.h,
                                                  child: Stack(
                                                    children: [
                                                      Image.network(
                                                        instrument.flag,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _getMarketStatus(
                                                        instrument.status,
                                                      ),
                                                      style: AppTextStyles
                                                          .subheading
                                                          .copyWith(
                                                            fontSize: 10.sp,
                                                            color:
                                                                AppColors
                                                                    .textGrey,
                                                          ),
                                                    ),
                                                    Text(
                                                      instrument.name.substring(
                                                        0,
                                                        instrument.name
                                                            .lastIndexOf("."),
                                                      ),
                                                      style: AppTextStyles.input
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 14.sp,
                                                          ),
                                                    ),
                                                    if (instrument.heigh !=
                                                        null)
                                                      Row(
                                                        children: [
                                                          Text(
                                                            instrument.heigh!
                                                                    .replaceFirst(
                                                                      r'S',
                                                                      '+',
                                                                    ) +
                                                                '%' +
                                                                '\t',
                                                            style: AppTextStyles
                                                                .subheading
                                                                .copyWith(
                                                                  fontSize:
                                                                      10.sp,
                                                                  color:
                                                                      AppColors
                                                                          .green,
                                                                ),
                                                          ),
                                                          Text(
                                                            instrument.heigh!,
                                                            style: AppTextStyles
                                                                .subheading
                                                                .copyWith(
                                                                  fontSize:
                                                                      10.sp,
                                                                  color:
                                                                      AppColors
                                                                          .textGrey,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    SizedBox(height: 2.h),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Sell Price (Red) - Real-time price updates
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Obx(() {
                                                // Get real-time price for this symbol
                                                final realTimePrice =
                                                    realTimePrices[instrument
                                                        .name];
                                                final bidPrice =
                                                    realTimePrice?['bid']
                                                        ?.toString() ??
                                                    instrument.bidPrice;
                                                final digits =
                                                    realTimePrice?['digits'] ??
                                                    5;

                                                // Format price with correct decimal places
                                                String formattedBidPrice;
                                                bool isLivePrice = false;
                                                if (realTimePrice != null) {
                                                  final bid = double.tryParse(
                                                    bidPrice.toString(),
                                                  );
                                                  if (bid != null) {
                                                    formattedBidPrice = bid
                                                        .toStringAsFixed(
                                                          digits,
                                                        );
                                                    isLivePrice = true;
                                                  } else {
                                                    formattedBidPrice =
                                                        instrument.bidPrice;
                                                  }
                                                } else {
                                                  formattedBidPrice =
                                                      instrument.bidPrice;
                                                }

                                                return Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      formattedBidPrice,
                                                      style: AppTextStyles.input
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 17.sp,
                                                            color:
                                                                AppColors.red,
                                                            height: 22 / 17,
                                                          ),
                                                    ),
                                                    if (isLivePrice) ...[
                                                      SizedBox(width: 4.w),
                                                      Container(
                                                        width: 4.w,
                                                        height: 4.h,
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  AppColors
                                                                      .success,
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                      ),
                                                    ],
                                                  ],
                                                );
                                              }),
                                              SizedBox(height: 2.h),
                                              Text(
                                                'L: ${instrument.lowPrice}',
                                                style: AppTextStyles.subheading
                                                    .copyWith(
                                                      fontSize: 10.sp,
                                                      color: AppColors.textGrey,
                                                      height: 22 / 10,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Buy Price (Green) - Real-time price updates
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Obx(() {
                                                // Get real-time price for this symbol
                                                final realTimePrice =
                                                    realTimePrices[instrument
                                                        .name];
                                                final askPrice =
                                                    realTimePrice?['ask']
                                                        ?.toString() ??
                                                    instrument.askPrice;
                                                final digits =
                                                    realTimePrice?['digits'] ??
                                                    5;

                                                // Format price with correct decimal places
                                                String formattedAskPrice;
                                                bool isLivePrice = false;
                                                if (realTimePrice != null) {
                                                  final ask = double.tryParse(
                                                    askPrice.toString(),
                                                  );
                                                  if (ask != null) {
                                                    formattedAskPrice = ask
                                                        .toStringAsFixed(
                                                          digits,
                                                        );
                                                    isLivePrice = true;
                                                  } else {
                                                    formattedAskPrice =
                                                        instrument.askPrice;
                                                  }
                                                } else {
                                                  formattedAskPrice =
                                                      instrument.askPrice;
                                                }

                                                return Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      formattedAskPrice,
                                                      style: AppTextStyles.input
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 17.sp,
                                                            color:
                                                                AppColors
                                                                    .success,
                                                            height: 22 / 17,
                                                          ),
                                                    ),
                                                    if (isLivePrice) ...[
                                                      SizedBox(width: 4.w),
                                                      Container(
                                                        width: 4.w,
                                                        height: 4.h,
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  AppColors
                                                                      .success,
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                      ),
                                                    ],
                                                  ],
                                                );
                                              }),
                                              SizedBox(height: 2.h),
                                              Text(
                                                'H: ${instrument.highPrice}',
                                                style: AppTextStyles.subheading
                                                    .copyWith(
                                                      fontSize: 10.sp,
                                                      color: AppColors.textGrey,
                                                      height: 22 / 10,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),

                  // Bottom padding - only add extra padding when keyboard is not visible
                  if (keyboardHeight == 0)
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16.h,
                    ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Reset modal flag when modal is dismissed
      _isModalOpen = false;
      print('🚪 Modal dismissed - resuming price updates');

      // Cancel the price subscription
      priceSubscription?.cancel();
      print('📊 Symbol Selector: Price subscription cancelled');

      // Clear the observable map
      realTimePrices.clear();
      print('📊 Symbol Selector: Real-time prices cleared');
    });
  }

  Widget _buildInteractiveIcons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _showTradingOrderBottomSheet();
            },
            child: Container(
              height: 45.h,
              width: 288.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7.r),
                color: AppColors.cardBackGround,
              ),
              child: Text(
                "Pending order • SL • TP",
                style: AppTextStyles.labelOnTradeButton,
              ),
            ),
          ),
          Spacer(),

          GestureDetector(
            onTap: () {
              _showPriceAlertDialog();
            },
            child: Container(
              height: 45.h,
              width: 45.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7.r),
                color: AppColors.primary,
              ),
              child: SvgPicture.asset(
                "assets/svg/chart_screen_icon/bell_icon.svg",
                color: AppColors.whiteColor,
              ),
            ),
          ),
          // SizedBox(width: 8.w),

          // Debug info button
          // GestureDetector(
          //   onTap: () {
          //     _showPriceDebugInfo();
          //   },
          //   child: Container(
          //     height: 45.h,
          //     width: 45.w,
          //     alignment: Alignment.center,
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(7.r),
          //       color: Colors.blue,
          //     ),
          //     child: Icon(Icons.info, color: Colors.white, size: 20.sp),
          //   ),
          // ),
          // SizedBox(width: 8.w),
          // // Test alert button
          // GestureDetector(
          //   onTap: () {
          //     _testPriceAlert();
          //   },
          //   child: Container(
          //     height: 45.h,
          //     width: 45.w,
          //     alignment: Alignment.center,
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(7.r),
          //       color: Colors.orange,
          //     ),
          //     child: Icon(Icons.bug_report, color: Colors.white, size: 20.sp),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildTradingControls() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isLargeScreen = screenWidth > 600;

    // Get real-time prices from chart socket controller
    final currentPriceData = chartSocketController.getCurrentPrice();
    final bidPrice = chartSocketController.getBidPrice()?.toString() ?? '0';
    final askPrice = chartSocketController.getAskPrice().toString() ?? '0';
    final difference = chartSocketController.getDifference()?.toString() ?? '0';

    // print('🔵 CHART TRADING CONTROLS:');
    // print('💰 Bid Price: $bidPrice');
    // print('💰 Ask Price: $askPrice');
    // print('🎯 Symbol: $selectedSymbol');
    // print('📊 Real-time Price Data: $realTimePrice');
    // print('📊 Current Price Data: $currentPriceData');
    // print('🔌 WebSocket Connected: ${chartSocketController.isConnected.value}');
    // print(
    //   '📡 Current Symbol in Controller: ${chartSocketController.currentSymbol.value}',
    // );

    // // Try to get the model data
    // final priceDataModel = chartSocketController.getCurrentPriceDataModel();
    // if (priceDataModel != null) {
    //   print('📊 Model Data: $priceDataModel');
    //   print('💰 Model Bid: ${priceDataModel.bid}');
    //   print('💰 Model Ask: ${priceDataModel.ask}');
    //   print('📊 Model Spread: ${priceDataModel.calculatedSpread}');
    // } else {
    //   print('❌ No model data available');
    // }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // SELL Button - now wrapped in GestureDetector
                GestureDetector(
                  onTap: () async {
                    await chartController
                        .placeTradeOrder(
                          mt5Account:
                              "${accountController.activeMT5Account?.metaAccountNumber}",
                          symbol: "${selectedSymbol}",
                          volume: 0.01,
                          type: "1",
                          priceSl: "", //_stopLossPrice.value,
                          priceTp: "", //
                          price: "",
                        )
                        .then((value) {
                          if (value) {
                            // Navigate to trade tab using bottom navigation
                            if (widget.onNavigateToTrade != null) {
                              widget.onNavigateToTrade!();
                            }
                            Get.snackbar(
                              'Success',
                              'Order placed successfully',
                            );
                          } else {
                            //Get\.snackbar\('Error', 'Failed to place order');
                          }
                        });
                  },
                  child: Container(
                    height: 48.h,
                    width: (MediaQuery.of(context).size.width / 2) - 23,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SELL',
                          style: AppTextStyles.button.copyWith(
                            fontSize: isSmallScreen ? 12.sp : 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          bidPrice,
                          style: AppTextStyles.button.copyWith(
                            fontSize: isSmallScreen ? 12.sp : 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8.w : 16.w),
                // BUY Button - now wrapped in GestureDetector
                GestureDetector(
                  onTap: () async {
                    await chartController
                        .placeTradeOrder(
                          mt5Account:
                              "${accountController.activeMT5Account?.metaAccountNumber}",
                          symbol: "${selectedSymbol}",
                          volume: volume,
                          type: "0",
                          priceSl: "", //_stopLossPrice.value,
                          priceTp: "", //_takeProfitPrice.value,
                          price: "",
                          // price: chartSocketController.getAskPrice(),
                        )
                        .then((value) {
                          if (value) {
                            // Navigate to trade tab using bottom navigation
                            if (widget.onNavigateToTrade != null) {
                              widget.onNavigateToTrade!();
                            }
                            Get.snackbar(
                              'Success',
                              'Order placed successfully',
                            );
                          } else {
                            //Get\.snackbar\('Error', 'Failed to place order');
                          }
                        });
                  },
                  child: Container(
                    height: 48.h,
                    width: (MediaQuery.of(context).size.width / 2) - 23,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'BUY',
                          style: AppTextStyles.button.copyWith(
                            fontSize: isSmallScreen ? 12.sp : 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          askPrice.toString(),
                          style: AppTextStyles.button.copyWith(
                            fontSize: isSmallScreen ? 12.sp : 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.013,
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.tradeBackgroundCenterColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  height: 26.h,
                  width: 52.w,
                  child: Text(
                    difference,
                    style: AppTextStyles.labelOnTradeDifference,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeInputScreen(BuildContext context, bool isborder) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isborder ? 10.w : 0,
        vertical: isborder ? 10.h : 2.h,
      ),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 11.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isborder ? AppColors.border : Colors.transparent,
          ),
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
                // color: AppColors.icongrey,
                border: Border.all(color: AppColors.icongrey),
              ),
              width: 24.w,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    if (volume > 0.01) {
                      volume -= 0.01;
                      _volumeController.text = volume.toStringAsFixed(2);
                    }
                  });
                },
                icon: Icon(Icons.remove, size: 18.h, color: AppColors.icongrey),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),

            // Volume display
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Quantity (lots)',
                    style: AppTextStyles.labelOnTradeQuantity,
                  ),
                  // SizedBox(height: 1.h),
                  TextField(
                    controller: _volumeController,
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
                      final newVolume = double.tryParse(value);
                      if (newVolume != null && newVolume > 0) {
                        setState(() {
                          volume = newVolume;
                        });
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
                // color: AppColors.icongrey,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              width: 24.w,
              height: 24.h,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    volume += 0.01;
                    _volumeController.text = volume.toStringAsFixed(2);
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
    );
  }

  void _showTradingOrderBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // allow outside tap
      enableDrag: true, // allow swipe down
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque, // let outside taps pass through
          onTap: () {
            Navigator.of(context).pop(); // close on outside tap
          },
          child: GestureDetector(
            // prevent taps inside sheet from closing it
            onTap: () {},
            child: DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.3,
              maxChildSize: 0.95, // Increased to 95% to accommodate keyboard
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Container(
                          width: 30.w,
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: AppColors.grey,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 18.h),
                        child: Text(
                          "Pending order",
                          style: AppTextStyles.labelOnTradeBottomTitle,
                        ),
                      ),
                      SizedBox(height: 7.5.h),
                      Container(
                        height: 1.h,
                        width: double.infinity,
                        color: AppColors.grey,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                            left: 16.w,
                            right: 16.w,
                            top: 16.w,
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom +
                                16.w, // Add keyboard height
                          ),
                          child: _buildPendingOrderContent(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketOrderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Volume Input
        _buildVolumeInput(),
        SizedBox(height: 14.h),

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
              valueListenable: _openPrice,
              builder: (context, price, child) {
                return Text(
                  '${price.toStringAsFixed(2)}',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // Margin Details
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.grey,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required margin',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      '\$6.93',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Free margin',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      '\$4953.85',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Take Profit
        _buildSwitchTile(
          'Take Profit',
          _takeProfitEnabled,
          onChanged: (value) {
            _takeProfitEnabled.value = value;
            if (value) _stopLossEnabled.value = false;
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _takeProfitEnabled,
          builder: (context, enabled, child) {
            if (!enabled) return SizedBox.shrink();
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
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
                                  setState(() {
                                    if (_takeProfitPrice.value > 0.01) {
                                      _takeProfitPrice.value -= 0.01;
                                      _takeProfitController
                                          .text = _takeProfitPrice.value
                                          .toStringAsFixed(2);
                                    }
                                  });
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
                                        controller: _volumeController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
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
                                          final newVolume = double.tryParse(
                                            value,
                                          );
                                          if (newVolume != null &&
                                              newVolume > 0) {
                                            setState(() {
                                              volume = newVolume;
                                            });
                                          }
                                        },
                                      ),
                                    ), // Text(
                                    // volume.toStringAsFixed(2),
                                    // style: AppTextStyles.label.copyWith(
                                    // fontSize: 16.sp,
                                    // fontWeight: FontWeight.w700,
                                    // ),
                                    // ),
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
                                  setState(() {
                                    volume += 0.01;
                                    _volumeController.text = volume
                                        .toStringAsFixed(2);
                                  });
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

                // _buildPriceInput('1.15550', _takeProfitPrice),
                // SizedBox(height: 4.h),
                // Text(
                //   '68 points | Profit +4.08 USD | +0.08% of balance',
                //   style: AppTextStyles.label.copyWith(
                //     fontSize: 12.sp,
                //     color: AppColors.textGrey,
                //   ),
                // ),
                SizedBox(height: 8.h),
              ],
            );
          },
        ),

        // Stop Loss
        _buildSwitchTile(
          'Stop Loss',
          _stopLossEnabled,
          onChanged: (value) {
            _stopLossEnabled.value = value;
            if (value) _trailingStopEnabled.value = false;
            if (value) _breakEvenEnabled.value = false;
          },
        ),

        // ValueListenableBuilder<bool>(
        //   valueListenable: _stopLossEnabled,
        //   builder: (context, enabled, child) {
        //     if (!enabled) return SizedBox.shrink();
        //     return Column(
        //       children: [
        //         _buildPriceInput('1.15448', _stopLossPrice),
        //         SizedBox(height: 4.h),
        //         Text(
        //           '-37 points | Profit -2.22 USD | -0.04% of balance',
        //           style: AppTextStyles.label.copyWith(
        //             fontSize: 12.sp,
        //             color: AppColors.textGrey,
        //           ),
        //         ),
        //         SizedBox(height: 8.h),
        //       ],
        //     );
        //   },
        // ),
        ValueListenableBuilder<bool>(
          valueListenable: _stopLossEnabled,
          builder: (context, enabled, child) {
            if (!enabled) return SizedBox.shrink();
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
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
                                  setState(() {
                                    if (_takeProfitPrice.value > 0.01) {
                                      _takeProfitPrice.value -= 0.01;
                                      _takeProfitController
                                          .text = _takeProfitPrice.value
                                          .toStringAsFixed(2);
                                    }
                                  });
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
                                        controller: _volumeController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
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
                                          final newVolume = double.tryParse(
                                            value,
                                          );
                                          if (newVolume != null &&
                                              newVolume > 0) {
                                            setState(() {
                                              volume = newVolume;
                                            });
                                          }
                                        },
                                      ),
                                    ), // Text(
                                    // volume.toStringAsFixed(2),
                                    // style: AppTextStyles.label.copyWith(
                                    // fontSize: 16.sp,
                                    // fontWeight: FontWeight.w700,
                                    // ),
                                    // ),
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
                                  setState(() {
                                    volume += 0.01;
                                    _volumeController.text = volume
                                        .toStringAsFixed(2);
                                  });
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

                // _buildPriceInput('1.15550', _takeProfitPrice),
                // SizedBox(height: 4.h),
                // Text(
                //   '68 points | Profit +4.08 USD | +0.08% of balance',
                //   style: AppTextStyles.label.copyWith(
                //     fontSize: 12.sp,
                //     color: AppColors.textGrey,
                //   ),
                // ),
                SizedBox(height: 8.h),
              ],
            );
          },
        ),

        // // Advanced Settings
        _buildAdvancedSettings(),

        SizedBox(height: 24.h),

        // Confirm Button
        Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Confirm Buy order',
                style: AppTextStyles.button.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '1.15482',
                style: AppTextStyles.button.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingOrderContent() {
    return PendingOrderContent(
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
        volume = newVolume;
      },
    );
  }

  Widget _buildVolumeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
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
                      setState(() {
                        if (volume > 0.01) {
                          volume -= 0.01;
                          _volumeController.text = volume.toStringAsFixed(2);
                        }
                      });
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
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Volume',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _volumeController,
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
                              final newVolume = double.tryParse(value);
                              if (newVolume != null && newVolume > 0) {
                                setState(() {
                                  volume = newVolume;
                                });
                              }
                            },
                          ),
                        ), // Text(
                        // volume.toStringAsFixed(2),
                        // style: AppTextStyles.label.copyWith(
                        // fontSize: 16.sp,
                        // fontWeight: FontWeight.w700,
                        // ),
                        // ),
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
                      setState(() {
                        volume += 0.01;
                        _volumeController.text = volume.toStringAsFixed(2);
                      });
                    },
                    icon: Icon(Icons.add, size: 16.h, color: AppColors.primary),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
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
          child: Text(
            "lots",
            style: AppTextStyles.label.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuentyPendingOrder() {
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
          _buildVolumeInputScreen(context, false),
          Container(width: double.maxFinite, height: 2, color: AppColors.grey),
          SizedBox(height: 6.h),

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
                  "\$0.066%",
                  style: AppTextStyles.labelOnChartPendingOrderBold,
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 11.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Free margin",
                  style: AppTextStyles.labelOnChartPendingOrder,
                ),
                Text("\$356.68", style: AppTextStyles.labelOnChartPendingOrder),
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
                // color: AppColors.icongrey,
                border: Border.all(color: AppColors.icongrey),
              ),
              width: 24.w,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    if (volume > 0.01) {
                      volume -= 0.01;
                      _volumeController.text = volume.toStringAsFixed(2);
                    }
                  });
                },
                icon: Icon(Icons.remove, size: 18.h, color: AppColors.icongrey),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),

            // Volume display
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Quantity (lots)',
                    style: AppTextStyles.labelOnTradeQuantity,
                  ),
                  // SizedBox(height: 1.h),
                  TextField(
                    controller: _volumeController,
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
                      final newVolume = double.tryParse(value);
                      if (newVolume != null && newVolume > 0) {
                        setState(() {
                          volume = newVolume;
                        });
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
                // color: AppColors.icongrey,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              width: 24.w,
              height: 24.h,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    volume += 0.01;
                    _volumeController.text = volume.toStringAsFixed(2);
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

  Widget _buildPriceInput(String label, ValueNotifier<double> priceNotifier) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ValueListenableBuilder<double>(
        valueListenable: priceNotifier,
        builder: (context, price, child) {
          return Row(
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
                    if (price > 0.01) priceNotifier.value = price - 0.01;
                  },
                  icon: Icon(Icons.remove, size: 16.h, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    price.toStringAsFixed(5),
                    style: AppTextStyles.label.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
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
                    priceNotifier.value = price + 0.01;
                  },
                  icon: Icon(Icons.add, size: 16.h, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
              SizedBox(width: 12.w),
              _buildPriceTypeDropdown(),
            ],
          );
        },
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
                    scale: 0.8, // Adjust this scale to control total size
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

  Widget _buildAdvancedSettings() {
    return ValueListenableBuilder<bool>(
      valueListenable: _advanceSettingsEnabled,
      builder: (context, expanded, child) {
        return Column(
          children: [
            GestureDetector(
              onTap: () => _advanceSettingsEnabled.value = !expanded,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Advanced settings',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                      size: 20.h,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              SizedBox(height: 8.h),
              _buildSwitchTile(
                'Trailing stop',
                _trailingStopEnabled,
                onChanged: (value) {
                  _trailingStopEnabled.value = value;
                  if (value) _stopLossEnabled.value = false;
                  if (value) _breakEvenEnabled.value = false;
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _trailingStopEnabled,
                builder: (context, enabled, child) {
                  if (!enabled) return SizedBox.shrink();
                  return Column(
                    children: [
                      SizedBox(height: 8.h),
                      _buildDistanceInput(),
                      SizedBox(height: 8.h),
                    ],
                  );
                },
              ),

              _buildSwitchTile(
                'Break even',
                _breakEvenEnabled,
                onChanged: (value) {
                  _breakEvenEnabled.value = value;
                  if (value) _trailingStopEnabled.value = false;
                  if (value) _stopLossEnabled.value = false;
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _breakEvenEnabled,
                builder: (context, enabled, child) {
                  if (!enabled) return SizedBox.shrink();
                  return Column(
                    children: [
                      SizedBox(height: 8.h),
                      _buildDistanceInput(),
                      SizedBox(height: 8.h),
                    ],
                  );
                },
              ),
              ValueListenableBuilder<int>(
                valueListenable: _selectedOrderTab,
                builder: (context, selectedTab, child) {
                  return selectedTab == 1
                      ? Column(
                        children: [
                          _buildSwitchTile(
                            'Order expiration',
                            _orderExpirationEnabled,
                            onChanged: (value) {
                              _orderExpirationEnabled.value = value;
                            },
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: _orderExpirationEnabled,
                            builder: (context, enabled, child) {
                              if (!enabled) return SizedBox.shrink();
                              return Column(
                                children: [
                                  SizedBox(height: 8.h),
                                  _buildOrderExpirationInput(),
                                  SizedBox(height: 8.h),
                                ],
                              );
                            },
                          ),
                        ],
                      )
                      : SizedBox.shrink();
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOrderExpirationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // First container - Display selected date/time with calendar icon
            InkWell(
              onTap: _selectOrderExpirationDate,
              child: Container(
                width: 150.w,
                height: 50.h,
                padding: EdgeInsets.only(left: 12.w, top: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ValueListenableBuilder<DateTime>(
                        valueListenable: _orderExpirationDate,
                        builder: (context, dateTime, child) {
                          return Text(
                            DateFormat('MMM dd, yyyy').format(dateTime),
                            style: AppTextStyles.label.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Third container - Time picker button
            Container(
              width: 150.w,
              height: 50.h,
              padding: EdgeInsets.only(left: 12.w, top: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.border),
              ),
              child: InkWell(
                onTap: _selectOrderExpirationTime,
                borderRadius: BorderRadius.circular(8.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ValueListenableBuilder<DateTime>(
                      valueListenable: _orderExpirationTime,
                      builder: (context, dateTime, child) {
                        return Text(
                          DateFormat('hh:MM').format(dateTime),
                          style: AppTextStyles.label.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectOrderExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _orderExpirationDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Keep the current time, only update the date
      final currentDateTime = _orderExpirationDate.value;
      final newDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        currentDateTime.hour,
        currentDateTime.minute,
      );
      _orderExpirationDate.value = newDateTime;
    }
  }

  Future<void> _selectOrderExpirationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_orderExpirationTime.value),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Keep the current date, only update the time
      final currentDateTime = _orderExpirationTime.value;
      final newDateTime = DateTime(
        currentDateTime.year,
        currentDateTime.month,
        currentDateTime.day,
        picked.hour,
        picked.minute,
      );
      _orderExpirationTime.value = newDateTime;
    }
  }

  Widget _buildDistanceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance, points',
          style: AppTextStyles.label.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
          ),
        ),
        SizedBox(height: 8.h),
        ValueListenableBuilder<double>(
          valueListenable: _distance,
          builder: (context, distance, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 340.w,
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
                              if (distance > 10) {
                                _distance.value = distance - 10;
                                distanceController.text = _distance.value
                                    .toStringAsFixed(2);
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
                                    controller: distanceController,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
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
                                      if (value.isNotEmpty) {
                                        try {
                                          double newDistance = double.parse(
                                            value,
                                          );
                                          if (newDistance > 0) {
                                            _distance.value = newDistance;
                                          }
                                        } catch (e) {
                                          // Handle invalid input
                                        }
                                      }
                                    },
                                  ),
                                ), // Text(
                                // volume.toStringAsFixed(2),
                                // style: AppTextStyles.label.copyWith(
                                // fontSize: 16.sp,
                                // fontWeight: FontWeight.w700,
                                // ),
                                // ),
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
                              _distance.value = distance + 10;
                              distanceController.text = _distance.value
                                  .toStringAsFixed(2);
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
              ],
            );

            //  Row(
            //   children: [
            //     Container(
            //       width: 32.w,
            //       height: 32.h,
            //       decoration: BoxDecoration(
            //         shape: BoxShape.circle,
            //         border: Border.all(color: Colors.grey[400]!),
            //       ),
            //       child: IconButton(
            //         onPressed: () {
            //           if (distance > 10) _distance.value = distance - 10;
            //         },
            //         icon: Icon(
            //           Icons.remove,
            //           size: 16.h,
            //           color: Colors.grey[600],
            //         ),
            //         padding: EdgeInsets.zero,
            //         constraints: BoxConstraints(),
            //       ),
            //     ),
            //     Expanded(
            //       child: Center(
            //         child: Text(
            //           distance.toInt().toString(),
            //           style: AppTextStyles.label.copyWith(
            //             fontSize: 18.sp,
            //             fontWeight: FontWeight.w700,
            //             color: AppColors.textPrimary,
            //           ),
            //         ),
            //       ),
            //     ),
            //     Container(
            //       width: 32.w,
            //       height: 32.h,
            //       decoration: BoxDecoration(
            //         shape: BoxShape.circle,
            //         border: Border.all(color: AppColors.primary),
            //       ),
            //       child: IconButton(
            //         onPressed: () {
            //           _distance.value = distance + 10;
            //         },
            //         icon: Icon(
            //           Icons.add,
            //           size: 16.h,
            //           color: AppColors.primary,
            //         ),
            //         padding: EdgeInsets.zero,
            //         constraints: BoxConstraints(),
            //       ),
            //     ),
            //   ],
            // );
          },
        ),
      ],
    );
  }

  Widget _buildPriceTypeDropdown() {
    return ValueListenableBuilder<String>(
      valueListenable: selectedPriceType,
      builder: (context, value, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
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
                if (newValue != null) {
                  selectedPriceType.value = newValue;
                }
              },
            ),
          ),
        );
      },
    );
  }

  // Helper methods from instruments screen
  String _getMarketStatus(String status) {
    // Extract time and percentage from status like "01:00:00 H 16.0"
    if (status.contains('H') || status.contains('S')) {
      final parts = status.split(' ');
      if (parts.length >= 3) {
        final time = parts[0];
        final type = parts[1];
        final value = parts[2];

        if (type == 'S') {
          // Show active status with percentage
          return '$time +$value% S:${value.split('.')[0]}.${value.split('.')[1]}';
        } else {
          // Show market closed
          return 'Market closed';
        }
      }
    }
    return 'Market closed';
  }
}
