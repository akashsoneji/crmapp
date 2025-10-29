import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TradingWebSocketService extends GetxService with WidgetsBindingObserver {
  // Connection state
  final RxBool isConnected = false.obs;
  final RxBool isReconnecting = false.obs;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  bool _isDisposed = false;
  late WebSocketChannel channel;

  // Subscription state tracking
  Timer? _subscriptionRefreshTimer;
  Timer? _dataRetryTimer;
  DateTime? _lastDataReceived;

  // Debounce timer to prevent rapid updates causing flickering
  Timer? _updateDebounceTimer;

  // Controllers
  late TradingController _tradingController;
  late AccountController _accountController;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Initialize controllers
    _tradingController = Get.find<TradingController>();
    _accountController = Get.find<AccountController>();

    // Initialize WebSocket connection
    _initializeWebSocket();
  }

  @override
  void onClose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disconnectWebSocket();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (!isConnected.value && !_isDisposed) {
          if (kDebugMode) {
            dev.log('Trading WS: App resumed, reconnecting...');
          }
          _initializeWebSocket();
        }
        break;
      case AppLifecycleState.paused:
        if (kDebugMode) {
          dev.log('Trading WS: App paused, maintaining connection');
        }
        break;
      case AppLifecycleState.detached:
        if (kDebugMode) {
          dev.log('Trading WS: App detached, closing connection');
        }
        _disconnectWebSocket();
        break;
      case AppLifecycleState.inactive:
        if (kDebugMode) {
          dev.log('Trading WS: App inactive');
        }
        break;
      case AppLifecycleState.hidden:
        if (kDebugMode) {
          dev.log('Trading WS: App hidden');
        }
        break;
    }
  }

  // Initialize WebSocket connection
  void _initializeWebSocket() {
    if (isConnected.value) return;

    try {
      channel = WebSocketChannel.connect(Uri.parse(ApiConstants.socketUrl));
      isConnected.value = true;
      _reconnectAttempts = 0;
      isReconnecting.value = false;

      if (kDebugMode) {
        dev.log('Trading WS: Connected successfully');
      }

      channel.stream.listen(
        (message) => _handleSocketMessage(message),
        onError: (error) {
          if (kDebugMode) {
            dev.log('Trading WS error: $error');
          }
          isConnected.value = false;
          _scheduleReconnect();
        },
        onDone: () {
          if (kDebugMode) {
            dev.log('Trading WS: Connection closed');
          }
          isConnected.value = false;
          _scheduleReconnect();
        },
      );

      // Request trading data after connection with proper delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (isConnected.value && !_isDisposed) {
          _requestTradingData();
          // Start periodic refresh to maintain subscription
          _startPeriodicRefresh();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Initialization failed: $e');
      }
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  // Request trading data from WebSocket
  void _requestTradingData() async {
    if (_isDisposed || !isConnected.value) {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot request data - disposed or not connected');
      }
      return;
    }

    final authId = await SecureStorageService.getWebsocketToken();
    if (authId == null || authId.isEmpty) {
      if (kDebugMode) {
        dev.log('Trading WS: No auth token, retrying in 2 seconds...');
      }
      Timer(const Duration(seconds: 2), () {
        if (isConnected.value && !_isDisposed) {
          _requestTradingData();
        }
      });
      return;
    }

    final activeAccount = _accountController.activeMT5Account;
    final accountNumber = activeAccount?.metaAccountNumber ?? "0";

    if (accountNumber == "0" || accountNumber.isEmpty) {
      if (kDebugMode) {
        dev.log('Trading WS: Invalid account number, retrying in 2 seconds...');
      }
      Timer(const Duration(seconds: 2), () {
        if (isConnected.value && !_isDisposed) {
          _requestTradingData();
        }
      });
      return;
    }

    if (kDebugMode) {
      dev.log('Trading WS: Requesting data for account: $accountNumber');
    }

    // Subscribe based on current tab: Market tab (0) or Pending tab (1)
    final currentTab = _tradingController.selectedTab;

    if (currentTab == 1) {
      // Pending tab - subscribe to pending orders
      if (kDebugMode) {
        dev.log(
          'Trading WS: Pending tab active - subscribing to pending orders',
        );
      }
      _sendEvent({
        "type": "subscribe_pending_orders",
        "account": accountNumber,
      });
    } else {
      // Market tab (0) or Close tab (2) - subscribe to all groups for positions
      if (kDebugMode) {
        dev.log(
          'Trading WS: Market/Close tab active - subscribing to all groups',
        );
      }
      _sendEvent({"type": "subscribe_all_groups", "account": accountNumber});
    }

    // Set up retry timer if no data received within 3 seconds
    _setupDataRetryTimer();
  }

  // Setup retry timer if data doesn't arrive
  void _setupDataRetryTimer() {
    _dataRetryTimer?.cancel();
    _dataRetryTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed || !isConnected.value) return;

      // Check if we received data after last subscription
      if (_lastDataReceived == null ||
          DateTime.now().difference(_lastDataReceived!).inSeconds > 2) {
        if (kDebugMode) {
          dev.log(
            'Trading WS: No data received after subscription, retrying...',
          );
        }
        // Retry subscription
        final activeAccount = _accountController.activeMT5Account;
        final accountNumber = activeAccount?.metaAccountNumber ?? "0";
        final currentTab = _tradingController.selectedTab;

        if (currentTab == 1) {
          _sendEvent({
            "type": "subscribe_pending_orders",
            "account": accountNumber,
          });
        } else {
          _sendEvent({
            "type": "subscribe_all_groups",
            "account": accountNumber,
          });
        }

        // Setup another retry if still no data
        _setupDataRetryTimer();
      }
    });
  }

  // Start periodic refresh to maintain subscription
  void _startPeriodicRefresh() {
    _subscriptionRefreshTimer?.cancel();
    // Refresh subscription every 30 seconds to maintain connection
    _subscriptionRefreshTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) {
      if (_isDisposed || !isConnected.value) {
        timer.cancel();
        return;
      }
      if (kDebugMode) {
        dev.log('Trading WS: Periodic refresh - maintaining subscription');
      }
      _requestTradingData();
    });
  }

  // Refresh data based on current tab
  void refreshDataForCurrentTab() {
    if (_isDisposed || !isConnected.value) {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot refresh - disposed or not connected');
      }
      return;
    }

    // Cancel retry timer since we're manually refreshing
    _dataRetryTimer?.cancel();

    // Request fresh data with small delay to ensure WebSocket is ready
    Future.delayed(const Duration(milliseconds: 200), () {
      if (isConnected.value && !_isDisposed) {
        _requestTradingData();
      }
    });
  }

  // Send event to WebSocket
  void _sendEvent(Map<String, dynamic> event) {
    if (!isConnected.value || _isDisposed) return;

    try {
      final message = jsonEncode(event);
      channel.sink.add(message);
      if (kDebugMode) {
        // Commented out to reduce noise - uncomment if needed
        // dev.log('Trading WS: Sent event: $event');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error sending event: $e');
      }
    }
  }

  // Handle incoming WebSocket messages
  void _handleSocketMessage(dynamic message) {
    if (_isDisposed) return;

    try {
      final decoded = jsonDecode(message);

      // Update last data received timestamp
      _lastDataReceived = DateTime.now();

      // Cancel retry timer since we received data
      _dataRetryTimer?.cancel();

      // Only log important message types in debug mode
      if (kDebugMode) {
        // Comment out to reduce noise - uncomment if needed for debugging
        // dev.log('Trading WS: Received message type: ${decoded.runtimeType}');
      }

      // Handle new format: {"positions": [[...], [...]], "account": [...]}
      // Example: {"positions": [[387809, 301541, "EURUSD.c", 1, 0.01, 1.16248, 1.16269, -0.21]], "account": [8502.2, 0.0, 8499.9, 8489.54, 82045.37, -2.3]}
      // Also handles empty positions: {"positions": [], "account": [8502.2, 0.0, 8499.9, 8489.54, 82045.37, -2.3]}
      if (decoded is Map<String, dynamic> && decoded.containsKey('positions')) {
        if (kDebugMode) {
          // Only log raw message in debug mode when needed for troubleshooting
          // dev.log('Trading WS: Received positions with account data format');
          // dev.log('Trading WS: Raw message: $message');
        }
        final positionsArray = decoded['positions'];
        final accountArray = decoded['account'];

        // positionsArray can be empty, which is valid (no open positions)
        if (positionsArray is List) {
          _handlePositionsAndAccountFormat(positionsArray, accountArray);
          return;
        } else {
          if (kDebugMode) {
            dev.log(
              'Trading WS: positions is not a List, type: ${positionsArray.runtimeType}',
            );
          }
        }
      }

      // Handle raw array format: [[...], [...]]
      // Positions format: [382703, 301333, "GBPUSD.c", 1, 0.02, 1.27500, 1.27450, -10.0] (8 elements)
      // Pending orders format: [301541, 387776, "EURUSD.c", 1.1642, 1.16, 1.0, "buy"] (7 elements)
      if (decoded is List) {
        // Check if it's an array of arrays
        if (decoded.isNotEmpty && decoded[0] is List) {
          final firstItem = decoded[0] as List;

          if (firstItem.length >= 8) {
            // This is positions array (8+ elements)
            if (kDebugMode) {
              // Commented out to reduce log noise - uncomment if needed
              // dev.log('Trading WS: Received array of positions: ${decoded.length} positions');
            }
            _handlePositionsArrayFormat(decoded);
            return;
          } else if (firstItem.length >= 7) {
            // This is pending orders array (7 elements) from subscribe_pending_orders
            if (kDebugMode) {
              // Commented out to reduce log noise - uncomment if needed
              // dev.log('Trading WS: Received array of pending orders: ${decoded.length} orders');
            }
            _handlePendingOrdersArrayFormat(decoded);
            return;
          }
        }
        // Single item array
        else {
          if (decoded.length >= 8) {
            if (kDebugMode) {
              // dev.log('Trading WS: Received single position array');
            }
            _handlePositionsArrayFormat([decoded]);
            return;
          } else if (decoded.length >= 7) {
            if (kDebugMode) {
              // dev.log('Trading WS: Received single pending order array');
            }
            _handlePendingOrdersArrayFormat([decoded]);
            return;
          }
        }
      }

      // Handle old JSON object format (backward compatibility)
      if (decoded is Map<String, dynamic>) {
        if (kDebugMode) {
          // dev.log('Trading WS: Received old JSON object format');
        }

        // Check if this is trading data
        if (decoded.containsKey('openPositions') ||
            decoded.containsKey('pendingOrders')) {
          final tradingResponse = WebSocketTradingResponse.fromJson(decoded);
          // Light debounce for smooth updates (50ms)
          _updateDebounceTimer?.cancel();
          _updateDebounceTimer = Timer(const Duration(milliseconds: 50), () {
            if (!_isDisposed) {
              _tradingController.updateWebSocketData(tradingResponse);
              if (kDebugMode) {
                // dev.log('Trading WS: Updated trading data successfully');
              }
            }
          });
        }
      }
    } catch (e) {
      // Always log errors
      if (kDebugMode) {
        dev.log('Trading WS: Error parsing message: $e');
        dev.log('Trading WS: Raw message: $message');
      }
    }
  }

  // Handle positions and account format
  // Format: {"positions": [[...], [...]], "account": [balance, credit, equity, marginFree, marginLevel, floating]}
  // Example: {"positions": [[387809, 301541, "EURUSD.c", 1, 0.01, 1.16248, 1.16269, -0.21]], "account": [8502.2, 0.0, 8499.9, 8489.54, 82045.37, -2.3]}
  void _handlePositionsAndAccountFormat(
    List<dynamic> positionsArray,
    dynamic accountArray,
  ) {
    try {
      final List<TradingPosition> positions = [];
      List<AccountInfo> accountInfos = [];

      // Parse positions array
      for (final positionData in positionsArray) {
        if (positionData is! List || positionData.length < 8) {
          if (kDebugMode) {
            dev.log(
              'Trading WS: Skipping invalid position data: $positionData',
            );
          }
          continue;
        }

        try {
          // Parse array: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit]
          final positionId = int.tryParse(positionData[0].toString()) ?? 0;
          final mt5Account = int.tryParse(positionData[1].toString()) ?? 0;
          final symbol = positionData[2].toString();
          final actionValue =
              int.tryParse(positionData[3].toString()) ??
              0; // 0 = Buy, 1 = Sell
          final volume = double.tryParse(positionData[4].toString()) ?? 0.0;
          final priceOpen = double.tryParse(positionData[5].toString()) ?? 0.0;
          final priceCurrent =
              double.tryParse(positionData[6].toString()) ?? 0.0;
          final profit = double.tryParse(positionData[7].toString()) ?? 0.0;

          // Convert action: 0 = Buy, 1 = Sell
          final action = actionValue == 0 ? 'Buy' : 'Sell';

          // Create TradingPosition from array data
          final position = TradingPosition(
            mt5Account: mt5Account,
            position: positionId,
            action: action,
            volume: volume.toString(),
            priceOpen: priceOpen.toString(),
            priceSL: '0', // Not in array, default to 0
            priceTP: '0', // Not in array, default to 0
            priceCurrent: priceCurrent.toString(),
            closeTime: '', // Not in array
            timeCreate: '', // Not in array
            symbol: symbol,
            logo: '', // Will be set later if needed
            profit: profit,
            digits: 5, // Default, can be calculated from symbol if needed
          );

          positions.add(position);
          if (kDebugMode) {
            // Commented out to reduce noise - fires for every position
            // dev.log('Trading WS: Parsed position: $symbol $action $volume @ $priceOpen (P&L: $profit)');
          }
        } catch (e) {
          if (kDebugMode) {
            dev.log('Trading WS: Error parsing position: $e');
          }
        }
      }

      // Parse account array: [balance, credit, equity, marginFree, marginLevel, floating]
      // Example: [8502.2, 0.0, 8499.9, 8489.54, 82045.37, -2.3]
      if (accountArray != null) {
        if (accountArray is List && accountArray.length >= 6) {
          try {
            final balance = double.tryParse(accountArray[0].toString()) ?? 0.0;
            final credit = double.tryParse(accountArray[1].toString()) ?? 0.0;
            final equity = double.tryParse(accountArray[2].toString()) ?? 0.0;
            final marginFree =
                double.tryParse(accountArray[3].toString()) ?? 0.0;
            final marginLevel =
                double.tryParse(accountArray[4].toString()) ?? 0.0;
            final floating = double.tryParse(accountArray[5].toString()) ?? 0.0;

            // Calculate used margin: equity - marginFree (or balance - marginFree if equity not available)
            // Margin = Used margin for open positions
            final margin =
                equity > 0
                    ? (equity - marginFree).abs()
                    : (balance - marginFree).abs();

            // Create AccountInfo from array data
            final accountInfo = AccountInfo(
              assets: balance + credit, // Assets = Balance + Credit
              balance: balance,
              blockedCommission: 0.0, // Not in array
              blockedProfit: 0.0, // Not in array
              credit: credit,
              currencyDigits: 2, // Default
              equity: equity,
              floating: floating,
              liabilities: 0.0, // Not in array
              login:
                  int.tryParse(
                    _accountController.activeMT5Account?.metaAccountNumber ??
                        '0',
                  ) ??
                  0,
              margin: margin,
              marginFree: marginFree,
              marginInitial: 0.0, // Not in array
              marginLevel: marginLevel,
              marginLeverage: 0, // Not in array
              marginMaintenance: 0.0, // Not in array
              profit: floating, // Profit is same as floating
              soActivation: 0.0, // Not in array
              soEquity: 0.0, // Not in array
              soLevel: 0.0, // Not in array
              soMargin: 0.0, // Not in array
              soTime: 0.0, // Not in array
              storage: 0.0, // Not in array
            );

            accountInfos = [accountInfo];
            if (kDebugMode) {
              // Commented out to reduce noise - fires frequently
              // dev.log('Trading WS: Parsed account info - Balance: $balance, Equity: $equity, Margin: $margin, Floating: $floating');
            }
          } catch (e) {
            if (kDebugMode) {
              dev.log('Trading WS: Error parsing account data: $e');
            }
          }
        } else {
          if (kDebugMode) {
            dev.log(
              'Trading WS: account array is invalid - type: ${accountArray.runtimeType}, length: ${accountArray is List ? accountArray.length : "N/A"}',
            );
          }
        }
      } else {
        if (kDebugMode) {
          dev.log('Trading WS: account array is null or missing');
        }
      }

      // Always create OpenPositionsData and update controller, even if positions are empty
      // This ensures account info is updated even when there are no open positions
      final openPositionsData = OpenPositionsData(
        positions: positions,
        accountinfo: accountInfos.isNotEmpty ? accountInfos : [],
      );

      // Create WebSocketTradingResponse and update controller
      final tradingResponse = WebSocketTradingResponse(
        openPositions: openPositionsData,
        pendingOrders: null,
        realtime: true,
        serverTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      // Light debounce to prevent flickering but keep updates smooth (50ms is fast enough)
      _updateDebounceTimer?.cancel();
      _updateDebounceTimer = Timer(const Duration(milliseconds: 50), () {
        if (!_isDisposed) {
          _tradingController.updateWebSocketData(tradingResponse);
          if (kDebugMode) {
            // Commented out to reduce noise - fires on every update
            // dev.log('Trading WS: Updated ${positions.length} positions and ${accountInfos.length} account info(s)');
            // dev.log('Trading WS: Account balance: ${accountInfos.isNotEmpty ? accountInfos.first.balance : "N/A"}, Equity: ${accountInfos.isNotEmpty ? accountInfos.first.equity : "N/A"}');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error handling positions and account format: $e');
      }
    }
  }

  // Handle array format positions (raw array without account data)
  // Format: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit]
  // Example: [382703, 301333, "GBPUSD.c", 1, 0.02, 1.27500, 1.27450, -10.0]
  void _handlePositionsArrayFormat(List<dynamic> positionsArray) {
    try {
      final List<TradingPosition> positions = [];

      for (final positionData in positionsArray) {
        if (positionData is! List || positionData.length < 8) {
          if (kDebugMode) {
            dev.log(
              'Trading WS: Skipping invalid position data: $positionData',
            );
          }
          continue;
        }

        try {
          // Parse array: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit]
          final positionId = int.tryParse(positionData[0].toString()) ?? 0;
          final mt5Account = int.tryParse(positionData[1].toString()) ?? 0;
          final symbol = positionData[2].toString();
          final actionValue =
              int.tryParse(positionData[3].toString()) ??
              0; // 0 = Buy, 1 = Sell
          final volume = double.tryParse(positionData[4].toString()) ?? 0.0;
          final priceOpen = double.tryParse(positionData[5].toString()) ?? 0.0;
          final priceCurrent =
              double.tryParse(positionData[6].toString()) ?? 0.0;
          final profit = double.tryParse(positionData[7].toString()) ?? 0.0;

          // Convert action: 0 = Buy, 1 = Sell
          final action = actionValue == 0 ? 'Buy' : 'Sell';

          // Create TradingPosition from array data
          final position = TradingPosition(
            mt5Account: mt5Account,
            position: positionId,
            action: action,
            volume: volume.toString(),
            priceOpen: priceOpen.toString(),
            priceSL: '0', // Not in array, default to 0
            priceTP: '0', // Not in array, default to 0
            priceCurrent: priceCurrent.toString(),
            closeTime: '', // Not in array
            timeCreate: '', // Not in array
            symbol: symbol,
            logo: '', // Will be set later if needed
            profit: profit,
            digits: 5, // Default, can be calculated from symbol if needed
          );

          positions.add(position);
          if (kDebugMode) {
            // Commented out to reduce noise - fires for every position
            // dev.log('Trading WS: Parsed position: $symbol $action $volume @ $priceOpen (P&L: $profit)');
          }
        } catch (e) {
          if (kDebugMode) {
            dev.log('Trading WS: Error parsing position: $e');
          }
        }
      }

      if (positions.isNotEmpty) {
        // Create OpenPositionsData from parsed positions
        final openPositionsData = OpenPositionsData(
          positions: positions,
          accountinfo: [], // Account info not in array format
        );

        // Create WebSocketTradingResponse and update controller
        final tradingResponse = WebSocketTradingResponse(
          openPositions: openPositionsData,
          pendingOrders: null,
          realtime: true,
          serverTimestamp: DateTime.now().millisecondsSinceEpoch,
        );

        // Light debounce for smooth updates (50ms)
        _updateDebounceTimer?.cancel();
        _updateDebounceTimer = Timer(const Duration(milliseconds: 50), () {
          if (!_isDisposed) {
            _tradingController.updateWebSocketData(tradingResponse);
            if (kDebugMode) {
              // Commented out to reduce noise
              // dev.log('Trading WS: Updated ${positions.length} positions from array format');
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error handling positions array: $e');
      }
    }
  }

  // Handle pending orders array format from subscribe_pending_orders
  // Response format: [[301541, 387776, "EURUSD.c", 1.1642, 1.16, 1.0, "buy"], ...]
  // Format: [MT5Account, OrderID, Symbol, PriceOrder, PriceCurrent, Volume, Action]
  // Action is string: "buy", "sell", "Buy Limit", "Sell Limit", etc.
  void _handlePendingOrdersArrayFormat(List<dynamic> pendingOrdersArray) {
    try {
      final List<PendingOrder> pendingOrders = [];

      for (final orderData in pendingOrdersArray) {
        if (orderData is! List || orderData.length < 7) {
          if (kDebugMode) {
            dev.log(
              'Trading WS: Skipping invalid pending order data: $orderData',
            );
          }
          continue;
        }

        try {
          // Parse pending order array format (7 elements)
          // [0]: MT5Account, [1]: OrderID, [2]: Symbol, [3]: PriceOrder,
          // [4]: PriceCurrent, [5]: Volume, [6]: Action (string)
          final mt5Account = int.tryParse(orderData[0].toString()) ?? 0;
          final orderId = int.tryParse(orderData[1].toString()) ?? 0;
          final symbol = orderData[2].toString();
          final priceOrder = double.tryParse(orderData[3].toString()) ?? 0.0;
          final priceCurrent = double.tryParse(orderData[4].toString()) ?? 0.0;
          final volume = double.tryParse(orderData[5].toString()) ?? 0.0;
          final actionStr = orderData[6].toString().toLowerCase();

          // Convert action string to proper format
          String action;
          if (actionStr.contains('buy')) {
            action = 'Buy Limit';
          } else if (actionStr.contains('sell')) {
            action = 'Sell Limit';
          } else {
            // Try to parse as is or default
            action =
                actionStr.isEmpty
                    ? 'Buy Limit'
                    : actionStr[0].toUpperCase() + actionStr.substring(1);
          }

          final pendingOrder = PendingOrder(
            mt5Account: mt5Account,
            order: orderId,
            action: action,
            symbol: symbol,
            priceOrder: priceOrder,
            priceCurrent: priceCurrent,
            volume: volume,
            priceSL: 0.0, // Not in array, default to 0
            priceTP: 0.0, // Not in array, default to 0
            timeCreate: '', // Not in array
            state: 'pending',
            logo: '', // Will be set later if needed
          );

          pendingOrders.add(pendingOrder);
          if (kDebugMode) {
            // Commented out to reduce noise - fires for every pending order
            // dev.log('Trading WS: Parsed pending order: $symbol $action $volume @ $priceOrder (Current: $priceCurrent)');
          }
        } catch (e) {
          if (kDebugMode) {
            dev.log('Trading WS: Error parsing pending order: $e');
            dev.log('Trading WS: Order data: $orderData');
          }
        }
      }

      // Always update pending orders (even if empty, to clear existing)
      final pendingOrdersData = PendingOrdersData(pendingOrders: pendingOrders);

      final tradingResponse = WebSocketTradingResponse(
        openPositions: null, // Don't update positions
        pendingOrders: pendingOrdersData,
        realtime: true,
        serverTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      // Update only pending orders in controller (separate from positions)
      if (tradingResponse.pendingOrders != null) {
        _tradingController.updatePendingOrders(
          tradingResponse.pendingOrders!.pendingOrders,
        );
      }

      if (kDebugMode) {
        // Commented out to reduce noise - fires frequently
        // dev.log('Trading WS: Updated ${pendingOrders.length} pending orders (separate from positions)');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error handling pending orders array: $e');
      }
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_isDisposed || _reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        dev.log('Trading WS: Max reconnection attempts reached or disposed');
      }
      return;
    }

    if (isReconnecting.value) return;

    isReconnecting.value = true;
    _reconnectAttempts++;

    if (kDebugMode) {
      dev.log(
        'Trading WS: Scheduling reconnect attempt $_reconnectAttempts in ${_reconnectDelay.inSeconds}s',
      );
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed) {
        if (kDebugMode) {
          dev.log('Trading WS: Attempting reconnection...');
        }
        _initializeWebSocket();
      }
    });
  }

  // Disconnect WebSocket
  void _disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Cancel all timers
    _subscriptionRefreshTimer?.cancel();
    _subscriptionRefreshTimer = null;
    _dataRetryTimer?.cancel();
    _dataRetryTimer = null;
    _updateDebounceTimer?.cancel();
    _updateDebounceTimer = null;

    if (isConnected.value) {
      try {
        channel.sink.close();
        if (kDebugMode) {
          dev.log('Trading WS: Disconnected');
        }
      } catch (e) {
        if (kDebugMode) {
          dev.log('Trading WS: Error during disconnect: $e');
        }
      }
    }

    isConnected.value = false;
    isReconnecting.value = false;
    _lastDataReceived = null;
  }

  // Manual reconnection
  void reconnect() {
    if (_isDisposed) return;

    if (kDebugMode) {
      dev.log('Trading WS: Manual reconnection requested');
    }
    _disconnectWebSocket();
    _reconnectAttempts = 0;
    _initializeWebSocket();
  }

  // Manual disconnect
  void disconnect() {
    if (kDebugMode) {
      dev.log('Trading WS: Manual disconnect requested');
    }
    _disconnectWebSocket();
  }

  // Refresh trading data
  void refreshTradingData() {
    if (isConnected.value && !_isDisposed) {
      if (kDebugMode) {
        dev.log('Trading WS: Manual refresh requested');
      }
      _requestTradingData();
    } else {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot refresh - not connected or disposed');
      }
    }
  }

  // Force refresh trading data (clears cache and requests fresh data)
  void forceRefreshTradingData() {
    if (kDebugMode) {
      dev.log('Trading WS: Force refresh requested');
    }

    // Clear all trading data first
    _tradingController.clearAllTradingData();

    // Request fresh data
    if (isConnected.value && !_isDisposed) {
      _requestTradingData();
    } else {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot force refresh - not connected or disposed');
      }
    }
  }

  // Update account without disconnecting (faster account switching)
  // This just refreshes the subscription with new account instead of full reconnect
  void updateAccountAndRefresh() {
    if (kDebugMode) {
      dev.log('Trading WS: Updating account and refreshing subscription');
    }

    // If connected, just refresh subscription with new account
    if (isConnected.value && !_isDisposed) {
      // DON'T clear all data immediately to prevent flickering
      // Data will be replaced with new account data when it arrives
      // _tradingController.clearAllTradingData(); // Commented to prevent flickering

      // Request fresh data with new account immediately
      // This will update the data without clearing first (prevents flickering)
      _requestTradingData();
    } else {
      // If not connected, initialize connection
      _initializeWebSocket();
    }
  }

  // Clear all trading data and disconnect (called on logout)
  void clearAllDataAndDisconnect() {
    if (kDebugMode) {
      dev.log('Trading WS: Clearing all data and disconnecting...');
    }

    // Disconnect WebSocket
    _disconnectWebSocket();

    // Clear trading controller data if it exists
    try {
      if (Get.isRegistered<TradingController>()) {
        final tradingController = Get.find<TradingController>();
        tradingController.clearAllTradingData();
        if (kDebugMode) {
          dev.log('Trading WS: Cleared trading controller data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error clearing trading controller: $e');
      }
    }

    // Reset reconnection attempts
    _reconnectAttempts = 0;

    if (kDebugMode) {
      dev.log('Trading WS: Data cleared and disconnected successfully');
    }
  }

  // Reset and reconnect with new account (called on login)
  void resetAndReconnect() {
    if (kDebugMode) {
      dev.log('Trading WS: Resetting and reconnecting...');
    }

    // Clear all data first
    clearAllDataAndDisconnect();

    // Reset disposed flag
    _isDisposed = false;

    // Reconnect after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        _initializeWebSocket();
      }
    });

    if (kDebugMode) {
      dev.log('Trading WS: Reset and reconnect initiated');
    }
  }
}
