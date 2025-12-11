import 'dart:async';
import 'dart:convert';
import 'dart:io'; // ✅ ADD: For IOWebSocketChannel and WebSocket
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/models/order_types.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/services/websocket_endpoint_helper.dart';
import 'package:web_socket_channel/io.dart'; // ✅ CHANGED: Use IOWebSocketChannel instead

class TradingWebSocketService extends GetxService with WidgetsBindingObserver {
  // Connection state - support multiple concurrent connections
  final RxBool isConnected = false.obs;
  final RxBool isReconnecting = false.obs;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  bool _isDisposed = false;
  bool _isConnecting = false; // Guard to prevent concurrent connections

  // ✅ CHANGED: Use IOWebSocketChannel for ping/pong support
  IOWebSocketChannel? _channel; // Changed from late WebSocketChannel
  WebSocket? _rawWebSocket; // Raw socket reference for ping control

  // Separate channels for open positions, pending orders, market watch, and symbols
  IOWebSocketChannel? _openPositionsChannel; // Changed type
  IOWebSocketChannel? _pendingOrdersChannel; // Changed type
  IOWebSocketChannel? _marketWatchChannel; // Changed type
  IOWebSocketChannel? _symbolsChannel; // Changed type

  // Connection state for each channel
  final RxBool isOpenPositionsConnected = false.obs;
  final RxBool isPendingOrdersConnected = false.obs;
  final RxBool isMarketWatchConnected = false.obs;
  final RxBool isSymbolsConnected = false.obs;
  bool _isConnectingOpenPositions = false;
  bool _isConnectingPendingOrders = false;
  bool _isConnectingMarketWatch = false;
  bool _isConnectingSymbols = false;
  bool _loggedFirstMessage = false;

  // Reconnect state for each channel
  Timer? _openPositionsReconnectTimer;
  Timer? _pendingOrdersReconnectTimer;
  Timer? _marketWatchReconnectTimer;
  Timer? _symbolsReconnectTimer;
  int _openPositionsReconnectAttempts = 0;
  int _pendingOrdersReconnectAttempts = 0;
  int _marketWatchReconnectAttempts = 0;
  int _symbolsReconnectAttempts = 0;

  // Subscription state tracking
  Timer? _subscriptionRefreshTimer;
  Timer? _dataRetryTimer;
  DateTime? _lastDataReceived;
  // Track account used for last subscription to drop stale frames
  String? _lastSubscribedAccount;
  // Session gating to ignore late frames from previous connections
  int _sessionId = 0;
  int _activeSessionId = 0;

  // Debounce timer to prevent rapid updates causing flickering
  Timer? _updateDebounceTimer;

  // Unsubscribe/resubscribe state
  Completer<void>? _unsubscribeCompleter;

  // Track current endpoint to avoid unnecessary reconnections
  String? _currentEndpoint;

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

    // ✅ Wait for account data from API before initializing WebSocket
    // This ensures we use the correct endpoint (MT5 vs self-hosted) from the start
    // Much faster than fixed delay - connects as soon as account API returns
    _waitForAccountAndConnect();
  }

  /// Wait for AccountController to load account data, then connect with correct endpoint
  void _waitForAccountAndConnect() async {
    try {
      // ✅ FIX: Check stored account first (from initServices)
      final storedAccount = WebSocketEndpointHelper.getStoredPrimaryAccount();
      if (storedAccount != null) {
        if (kDebugMode) {
          final accountType = WebSocketEndpointHelper.getAccountType(
            storedAccount,
          );
          dev.log(
            'Trading WS: Using stored primary account from initialization: ${storedAccount.metaAccountNumber} ($accountType)',
          );
        }
        _initializeWebSocket();
        _initializeAllConnections();
        return;
      }

      // Fallback to waiting for AccountController
      // Wait for account controller to finish loading accounts from API
      await _accountController.waitForInitialization();

      if (_isDisposed) return;

      final activeAccount = _accountController.activeMT5Account;
      if (activeAccount != null) {
        // Account loaded - connect with correct endpoints
        final accountType =
            activeAccount.tradingServer.toUpperCase() == "MT5"
                ? "MT5"
                : "Self-hosted";
        if (kDebugMode) {
          dev.log(
            'Trading WS: Account loaded, initializing with $accountType account: ${activeAccount.metaAccountNumber}',
          );
        }
        _initializeWebSocket();
        _initializeAllConnections();
      } else {
        // No account yet - listen for account changes
        if (kDebugMode) {
          dev.log('Trading WS: No account loaded yet, waiting for account...');
        }
        _accountController.activeMT5AccountRx.listen((account) {
          if (account != null && !isConnected.value && !_isDisposed) {
            final accountType =
                account.tradingServer.toUpperCase() == "MT5"
                    ? "MT5"
                    : "Self-hosted";
            if (kDebugMode) {
              dev.log(
                'Trading WS: Account loaded, initializing with $accountType account: ${account.metaAccountNumber}',
              );
            }
            _initializeWebSocket();
            _initializeAllConnections();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error waiting for account: $e');
      }
      // Fallback: connect with default endpoint after short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed && !isConnected.value) {
          _initializeWebSocket();
          _initializeAllConnections();
        }
      });
    }
  }

  /// Initialize all WebSocket connections simultaneously for fast data loading
  /// All 4 channels connect at once - no delays between connections
  void _initializeAllConnections() {
    // Connect all channels simultaneously
    _connectToMarketWatch();
    _connectToOpenPositions();
    _connectToPendingOrders();

    // Note: Symbols connection is lazy-loaded when chart screen opens
  }

  @override
  void onClose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disconnectWebSocket();
    _disconnectOpenPositions();
    _disconnectPendingOrders();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // ✅ FORCE RECONNECT - Don't trust isConnected flag
        if (!_isDisposed) {
          if (kDebugMode) {
            dev.log('Trading WS: App resumed, forcing reconnect');
          }

          // Close stale connections
          _rawWebSocket?.close();
          _channel?.sink.close();

          // Force fresh reconnect
          _reconnectAttempts = 0;
          _initializeWebSocket();
        }
        break;
      case AppLifecycleState.paused:
        if (kDebugMode) {
          // dev.log('Trading WS: App paused, maintaining connection');
        }
        break;
      case AppLifecycleState.detached:
        if (kDebugMode) {
          // dev.log('Trading WS: App detached, closing connection');
        }
        _disconnectWebSocket();
        break;
      case AppLifecycleState.inactive:
        if (kDebugMode) {
          // dev.log('Trading WS: App inactive');
        }
        break;
      case AppLifecycleState.hidden:
        if (kDebugMode) {
          // dev.log('Trading WS: App hidden');
        }
        break;
    }
  }

  // Initialize WebSocket connection - use conditional endpoints based on account type
  void _initializeWebSocket() {
    // Get current tab to determine endpoint
    final currentTab = _tradingController.selectedTab;
    final activeAccount = _accountController.activeMT5Account;

    // ✅ Use centralized endpoint helper based on current tab
    String endpoint;
    if (currentTab == 0) {
      // Market tab (open positions)
      endpoint = WebSocketEndpointHelper.getOpenPositionsEndpoint(
        activeAccount,
      );
    } else if (currentTab == 1) {
      // Pending tab (pending orders)
      endpoint = WebSocketEndpointHelper.getPendingOrdersEndpoint(
        activeAccount,
      );
    } else {
      // Other tabs - use default endpoint (open positions)
      endpoint = WebSocketEndpointHelper.getOpenPositionsEndpoint(
        activeAccount,
      );
    }

    // Use centralized helper to get full URL
    final wsUrl = WebSocketEndpointHelper.getFullUrl(endpoint);

    // Add logging for endpoint selection
    final accountType = WebSocketEndpointHelper.getAccountType(activeAccount);
    if (kDebugMode) {
      WebSocketEndpointHelper.logSwitchStep(
        'Trading connect start',
        url: wsUrl,
      );
      dev.log(
        'Trading WS: Using $accountType endpoint: $wsUrl (Account: ${activeAccount?.metaAccountNumber ?? "N/A"}, trading_server: ${activeAccount?.tradingServer ?? "N/A"}, tab: $currentTab)',
      );
      dev.log(
        'Trading WS: Endpoint change? prev=${_currentEndpoint ?? "none"} -> new=$wsUrl',
      );
    }

    // Check if already connected to the same endpoint
    if (isConnected.value && _currentEndpoint == wsUrl) {
      if (kDebugMode) {
        // dev.log(
        //   'Trading WS: Already connected to $wsUrl, skipping reconnection',
        // );
      }
      return;
    }

    // If connected to different endpoint, disconnect first
    if (isConnected.value && _currentEndpoint != wsUrl) {
      // if (kDebugMode) {
      //   dev.log('Trading WS: Switching from $_currentEndpoint to $wsUrl');
      // }
      _disconnectWebSocket();
      // Wait a bit for clean disconnect - reduced for real-time trading
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!_isDisposed) {
          _connectToEndpoint(wsUrl, currentTab);
        }
      });
      return;
    }

    // Not connected, connect now
    if (!isConnected.value) {
      _connectToEndpoint(wsUrl, currentTab);
    }
  }

  // Connect to a specific endpoint
  Future<void> _connectToEndpoint(String wsUrl, int tab) async {
    if (_isConnecting) {
      return;
    }

    try {
      _loggedFirstMessage = false;
      _isConnecting = true;
      // Increment session and mark active
      _activeSessionId = ++_sessionId;

      // ✅ CREATE RAW WEBSOCKET WITH PING SUPPORT
      _rawWebSocket = await WebSocket.connect(
        wsUrl,
        headers: {'Connection': 'Upgrade', 'Upgrade': 'websocket'},
      );

      // ✅ CRITICAL: Enable automatic ping/pong
      // Send ping every 25 seconds (before server's 30s timeout)
      _rawWebSocket!.pingInterval = const Duration(seconds: 25);

      // ✅ WRAP IN IO WEBSOCKET CHANNEL
      _channel = IOWebSocketChannel(_rawWebSocket!);

      _currentEndpoint = wsUrl;
      isConnected.value = true;
      _reconnectAttempts = 0;
      isReconnecting.value = false;

      // Listen to messages
      _channel!.stream.listen(
        (message) => _handleSocketMessageWithSession(_activeSessionId, message),
        onError: (error) {
          if (kDebugMode) {
            dev.log('Trading WS error: $error');
          }
          isConnected.value = false;
          _currentEndpoint = null;
          _isConnecting = false;
          _scheduleReconnect();
        },
        onDone: () {
          if (kDebugMode) {
            dev.log('Trading WS: Connection closed');
          }
          isConnected.value = false;
          _currentEndpoint = null;
          _isConnecting = false;
          _scheduleReconnect();
        },
      );

      // Request trading data after connection
      Future.delayed(const Duration(milliseconds: 100), () {
        if (isConnected.value && !_isDisposed) {
          _requestTradingData();
          _startPeriodicRefresh();
          WebSocketEndpointHelper.logSwitchStep(
            'Trading connected',
            url: wsUrl,
          );
        }
        _isConnecting = false;
      });
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Initialization failed: $e');
      }
      isConnected.value = false;
      _currentEndpoint = null;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  // Wrapper to drop frames from old sessions
  void _handleSocketMessageWithSession(int session, dynamic message) {
    if (_isDisposed) return;
    if (session != _activeSessionId) {
      // Stale frame from previous connection
      return;
    }
    if (!_loggedFirstMessage) {
      _loggedFirstMessage = true;
      WebSocketEndpointHelper.logSwitchStep(
        'Trading first message',
        url: _currentEndpoint,
      );
    }
    _handleSocketMessage(message);
  }

  // Request trading data from WebSocket
  void _requestTradingData() async {
    if (_isDisposed || !isConnected.value) {
      if (kDebugMode) {
        // dev.log('Trading WS: Cannot request data - disposed or not connected');
      }
      return;
    }

    // Use getAuthToken for /ws/op endpoint (same as other new endpoints)
    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) {
      if (kDebugMode) {
        // dev.log('Trading WS: No auth token, retrying in 2 seconds...');
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
        // dev.log('Trading WS: Invalid account number, retrying in 2 seconds...');
      }
      Timer(const Duration(seconds: 2), () {
        if (isConnected.value && !_isDisposed) {
          _requestTradingData();
        }
      });
      return;
    }

    if (kDebugMode) {
      WebSocketEndpointHelper.logSwitchStep(
        'Trading subscribe',
        url: _currentEndpoint,
        payload: {"authID": authId, "trading_account": accountNumber},
      );
    }

    // Determine subscription based on current endpoint, not just selected tab
    // ✅ Use centralized endpoint helper for legacy compatibility checks
    final pendingUrl = WebSocketEndpointHelper.getPendingOrdersUrl(
      activeAccount,
    );
    final marketUrl = WebSocketEndpointHelper.getOpenPositionsUrl(
      activeAccount,
    );
    final currentTab = _tradingController.selectedTab;

    // Check if connected to pending orders endpoint (regardless of selected tab)
    final isConnectedToPending = _currentEndpoint == pendingUrl;
    final isConnectedToMarket = _currentEndpoint == marketUrl;

    if (isConnectedToPending) {
      // Connected to /ws/po endpoint - subscribe to pending orders
      final payload = {"authID": authId, "trading_account": accountNumber};
      if (kDebugMode) {
        dev.log(
          'Trading WS: Subscribing pending orders @$_currentEndpoint payload=$payload',
        );
      }
      _sendEvent(payload);
      _lastSubscribedAccount = accountNumber;
    } else if (isConnectedToMarket) {
      // Connected to /ws/op endpoint - subscribe to open positions
      final payload = {"authID": authId, "trading_account": accountNumber};
      if (kDebugMode) {
        dev.log(
          'Trading WS: Subscribing open positions @$_currentEndpoint payload=$payload',
        );
      }
      _sendEvent(payload);
      _lastSubscribedAccount = accountNumber;
    } else if (currentTab == 1) {
      // Pending tab (1) - use /ws/po endpoint with new format
      if (kDebugMode) {
        // dev.log(
        //   'Trading WS: Pending tab active - subscribing to /ws/po for pending orders',
        // );
      }
      // Send subscription in format: { "authID": "user_token", "trading_account": "301023" }
      _sendEvent({"authID": authId, "trading_account": accountNumber});
      _lastSubscribedAccount = accountNumber;
      if (kDebugMode) {
        // dev.log(
        //   'Trading WS: Sent /ws/po subscription for account: $accountNumber',
        // );
      }
    } else if (currentTab == 0) {
      // Market tab (0) - use /ws/op endpoint with new format
      if (kDebugMode) {
        // dev.log(
        //   'Trading WS: Market tab active - subscribing to /ws/op for open positions',
        // );
      }
      // Send subscription in format: { "authID": "user_token", "trading_account": "301023" }
      _sendEvent({"authID": authId, "trading_account": accountNumber});
      _lastSubscribedAccount = accountNumber;
      if (kDebugMode) {
        // dev.log(
        //   'Trading WS: Sent /ws/op subscription for account: $accountNumber',
        // );
      }
    } else {
      // Close tab (2) - subscribe to all groups for positions (legacy)
      if (kDebugMode) {
        // dev.log('Trading WS: Close tab active - subscribing to all groups');
      }
      _sendEvent({"type": "subscribe_all_groups", "account": accountNumber});
      _lastSubscribedAccount = accountNumber;
    }

    // Set up retry timer if no data received within 3 seconds
    _setupDataRetryTimer();
  }

  // Setup retry timer if data doesn't arrive
  void _setupDataRetryTimer() {
    _dataRetryTimer?.cancel();
    _dataRetryTimer = Timer(const Duration(seconds: 3), () async {
      if (_isDisposed || !isConnected.value) return;

      // Check if we received data after last subscription
      if (_lastDataReceived == null ||
          DateTime.now().difference(_lastDataReceived!).inSeconds > 2) {
        if (kDebugMode) {
          // dev.log(
          //   'Trading WS: No data received after subscription, retrying...',
          // );
        }
        // Retry subscription
        final activeAccount = _accountController.activeMT5Account;
        final accountNumber = activeAccount?.metaAccountNumber ?? "0";
        final currentTab = _tradingController.selectedTab;

        if (currentTab == 1) {
          // Pending tab - use /ws/po endpoint format
          final authId = await SecureStorageService.getAuthToken();
          if (authId != null && authId.isNotEmpty) {
            _sendEvent({"authID": authId, "trading_account": accountNumber});
          }
        } else if (currentTab == 0) {
          // Market tab - reconnect to /ws/op
          _disconnectWebSocket();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_isDisposed) {
              _initializeWebSocket();
            }
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
        // dev.log('Trading WS: Periodic refresh - maintaining subscription');
      }
      _requestTradingData();
    });
  }

  // Refresh data based on current tab - reconnect to ensure correct endpoint
  void refreshDataForCurrentTab() {
    if (_isDisposed) {
      if (kDebugMode) {
        // dev.log('Trading WS: Cannot refresh - disposed');
      }
      return;
    }

    // Cancel retry timer since we're manually refreshing
    _dataRetryTimer?.cancel();

    // ✅ FIX: Check account type to determine correct endpoint (MT5 vs self-hosted)
    final activeAccount = _accountController.activeMT5Account;

    // ✅ Use centralized endpoint helper
    final currentTab = _tradingController.selectedTab;
    final expectedEndpoint =
        currentTab == 0
            ? WebSocketEndpointHelper.getOpenPositionsUrl(activeAccount)
            : currentTab == 1
            ? WebSocketEndpointHelper.getPendingOrdersUrl(activeAccount)
            : _currentEndpoint;

    // Check if already connected to correct endpoint
    if (isConnected.value && _currentEndpoint == expectedEndpoint) {
      if (kDebugMode) {
        // dev.log(
        //   'Trading WS: Already connected to correct endpoint for tab $currentTab, just refreshing subscription',
        // );
      }
      // Just refresh the subscription without reconnecting
      _requestTradingData();
      return;
    }

    if (kDebugMode) {
      // dev.log(
      //   'Trading WS: Refreshing for tab $currentTab - reconnecting to correct endpoint',
      // );
    }

    // Need to reconnect to correct endpoint
    _initializeWebSocket();
  }

  // Ensure WebSocket is connected to pending orders endpoint
  // This is called before navigating to pending tab to pre-connect
  Future<void> ensurePendingOrdersConnection() async {
    if (_isDisposed) {
      if (kDebugMode) {
        // dev.log('Trading WS: Cannot ensure pending connection - disposed');
      }
      return;
    }

    // Use separate connection for pending orders
    if (!isPendingOrdersConnected.value) {
      if (kDebugMode) {
        // dev.log('Trading WS: Ensuring connection to pending orders endpoint');
      }
      _connectToPendingOrders();
    } else {
      // Already connected, just refresh subscription
      _requestPendingOrdersData();
    }
  }

  // Ensure WebSocket is connected to open positions endpoint
  // This is called before navigating to market tab to pre-connect
  Future<void> ensureOpenPositionsConnection() async {
    if (_isDisposed) {
      if (kDebugMode) {
        // dev.log(
        //   'Trading WS: Cannot ensure open positions connection - disposed',
        // );
      }
      return;
    }

    // Use separate connection for open positions
    if (!isOpenPositionsConnected.value) {
      if (kDebugMode) {
        // dev.log('Trading WS: Ensuring connection to open positions endpoint');
      }
      _connectToOpenPositions();
    } else {
      // Already connected, just refresh subscription
      _requestOpenPositionsData();
    }
  }

  // Connect to open positions endpoint with conditional MT5 prefix
  void _connectToOpenPositions() {
    if (_isDisposed || _isConnectingOpenPositions) return;

    final activeAccount = _accountController.activeMT5Account;

    // ✅ Validate account exists before determining endpoint
    if (activeAccount == null) {
      if (kDebugMode) {
        dev.log(
          'Trading WS: Cannot connect to open positions - no active account',
        );
      }
      return;
    }

    // ✅ Use centralized endpoint helper
    final openPositionsUrl = WebSocketEndpointHelper.getOpenPositionsUrl(
      activeAccount,
    );

    // Check if already connected
    if (isOpenPositionsConnected.value && _openPositionsChannel != null) {
      if (kDebugMode) {
        dev.log('Trading WS: Already connected to open positions endpoint');
      }
      _requestOpenPositionsData();
      return;
    }

    try {
      _isConnectingOpenPositions = true;
      _openPositionsChannel = IOWebSocketChannel.connect(
        Uri.parse(openPositionsUrl),
      );
      isOpenPositionsConnected.value = true;
      _openPositionsReconnectAttempts = 0;

      if (kDebugMode) {
        // dev.log('Trading WS: Connected to open positions endpoint');
      }

      _openPositionsChannel!.stream.listen(
        (message) {
          if (_isDisposed) return;
          _handleOpenPositionsMessage(message);
        },
        onError: (error) {
          if (kDebugMode) {
            // dev.log('Trading WS: Open positions connection error: $error');
          }
          isOpenPositionsConnected.value = false;
          _scheduleOpenPositionsReconnect();
        },
        onDone: () {
          if (kDebugMode) {
            // dev.log('Trading WS: Open positions connection closed');
          }
          isOpenPositionsConnected.value = false;
          if (!_isDisposed) {
            _scheduleOpenPositionsReconnect();
          }
        },
        cancelOnError: false,
      );

      // Request data after connection
      Future.delayed(const Duration(milliseconds: 500), () {
        _requestOpenPositionsData();
      });

      _isConnectingOpenPositions = false;
    } catch (e) {
      _isConnectingOpenPositions = false;
      if (kDebugMode) {
        dev.log('Trading WS: Error connecting to open positions: $e');
      }
      _scheduleOpenPositionsReconnect();
    }
  }

  // Connect to pending orders endpoint with conditional MT5 prefix
  void _connectToPendingOrders() {
    if (_isDisposed || _isConnectingPendingOrders) return;

    final activeAccount = _accountController.activeMT5Account;

    // ✅ Validate account exists before determining endpoint
    if (activeAccount == null) {
      if (kDebugMode) {
        dev.log(
          'Trading WS: Cannot connect to pending orders - no active account',
        );
      }
      return;
    }

    // ✅ Use centralized endpoint helper
    final pendingOrdersUrl = WebSocketEndpointHelper.getPendingOrdersUrl(
      activeAccount,
    );

    // Check if already connected
    if (isPendingOrdersConnected.value && _pendingOrdersChannel != null) {
      if (kDebugMode) {
        dev.log('Trading WS: Already connected to pending orders endpoint');
      }
      _requestPendingOrdersData();
      return;
    }

    try {
      _isConnectingPendingOrders = true;
      _pendingOrdersChannel = IOWebSocketChannel.connect(
        Uri.parse(pendingOrdersUrl),
      );
      isPendingOrdersConnected.value = true;
      _pendingOrdersReconnectAttempts = 0;

      if (kDebugMode) {
        dev.log('Trading WS: Connected to pending orders endpoint');
      }

      _pendingOrdersChannel!.stream.listen(
        (message) {
          if (_isDisposed) return;
          _handlePendingOrdersMessage(message);
        },
        onError: (error) {
          if (kDebugMode) {
            dev.log('Trading WS: Pending orders connection error: $error');
          }
          isPendingOrdersConnected.value = false;
          _schedulePendingOrdersReconnect();
        },
        onDone: () {
          if (kDebugMode) {
            dev.log('Trading WS: Pending orders connection closed');
          }
          isPendingOrdersConnected.value = false;
          if (!_isDisposed) {
            _schedulePendingOrdersReconnect();
          }
        },
        cancelOnError: false,
      );

      // Request data after connection
      Future.delayed(const Duration(milliseconds: 500), () {
        _requestPendingOrdersData();
      });

      _isConnectingPendingOrders = false;
    } catch (e) {
      _isConnectingPendingOrders = false;
      if (kDebugMode) {
        dev.log('Trading WS: Error connecting to pending orders: $e');
      }
      _schedulePendingOrdersReconnect();
    }
  }

  // Connect to market watch endpoint with conditional MT5 prefix
  void _connectToMarketWatch() {
    if (_isDisposed || _isConnectingMarketWatch) return;

    final activeAccount = _accountController.activeMT5Account;

    // ✅ Validate account exists before determining endpoint
    if (activeAccount == null) {
      if (kDebugMode) {
        dev.log(
          'Trading WS: Cannot connect to market watch - no active account',
        );
      }
      return;
    }

    // ✅ Use centralized endpoint helper
    final marketWatchUrl = WebSocketEndpointHelper.getMarketWatchUrl(
      activeAccount,
    );

    // Check if already connected
    if (isMarketWatchConnected.value && _marketWatchChannel != null) {
      if (kDebugMode) {
        dev.log('Trading WS: Already connected to market watch endpoint');
      }
      _requestMarketWatchData();
      return;
    }

    _isConnectingMarketWatch = true;
    _marketWatchReconnectAttempts = 0;

    try {
      _marketWatchChannel = IOWebSocketChannel.connect(
        Uri.parse(marketWatchUrl),
      );
      isMarketWatchConnected.value = true;

      if (kDebugMode) {
        dev.log(
          'Trading WS: Connected to market watch endpoint: $marketWatchUrl',
        );
      }

      _marketWatchChannel!.stream.listen(
        (message) => _handleMarketWatchMessage(message),
        onError: (error) {
          if (kDebugMode) {
            dev.log('Trading WS: Market watch connection error: $error');
          }
          isMarketWatchConnected.value = false;
          _scheduleMarketWatchReconnect();
        },
        onDone: () {
          if (kDebugMode) {
            dev.log('Trading WS: Market watch connection closed');
          }
          isMarketWatchConnected.value = false;
          if (!_isDisposed) {
            _scheduleMarketWatchReconnect();
          }
        },
        cancelOnError: false,
      );

      // Request data after connection
      Future.delayed(const Duration(milliseconds: 500), () {
        _requestMarketWatchData();
      });

      _isConnectingMarketWatch = false;
    } catch (e) {
      _isConnectingMarketWatch = false;
      if (kDebugMode) {
        dev.log('Trading WS: Error connecting to market watch: $e');
      }
      _scheduleMarketWatchReconnect();
    }
  }

  /// Ensure Symbols WebSocket is connected (lazy loading)
  /// Call this when user opens chart screen to connect on demand
  void ensureSymbolsConnected() {
    if (_isDisposed) {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot ensure symbols connection - disposed');
      }
      return;
    }

    // Use separate connection for symbols
    if (!isSymbolsConnected.value) {
      if (kDebugMode) {
        dev.log('Trading WS: Ensuring connection to symbols endpoint');
      }
      _connectToSymbols();
    } else {
      // Already connected, just refresh subscription
      _requestSymbolsData();
    }
  }

  // Connect to symbols endpoint with conditional MT5 prefix
  void _connectToSymbols() {
    if (_isDisposed || _isConnectingSymbols) return;

    final activeAccount = _accountController.activeMT5Account;

    // ✅ Validate account exists before determining endpoint
    if (activeAccount == null) {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot connect to symbols - no active account');
      }
      return;
    }

    // ✅ Use centralized endpoint helper
    final symbolsUrl = WebSocketEndpointHelper.getSymbolUrl(activeAccount);

    // Check if already connected
    if (isSymbolsConnected.value && _symbolsChannel != null) {
      if (kDebugMode) {
        dev.log('Trading WS: Already connected to symbols endpoint');
      }
      _requestSymbolsData();
      return;
    }

    _isConnectingSymbols = true;
    _symbolsReconnectAttempts = 0;

    try {
      _symbolsChannel = IOWebSocketChannel.connect(Uri.parse(symbolsUrl));
      isSymbolsConnected.value = true;

      if (kDebugMode) {
        dev.log('Trading WS: Connected to symbols endpoint: $symbolsUrl');
      }

      _symbolsChannel!.stream.listen(
        (message) => _handleSymbolsMessage(message),
        onError: (error) {
          if (kDebugMode) {
            dev.log('Trading WS: Symbols connection error: $error');
          }
          isSymbolsConnected.value = false;
          _scheduleSymbolsReconnect();
        },
        onDone: () {
          if (kDebugMode) {
            dev.log('Trading WS: Symbols connection closed');
          }
          isSymbolsConnected.value = false;
          if (!_isDisposed) {
            _scheduleSymbolsReconnect();
          }
        },
        cancelOnError: false,
      );

      // Request data after connection
      Future.delayed(const Duration(milliseconds: 500), () {
        _requestSymbolsData();
      });

      _isConnectingSymbols = false;
    } catch (e) {
      _isConnectingSymbols = false;
      if (kDebugMode) {
        dev.log('Trading WS: Error connecting to symbols: $e');
      }
      _scheduleSymbolsReconnect();
    }
  }

  // Disconnect open positions connection
  void _disconnectOpenPositions() {
    _openPositionsReconnectTimer?.cancel();
    try {
      _openPositionsChannel?.sink.close();
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error closing open positions connection: $e');
      }
    }
    _openPositionsChannel = null;
    isOpenPositionsConnected.value = false;
  }

  // Disconnect pending orders connection
  void _disconnectPendingOrders() {
    _pendingOrdersReconnectTimer?.cancel();
    try {
      _pendingOrdersChannel?.sink.close();
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error closing pending orders connection: $e');
      }
    }
    _pendingOrdersChannel = null;
    isPendingOrdersConnected.value = false;
  }

  // Disconnect market watch connection
  void _disconnectMarketWatch() {
    _marketWatchReconnectTimer?.cancel();
    try {
      _marketWatchChannel?.sink.close();
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error closing market watch connection: $e');
      }
    }
    _marketWatchChannel = null;
    isMarketWatchConnected.value = false;
  }

  // Disconnect symbols connection
  void _disconnectSymbols() {
    _symbolsReconnectTimer?.cancel();
    try {
      _symbolsChannel?.sink.close();
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error closing symbols connection: $e');
      }
    }
    _symbolsChannel = null;
    isSymbolsConnected.value = false;
  }

  // Schedule reconnect for open positions
  void _scheduleOpenPositionsReconnect() {
    if (_isDisposed ||
        _openPositionsReconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _openPositionsReconnectTimer?.cancel();
    _openPositionsReconnectAttempts++;

    _openPositionsReconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed) {
        _connectToOpenPositions();
      }
    });
  }

  // Schedule reconnect for pending orders
  void _schedulePendingOrdersReconnect() {
    if (_isDisposed ||
        _pendingOrdersReconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _pendingOrdersReconnectTimer?.cancel();
    _pendingOrdersReconnectAttempts++;

    _pendingOrdersReconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed) {
        _connectToPendingOrders();
      }
    });
  }

  // Schedule reconnect for market watch
  void _scheduleMarketWatchReconnect() {
    if (_isDisposed || _marketWatchReconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _marketWatchReconnectTimer?.cancel();
    _marketWatchReconnectAttempts++;

    _marketWatchReconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed) {
        _connectToMarketWatch();
      }
    });
  }

  // Schedule reconnect for symbols
  void _scheduleSymbolsReconnect() {
    if (_isDisposed || _symbolsReconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _symbolsReconnectTimer?.cancel();
    _symbolsReconnectAttempts++;

    _symbolsReconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed) {
        _connectToSymbols();
      }
    });
  }

  // Request data for open positions
  void _requestOpenPositionsData() async {
    if (!isOpenPositionsConnected.value || _isDisposed) return;

    final account = _accountController.activeMT5Account?.metaAccountNumber;
    if (account == null || account.isEmpty) return;

    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) {
      // Retry after delay if auth token not available
      Future.delayed(const Duration(seconds: 2), () {
        if (isOpenPositionsConnected.value && !_isDisposed) {
          _requestOpenPositionsData();
        }
      });
      return;
    }

    _sendEventToChannel(_openPositionsChannel, {
      "authID": authId,
      "trading_account": account,
    });
    _lastSubscribedAccount = account;

    if (kDebugMode) {
      dev.log(
        'Trading WS: Sent open positions subscription for account: $account',
      );
    }
  }

  // Request data for pending orders
  void _requestPendingOrdersData() async {
    if (!isPendingOrdersConnected.value || _isDisposed) return;

    final account = _accountController.activeMT5Account?.metaAccountNumber;
    if (account == null || account.isEmpty) return;

    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) {
      // Retry after delay if auth token not available
      Future.delayed(const Duration(seconds: 2), () {
        if (isPendingOrdersConnected.value && !_isDisposed) {
          _requestPendingOrdersData();
        }
      });
      return;
    }

    _sendEventToChannel(_pendingOrdersChannel, {
      "authID": authId,
      "trading_account": account,
    });
    _lastSubscribedAccount = account;

    if (kDebugMode) {
      dev.log(
        'Trading WS: Sent pending orders subscription for account: $account',
      );
    }
  }

  // Handle messages from open positions channel
  void _handleOpenPositionsMessage(dynamic message) {
    _handleSocketMessage(message, isOpenPositionChannel: true);
  }

  // Handle messages from pending orders channel
  void _handlePendingOrdersMessage(dynamic message) {
    _handleSocketMessage(message, isPendingOrderChannel: true);
  }

  // Request market watch data
  void _requestMarketWatchData() async {
    if (_marketWatchChannel == null || _isDisposed) return;

    final activeAccount = _accountController.activeMT5Account;
    final accountNumber = activeAccount?.metaAccountNumber ?? "";

    if (accountNumber.isEmpty) {
      if (kDebugMode) {
        dev.log(
          'Trading WS: Cannot request market watch data - no account number',
        );
      }
      return;
    }

    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot request market watch data - no auth token');
      }
      return;
    }

    final event = {
      "authID": authId,
      "trading_account": accountNumber,
      "type": "subscribe_marketwatch",
    };

    _sendEventToChannel(_marketWatchChannel, event);

    if (kDebugMode) {
      dev.log(
        'Trading WS: Requested market watch data for account: $accountNumber',
      );
    }
  }

  // Handle market watch messages
  void _handleMarketWatchMessage(dynamic message) {
    try {
      final String messageStr = message.toString();
      if (kDebugMode) {
        // dev.log('Trading WS: Market watch message: $messageStr');
      }

      final dynamic decodedData = jsonDecode(messageStr);
      _handleSocketMessage(decodedData); // Process through main handler
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error handling market watch message: $e');
      }
    }
  }

  // Request symbols data
  void _requestSymbolsData() async {
    if (_symbolsChannel == null || _isDisposed) return;

    final activeAccount = _accountController.activeMT5Account;
    final accountNumber = activeAccount?.metaAccountNumber ?? "";

    if (accountNumber.isEmpty) {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot request symbols data - no account number');
      }
      return;
    }

    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot request symbols data - no auth token');
      }
      return;
    }

    final event = {
      "authID": authId,
      "trading_account": accountNumber,
      "type": "subscribe_symbols",
    };

    _sendEventToChannel(_symbolsChannel, event);

    if (kDebugMode) {
      dev.log('Trading WS: Requested symbols data for account: $accountNumber');
    }
  }

  // Handle symbols messages
  void _handleSymbolsMessage(dynamic message) {
    try {
      final String messageStr = message.toString();
      if (kDebugMode) {
        // dev.log('Trading WS: Symbols message: $messageStr');
      }

      final dynamic decodedData = jsonDecode(messageStr);
      _handleSocketMessage(decodedData); // Process through main handler
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error handling symbols message: $e');
      }
    }
  }

  // Send event to a specific channel
  void _sendEventToChannel(
    IOWebSocketChannel? channel,
    Map<String, dynamic> event,
  ) {
    if (_channel == null || _isDisposed) return;

    try {
      final message = jsonEncode(event);
      _channel?.sink.add(message); // ✅ CHANGED: Use _channel instead of channel
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

  // Send event to WebSocket (legacy method for backward compatibility)
  void _sendEvent(Map<String, dynamic> event) {
    if (!isConnected.value || _isDisposed) return;

    try {
      final message = jsonEncode(event);
      _channel?.sink.add(message); // ✅ CHANGED: Use _channel instead of channel
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
  void _handleSocketMessage(
    dynamic message, {
    bool isPendingOrderChannel = false,
    bool isOpenPositionChannel = false,
  }) {
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

      // Handle /ws/op and /ws/po endpoint responses (JSON format)
      if (decoded is Map<String, dynamic>) {
        final type = decoded['type']?.toString();

        // Handle unsubscribe confirmation
        if (type == 'unsubscribed') {
          if (kDebugMode) {
            dev.log('Trading WS: ✅ Unsubscribed successfully');
          }
          if (_unsubscribeCompleter != null &&
              !_unsubscribeCompleter!.isCompleted) {
            _unsubscribeCompleter!.complete();
            _unsubscribeCompleter = null;
          }
          return;
        }

        // Handle authentication success for both /ws/op and /ws/po
        if (type == 'authenticated' ||
            type == 'positions_joined' ||
            type == 'pending_orders_joined') {
          if (kDebugMode) {
            // dev.log('Trading WS: Authenticated successfully (type: $type)');
          }
          return;
        }

        // Handle error responses
        if (type == 'error') {
          final errorMessage =
              decoded['message']?.toString() ?? 'Unknown error';
          if (kDebugMode) {
            dev.log('Trading WS: Error: $errorMessage');
          }
          // Complete unsubscribe completer even on error to avoid hanging
          if (_unsubscribeCompleter != null &&
              !_unsubscribeCompleter!.isCompleted) {
            _unsubscribeCompleter!.complete();
            _unsubscribeCompleter = null;
          }
          return;
        }

        // Handle positions_init - initial load from /ws/op
        if (type == 'positions_init') {
          final chunk = decoded['chunk'] as List?;
          final total = decoded['total'] as int? ?? 0;
          final isComplete = decoded['is_complete'] as bool? ?? false;

          if (kDebugMode) {
            dev.log(
              'Trading WS: positions_init total=$total isComplete=$isComplete chunkSize=${chunk?.length ?? 0}',
            );
          }

          if (chunk != null) {
            _handlePositionsOpFormat(chunk);
          }

          // If not complete, request more chunks
          if (!isComplete) {
            final offset = chunk?.length ?? 0;
            _sendEvent({
              "type": "request_positions_chunk",
              "offset": offset,
              "limit": 100,
            });
          }
          return;
        }

        // Handle positions_delta - real-time updates from /ws/op
        if (type == 'positions_delta') {
          final changes = decoded['changes'] as List?;
          if (kDebugMode) {
            // dev.log(
            //   'Trading WS: /ws/op positions_delta - ${changes?.length ?? 0} changes',
            // );
          }
          if (changes != null) {
            _handlePositionsDeltaOpFormat(changes);
          }
          return;
        }

        // Handle pending_orders_init - initial load from /ws/po
        if (type == 'pending_orders_init') {
          final chunk = decoded['chunk'] as List?;
          final total = decoded['total'] as int? ?? 0;
          final isComplete = decoded['is_complete'] as bool? ?? false;

          if (kDebugMode) {
            dev.log(
              'Trading WS: pending_orders_init total=$total isComplete=$isComplete chunkSize=${chunk?.length ?? 0}',
            );
          }

          if (chunk != null) {
            // Process each order in the chunk
            for (final item in chunk) {
              if (item is List) {
                _handlePendingOrderMessage(item);
              }
            }
          }

          // If not complete, request more chunks
          if (!isComplete) {
            final offset = chunk?.length ?? 0;
            _sendEvent({
              "type": "request_pending_orders_chunk",
              "offset": offset,
              "limit": 100,
            });
          }
          return;
        }

        // Handle pending_orders_delta - real-time updates from /ws/po
        if (type == 'pending_orders_delta') {
          final changes = decoded['changes'] as List?;
          if (kDebugMode) {
            // dev.log(
            //   'Trading WS: /ws/po pending_orders_delta - ${changes?.length ?? 0} changes',
            // );
          }
          if (changes != null) {
            // Process each change (add/update/remove)
            for (final item in changes) {
              if (item is List) {
                _handlePendingOrderMessage(item);
              }
            }
          }
          return;
        }
      }

      // Handle /ws/po pending orders format (check before /ws/op handlers):
      // Add: ["a", "po", orderId, account, symbol, action, volume, price_order, price_current, price_sl, price_tp, server_type]
      // Update: ["u", "po", ...] (full array updates)
      // Remove: ["r", orderId]
      if (decoded is List && decoded.isNotEmpty) {
        // Check if it's a pending order message
        if (decoded.length >= 2 && decoded[0] is String) {
          final firstElement = decoded[0].toString();
          final secondElement = decoded.length > 1 ? decoded[1].toString() : '';

          // Handle pending order operations from /ws/po
          // Check for ["a", "po", ...], ["u", "po", ...], or ["r", orderId] or ["r", orderId, account] when on pending tab
          if (secondElement == 'po' ||
              (firstElement == 'r' &&
                  (decoded.length == 2 || decoded.length == 3) &&
                  _tradingController.selectedTab == 1)) {
            _handlePendingOrderMessage(decoded);
            return;
          }
        }

        // Handle array of arrays for pending orders: [["a", "po", ...], ["u", "po", ...], ["r", orderId]]
        if (decoded[0] is List && decoded[0].isNotEmpty) {
          final firstItem = decoded[0] as List;
          if (firstItem.length >= 2 &&
              firstItem[0] is String &&
              firstItem[1] is String &&
              firstItem[1].toString() == 'po') {
            // This is a batch of pending orders
            for (final item in decoded) {
              if (item is List) {
                _handlePendingOrderMessage(item);
              }
            }
            return;
          }
        }
      }

      // Handle /ws/op remove flag: ["r", position_id] or ["r", position_id, account] or [["r", position_id]]
      // MT5 account-first formats we now support:
      // - Single remove: ["r", account_number, position_id]
      // - Bulk remove (close all): ["r", account_number, [position_id1, position_id2, ...]]
      // Existing formats remain supported:
      // - ["r", position_id] (regular)
      // - ["r", position_id, account_number] (MT5 legacy)
      // - [["r", position_id], ["r", position_id, account_number]] (batch)
      if (decoded is List && decoded.isNotEmpty) {
        // Check if single array format: ["r", position_id] or ["r", position_id, account]
        if (decoded[0] is String && decoded[0].toString() == 'r') {
          final activeAccount = _accountController.activeMT5Account;
          final currentAccountNumber = activeAccount?.metaAccountNumber ?? "0";

          String? accountNumber;
          final List<dynamic> rawIds = [];

          if (decoded.length == 2) {
            rawIds.add(decoded[1]);
          } else if (decoded.length == 3) {
            final second = decoded[1];
            final third = decoded[2];

            // Account-first bulk: ["r", account, [ids]]
            if (third is List) {
              accountNumber = second.toString();
              rawIds.addAll(third);
            }
            // Account-first single: ["r", account, id]
            else if (second is String && third is! List) {
              // If second matches current account, treat third as id
              if (second.toString() == currentAccountNumber) {
                accountNumber = second.toString();
                rawIds.add(third);
              } else {
                // Fallback to legacy (id, account) unless third matches current account
                final possibleAccount = third.toString();
                if (possibleAccount == currentAccountNumber) {
                  accountNumber = possibleAccount;
                  rawIds.add(second);
                } else {
                  accountNumber = possibleAccount;
                  rawIds.add(second);
                }
              }
            }
            // Legacy: ["r", id, account]
            else {
              accountNumber = third.toString();
              rawIds.add(second);
            }
          }

          // Validate account if provided
          if (accountNumber != null &&
              accountNumber != 'N/A' &&
              accountNumber != currentAccountNumber) {
            print(
              '⚠️ POSITION REMOVE: Ignored removal for different account ($accountNumber vs $currentAccountNumber)',
            );
            return;
          }

          if (rawIds.isEmpty) return;

          for (final rawId in rawIds) {
            final positionId = rawId.toString();
            final orderIdInt = int.tryParse(positionId) ?? 0;

            print(
              '🗑️ POSITION REMOVE: Received remove flag for position $positionId (Account: ${accountNumber ?? 'N/A'})',
            );
            print(
              '📊 POSITION REMOVE: Current active account: $currentAccountNumber',
            );

            if (kDebugMode) {
              dev.log(
                'Trading WS: Received remove flag for position: $positionId (account: ${accountNumber ?? 'N/A'}, current account: $currentAccountNumber)',
              );
            }

            // ✅ FIX: Check if orderId exists in pending orders list
            // This ensures we remove pending orders correctly regardless of tab or channel
            final isPendingOrder =
                orderIdInt > 0 &&
                _tradingController.hasPendingOrder(orderIdInt);

            if (isPendingOrder) {
              // Order exists in pending list - remove from pending orders
              _tradingController.removePendingOrder(orderIdInt);
              if (kDebugMode) {
                dev.log(
                  'Trading WS: Removed PENDING ORDER $positionId (detected in pending list, Source: ${isPendingOrderChannel ? 'PO Channel' : 'Generic'})',
                );
              }
              print(
                '✅ PENDING ORDER REMOVED: Order $orderIdInt removed from pending list (from WebSocket)',
              );
            } else if (isPendingOrderChannel ||
                _tradingController.selectedTab == 1) {
              // Not in pending list, but message came from pending channel or we're on pending tab
              // Try to remove anyway (might be a race condition)
              if (orderIdInt > 0) {
                _tradingController.removePendingOrder(orderIdInt);
                if (kDebugMode) {
                  dev.log(
                    'Trading WS: Removed PENDING ORDER $positionId (Source: ${isPendingOrderChannel ? 'PO Channel' : 'Pending Tab'})',
                  );
                }
                print(
                  '✅ PENDING ORDER REMOVED: Order $orderIdInt removed from pending list',
                );
              }
            } else {
              // Default to Position removal (Open Positions channel or legacy)
              _tradingController.removePositionFromList(positionId);
              if (kDebugMode) {
                dev.log(
                  'Trading WS: Removed POSITION $positionId (Source: ${isOpenPositionChannel ? 'OP Channel' : 'Generic'})',
                );
              }
            }
          }
          return;
        }

        // Check if array of arrays: [["r", position_id], ["r", position_id, account]] or [["r", position_id2]]
        if (decoded[0] is List && decoded[0].isNotEmpty) {
          final firstItem = decoded[0] as List;
          // Check if first item is ["r", position_id] or ["r", position_id, account] format
          if ((firstItem.length == 2 || firstItem.length == 3) &&
              firstItem[0] is String &&
              firstItem[0].toString() == 'r') {
            if (kDebugMode) {
              dev.log(
                'Trading WS: Received remove flags - ${decoded.length} positions to remove',
              );
            }
            // Process all remove flags (supports both 2-element and 3-element formats)
            for (final item in decoded) {
              if (item is List &&
                  (item.length == 2 || item.length == 3) &&
                  item[0] is String &&
                  item[0].toString() == 'r') {
                final activeAccount = _accountController.activeMT5Account;
                final currentAccountNumber =
                    activeAccount?.metaAccountNumber ?? "0";

                String? accountNumber;
                final List<dynamic> rawIds = [];

                if (item.length == 2) {
                  rawIds.add(item[1]);
                } else if (item.length == 3) {
                  final second = item[1];
                  final third = item[2];

                  // Account-first bulk: ["r", account, [ids]] inside batch
                  if (third is List) {
                    accountNumber = second.toString();
                    rawIds.addAll(third);
                  }
                  // Account-first single
                  else if (second is String && third is! List) {
                    if (second.toString() == currentAccountNumber) {
                      accountNumber = second.toString();
                      rawIds.add(third);
                    } else {
                      final possibleAccount = third.toString();
                      if (possibleAccount == currentAccountNumber) {
                        accountNumber = possibleAccount;
                        rawIds.add(second);
                      } else {
                        accountNumber = possibleAccount;
                        rawIds.add(second);
                      }
                    }
                  } else {
                    accountNumber = third.toString();
                    rawIds.add(second);
                  }
                }

                if (accountNumber != null &&
                    accountNumber != 'N/A' &&
                    accountNumber != currentAccountNumber) {
                  print(
                    '⚠️ POSITION REMOVE (batch): Ignored removal for different account ($accountNumber vs $currentAccountNumber)',
                  );
                  continue;
                }

                for (final rawId in rawIds) {
                  final positionId = rawId.toString();
                  final orderIdInt = int.tryParse(positionId) ?? 0;

                  // ✅ FIX: Check if orderId exists in pending orders list
                  // This ensures we remove pending orders correctly regardless of tab or channel
                  final isPendingOrder =
                      orderIdInt > 0 &&
                      _tradingController.hasPendingOrder(orderIdInt);

                  if (isPendingOrder) {
                    // Order exists in pending list - remove from pending orders
                    _tradingController.removePendingOrder(orderIdInt);
                    if (kDebugMode) {
                      dev.log(
                        'Trading WS: Removed PENDING ORDER: $positionId (detected in pending list)',
                      );
                    }
                    print('✅ PENDING ORDER REMOVED (batch): Order $orderIdInt');
                  } else {
                    // Not a pending order - remove from market positions
                    _tradingController.removePositionFromList(positionId);
                    if (kDebugMode) {
                      dev.log('Trading WS: Removed POSITION: $positionId');
                    }
                  }
                }
              }
            }
            return;
          }
        }
      }

      // Handle /ws/op array format:
      // ["a","op",...] - Add new position
      // ["u","op",...] - Update existing position
      // ["op",...] - Update existing position (legacy format)
      if (decoded is List && decoded.isNotEmpty) {
        // Check if single array format: ["a","op",...], ["u","op",...] or ["op",...]
        if (decoded[0] is String && decoded.length >= 13) {
          final firstElement = decoded[0].toString();
          final secondElement =
              decoded.length >= 14 ? decoded[1].toString() : '';
          // Handle ["a","op",...], ["u","op",...] and ["op",...] formats
          if ((firstElement == 'op' ||
                  firstElement == 'u' ||
                  firstElement == 'a') &&
              (decoded.length >= 13 ||
                  (decoded.length >= 12 && secondElement == 'op'))) {
            if (kDebugMode) {
              // dev.log(
              //   'Trading WS: Received /ws/op array format position (${firstElement == 'a'
              //       ? 'add'
              //       : firstElement == 'u'
              //       ? 'update'
              //       : 'update'})',
              // );
            }
            _handleSinglePositionOpFormat(decoded);
            return;
          }
        }

        // Check if array of arrays: [["a","op",...], ["u","op",...], ["op",...]]
        if (decoded[0] is List && decoded[0].isNotEmpty) {
          final firstItem = decoded[0] as List;
          // Check if first item starts with "a","op", "u","op" or just "op"
          if (firstItem.length >= 13 &&
              (firstItem[0] == 'op' ||
                  (firstItem[0] == 'u' &&
                      firstItem.length >= 14 &&
                      firstItem[1] == 'op') ||
                  (firstItem[0] == 'a' &&
                      firstItem.length >= 14 &&
                      firstItem[1] == 'op'))) {
            if (kDebugMode) {
              // dev.log(
              //   'Trading WS: Received /ws/op array of arrays - ${decoded.length} positions',
              // );
            }
            for (final item in decoded) {
              if (item is List && item.length >= 13) {
                _handleSinglePositionOpFormat(item);
              }
            }
            return;
          }
        }
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

        // Guard: if we recently subscribed for a different account, drop stale frames
        final currentAcc =
            _accountController.activeMT5Account?.metaAccountNumber;
        if (_lastSubscribedAccount != null &&
            currentAcc != null &&
            _lastSubscribedAccount != currentAcc) {
          // Stale payload from previous account, ignore
          return;
        }

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
      //   - Element [6] is entry price (number), [7] is profit/loss (number)
      // Pending orders format: [778926, 76356, "USDJPY", 154.091, 152.1, 0.01, "buy", 0.0, 0.0] (7-9 elements)
      //   - Element [6] is action (string like "buy"), [7] is SL (optional), [8] is TP (optional)
      if (decoded is List) {
        // Check if it's an array of arrays
        if (decoded.isNotEmpty && decoded[0] is List) {
          final firstItem = decoded[0] as List;

          // Check if element [6] is a string (pending order) or number (position)
          // Positions: element [6] is entry price (number), [7] is profit/loss (number)
          // Pending orders: element [6] is action (string like "buy"), [7] and [8] are SL/TP (optional numbers)
          final isPendingOrder =
              firstItem.length >= 7 &&
              firstItem.length <= 9 &&
              firstItem[6] is String;

          if (isPendingOrder) {
            // This is pending orders array (7-9 elements) from subscribe_pending_orders
            if (kDebugMode) {
              // Commented out to reduce log noise - uncomment if needed
              // dev.log('Trading WS: Received array of pending orders: ${decoded.length} orders');
            }
            _handlePendingOrdersArrayFormat(decoded);
            return;
          } else if (firstItem.length >= 8) {
            // Guard against stale frames based on embedded MT5 account id at [1]
            try {
              final frameAcc =
                  int.tryParse(firstItem[1].toString())?.toString();
              final currentAcc =
                  _accountController.activeMT5Account?.metaAccountNumber;
              if (_lastSubscribedAccount != null &&
                  currentAcc != null &&
                  _lastSubscribedAccount != currentAcc) {
                return;
              }
              if (frameAcc != null &&
                  currentAcc != null &&
                  frameAcc != currentAcc) {
                return;
              }
            } catch (_) {}
            // This is positions array (8+ elements)
            if (kDebugMode) {
              // Commented out to reduce log noise - uncomment if needed
              // dev.log('Trading WS: Received array of positions: ${decoded.length} positions');
            }
            _handlePositionsArrayFormat(decoded);
            return;
          }
        }
        // Single item array
        else {
          // Check if element [6] is a string (pending order) or number (position)
          final isPendingOrder =
              decoded.length >= 7 &&
              decoded.length <= 9 &&
              decoded[6] is String;

          if (isPendingOrder) {
            if (kDebugMode) {
              // dev.log('Trading WS: Received single pending order array');
            }
            _handlePendingOrdersArrayFormat([decoded]);
            return;
          } else if (decoded.length >= 8) {
            if (kDebugMode) {
              // dev.log('Trading WS: Received single position array');
            }
            _handlePositionsArrayFormat([decoded]);
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
          // Optimized debounce for smooth updates (100ms - reduced UI updates by 50%)
          _updateDebounceTimer?.cancel();
          _updateDebounceTimer = Timer(const Duration(milliseconds: 100), () {
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
        // dev.log('Trading WS: Error parsing message: $e');
        // dev.log('Trading WS: Raw message: $message');
      }
    }
  }

  // Public helper: switch to currently active MT5 account by hard restarting WS
  Future<void> switchToActiveAccount() async {
    if (_isDisposed) return;
    try {
      _disconnectWebSocket();
      // Ensure the previous socket actually closes before reconnect
      await _gracefulClose();
      // Small gap to avoid late frames landing after new connect
      await Future.delayed(const Duration(milliseconds: 200));
      _reconnectAttempts = 0;
      _lastSubscribedAccount = null;
      _initializeWebSocket();
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: switchToActiveAccount error: $e');
      }
    }
  }

  // Try to await socket close (best-effort)
  Future<void> _gracefulClose() async {
    if (!isConnected.value) return;
    try {
      final done = Completer<void>();
      late StreamSubscription sub;
      sub = _channel!.stream.listen(
        (_) {},
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        onError: (_) {
          if (!done.isCompleted) done.complete();
        },
        cancelOnError: true,
      );
      try {
        _channel?.sink.close();
      } catch (_) {}
      await done.future.timeout(
        const Duration(milliseconds: 300),
        onTimeout: () {},
      );
      await sub.cancel();
    } catch (_) {}
  }

  // Handle positions and account format
  // Format: {"positions": [[...], [...]], "account": [balance, credit, equity, marginFree, marginLevel, floating]}
  // Example: {"positions": [[387809, 301541, "EURUSD.c", 1, 0.01, 1.16248, 1.16269, -0.21]], "account": [8502.2, 0.0, 8499.9, 8489.54, 82045.37, -2.3]}
  void _handlePositionsAndAccountFormat(
    List<dynamic> positionsArray,
    dynamic accountArray,
  ) {
    try {
      // Guard: Block data if _lastSubscribedAccount is null (during unsubscribe)
      if (_lastSubscribedAccount == null) {
        if (kDebugMode) {
          dev.log(
            'Trading WS: Rejecting positions and account format - account transition in progress',
          );
        }
        return;
      }

      final List<TradingPosition> positions = [];
      List<AccountInfo> accountInfos = [];
      final currentAccount =
          _accountController.activeMT5Account?.metaAccountNumber;

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
          // Parse array format:
          // 8 elements: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit]
          // 10 elements: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit, SL, TP]
          // Example 8: [382703, 301333, "GBPUSD.c", 1, 0.02, 1.27500, 1.27450, -10.0]
          // Example 10: [76355, 778926, "USDJPY", 0, 0.01, 154.347, 154.134, -1.38, 0.0, 156.65]
          final positionId = int.tryParse(positionData[0].toString()) ?? 0;
          final mt5AccountStr = positionData[1].toString();

          // Validate account number matches current account
          if (currentAccount != null && mt5AccountStr != currentAccount) {
            if (kDebugMode) {
              dev.log(
                'Trading WS: Rejecting position $positionId - account mismatch. Expected: $currentAccount, Got: $mt5AccountStr',
              );
            }
            continue; // Skip this position
          }

          // Also check _lastSubscribedAccount for additional safety
          if (_lastSubscribedAccount != null &&
              mt5AccountStr != _lastSubscribedAccount) {
            if (kDebugMode) {
              dev.log(
                'Trading WS: Rejecting position $positionId - subscription account mismatch. Expected: $_lastSubscribedAccount, Got: $mt5AccountStr',
              );
            }
            continue; // Skip this position
          }

          final mt5Account = int.tryParse(mt5AccountStr) ?? 0;
          final symbol = positionData[2].toString();
          final actionValue =
              int.tryParse(positionData[3].toString()) ??
              0; // 0 = Buy, 1 = Sell
          final volume = double.tryParse(positionData[4].toString()) ?? 0.0;
          final priceOpen = double.tryParse(positionData[5].toString()) ?? 0.0;
          final priceCurrent =
              double.tryParse(positionData[6].toString()) ?? 0.0;
          final profit = double.tryParse(positionData[7].toString()) ?? 0.0;

          // Extract SL and TP if available (indices 8 and 9 for 10-element arrays)
          final priceSL =
              positionData.length >= 9
                  ? (double.tryParse(positionData[8].toString()) ?? 0.0)
                  : 0.0;
          final priceTP =
              positionData.length >= 10
                  ? (double.tryParse(positionData[9].toString()) ?? 0.0)
                  : 0.0;

          // Convert action: 0 = Buy, 1 = Sell
          final action = actionValue == 0 ? 'Buy' : 'Sell';

          // Parse digits from last element of array (if available)
          // Format: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit, SL?, TP?, digits?]
          int digits = 5; // Default
          if (positionData.length > 7) {
            final lastElement = positionData[positionData.length - 1];
            final parsedDigits = int.tryParse(lastElement.toString());
            // Check if last element is digits (not SL/TP which are doubles)
            if (parsedDigits != null &&
                parsedDigits > 0 &&
                parsedDigits <= 10) {
              digits = parsedDigits;
            }
          }

          // Create TradingPosition from array data
          final position = TradingPosition(
            mt5Account: mt5Account,
            position: positionId,
            action: action,
            volume: volume.toString(),
            priceOpen: priceOpen.toString(),
            priceSL: priceSL == 0.0 ? '0' : priceSL.toString(),
            priceTP: priceTP == 0.0 ? '0' : priceTP.toString(),
            priceCurrent: priceCurrent.toString(),
            closeTime: '', // Not in array
            timeCreate: '', // Not in array
            symbol: symbol,
            logo: '', // Will be set later if needed
            profit: profit,
            digits: digits, // Use parsed digits from WebSocket
            swap: 0.0, // Swap not available in this format
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

      // Optimized debounce to prevent flickering but keep updates smooth (100ms - reduced UI updates by 50%)
      _updateDebounceTimer?.cancel();
      _updateDebounceTimer = Timer(const Duration(milliseconds: 100), () {
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
  // Or: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit, SL, TP]
  // Or: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit, SL, TP, server_type, opened_at]
  // Example 8: [382703, 301333, "GBPUSD.c", 1, 0.02, 1.27500, 1.27450, -10.0]
  // Example 10: [76355, 778926, "USDJPY", 0, 0.01, 154.347, 154.134, -1.38, 0.0, 156.65]
  // Example 12: [76355, 778926, "USDJPY", 0, 0.01, 154.347, 154.134, -1.38, 0.0, 156.65, 0, 1704067200]
  void _handlePositionsArrayFormat(List<dynamic> positionsArray) {
    try {
      // Guard: Block data if _lastSubscribedAccount is null (during unsubscribe)
      if (_lastSubscribedAccount == null) {
        if (kDebugMode) {
          dev.log(
            'Trading WS: Rejecting positions array - account transition in progress',
          );
        }
        return;
      }

      final List<TradingPosition> positions = [];
      final currentAccount =
          _accountController.activeMT5Account?.metaAccountNumber;

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
          // Parse array format:
          // 8 elements: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit]
          // 10 elements: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit, SL, TP]
          // 12 elements: [position_id, MT5Account, symbol, action, volume, price_open, price_current, profit, SL, TP, server_type, opened_at]
          final positionId = int.tryParse(positionData[0].toString()) ?? 0;
          final mt5AccountStr = positionData[1].toString();

          // Validate account number matches current account
          if (currentAccount != null && mt5AccountStr != currentAccount) {
            if (kDebugMode) {
              dev.log(
                'Trading WS: Rejecting position $positionId - account mismatch. Expected: $currentAccount, Got: $mt5AccountStr',
              );
            }
            continue; // Skip this position
          }

          // Also check _lastSubscribedAccount for additional safety
          if (_lastSubscribedAccount != null &&
              mt5AccountStr != _lastSubscribedAccount) {
            if (kDebugMode) {
              dev.log(
                'Trading WS: Rejecting position $positionId - subscription account mismatch. Expected: $_lastSubscribedAccount, Got: $mt5AccountStr',
              );
            }
            continue; // Skip this position
          }

          final mt5Account = int.tryParse(mt5AccountStr) ?? 0;
          final symbol = positionData[2].toString();
          final actionValue =
              int.tryParse(positionData[3].toString()) ??
              0; // 0 = Buy, 1 = Sell
          final volume = double.tryParse(positionData[4].toString()) ?? 0.0;
          final priceOpen = double.tryParse(positionData[5].toString()) ?? 0.0;
          final priceCurrent =
              double.tryParse(positionData[6].toString()) ?? 0.0;
          final profit = double.tryParse(positionData[7].toString()) ?? 0.0;

          // Extract SL and TP if available (indices 8 and 9 for 10+ element arrays)
          final priceSL =
              positionData.length >= 9
                  ? (double.tryParse(positionData[8].toString()) ?? 0.0)
                  : 0.0;
          final priceTP =
              positionData.length >= 10
                  ? (double.tryParse(positionData[9].toString()) ?? 0.0)
                  : 0.0;

          // Extract opened_at (timeCreate) if available (index 11 for 12+ element arrays)
          // server_type is at index 10, opened_at is at index 11
          // opened_at is a Unix timestamp in seconds
          final openedAt =
              positionData.length >= 12
                  ? (int.tryParse(positionData[11].toString()) ?? 0)
                  : 0;

          // Convert opened_at Unix timestamp (seconds) to format: "YYYY-MM-DD HH:MM:SS" (matches UI expectation)
          String timeCreate = '';
          if (openedAt > 0) {
            try {
              // Multiply by 1000 to convert seconds to milliseconds for DateTime.fromMillisecondsSinceEpoch
              final dateTime = DateTime.fromMillisecondsSinceEpoch(
                openedAt * 1000,
              );
              // Format as "YYYY-MM-DD HH:MM:SS" to match UI format
              final year = dateTime.year.toString().padLeft(4, '0');
              final month = dateTime.month.toString().padLeft(2, '0');
              final day = dateTime.day.toString().padLeft(2, '0');
              final hour = dateTime.hour.toString().padLeft(2, '0');
              final minute = dateTime.minute.toString().padLeft(2, '0');
              final second = dateTime.second.toString().padLeft(2, '0');
              timeCreate = '$year-$month-$day $hour:$minute:$second';
            } catch (e) {
              if (kDebugMode) {
                dev.log('Trading WS: Error parsing opened_at timestamp: $e');
              }
            }
          }

          // Parse digits from last element of array (if available)
          // If not available, use default of 5
          int digits = 5; // Default
          if (positionData.length > 10) {
            // Check if digits is in the last element
            final lastElement = positionData[positionData.length - 1];
            final parsedDigits = int.tryParse(lastElement.toString());
            if (parsedDigits != null && parsedDigits > 0) {
              digits = parsedDigits;
            }
          }

          // Convert action: 0 = Buy, 1 = Sell
          final action = actionValue == 0 ? 'Buy' : 'Sell';

          // Create TradingPosition from array data
          final position = TradingPosition(
            mt5Account: mt5Account,
            position: positionId,
            action: action,
            volume: volume.toString(),
            priceOpen: priceOpen.toString(),
            priceSL: priceSL == 0.0 ? '0' : priceSL.toString(),
            priceTP: priceTP == 0.0 ? '0' : priceTP.toString(),
            priceCurrent: priceCurrent.toString(),
            closeTime:
                '', // Not in array (open positions don't have close time)
            timeCreate: timeCreate, // Extracted from opened_at if available
            symbol: symbol,
            logo: '', // Will be set later if needed
            profit: profit,
            digits: digits, // Calculated from price precision
            swap: 0.0, // Swap not available in this format
          );

          positions.add(position);
          if (kDebugMode) {
            // Commented out to reduce noise - fires for every position
            // dev.log('Trading WS: Parsed position: $symbol $action $volume @ $priceOpen (P&L: $profit, timeCreate: $timeCreate, digits: $digits)');
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

        // Optimized debounce for smooth updates (100ms - reduced UI updates by 50%)
        _updateDebounceTimer?.cancel();
        _updateDebounceTimer = Timer(const Duration(milliseconds: 100), () {
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

  // Handle /ws/po pending order messages
  // Add: ["a", "po", orderId, account, symbol, action, volume, price_order, price_current, price_sl, price_tp, server_type]
  // Update: ["u", "po", ...] (full array updates)
  // Remove: ["r", orderId]
  void _handlePendingOrderMessage(List<dynamic> message) {
    try {
      if (message.isEmpty) return;

      // Guard: Block data if _lastSubscribedAccount is null (during unsubscribe)
      if (_lastSubscribedAccount == null) {
        if (kDebugMode) {
          dev.log(
            'Trading WS: Rejecting pending order - account transition in progress',
          );
        }
        return;
      }

      final firstElement = message[0].toString();
      final secondElement = message.length > 1 ? message[1].toString() : '';
      final currentAccount =
          _accountController.activeMT5Account?.metaAccountNumber;

      // Handle remove: ["r", orderId] or ["r", orderId, account] or ["r", account, orderId]
      if (firstElement == 'r' && (message.length == 2 || message.length == 3)) {
        int orderId = 0;
        String? accountNumber;

        if (message.length == 2) {
          orderId = int.tryParse(message[1].toString()) ?? 0;
        } else if (message.length == 3) {
          final second = message[1];
          final third = message[2];

          // Account-first: ["r", account, orderId]
          if (third is! List &&
              second is String &&
              currentAccount != null &&
              second.toString() == currentAccount) {
            accountNumber = second.toString();
            orderId = int.tryParse(third.toString()) ?? 0;
          }
          // Legacy: ["r", orderId, account]
          else {
            orderId = int.tryParse(second.toString()) ?? 0;
            accountNumber =
                third is String || third is num ? third.toString() : null;
          }
        }

        // Validate account if provided
        if (accountNumber != null &&
            currentAccount != null &&
            accountNumber != currentAccount) {
          if (kDebugMode) {
            dev.log(
              'Trading WS: Rejecting pending order removal $orderId - account mismatch. Expected: $currentAccount, Got: $accountNumber',
            );
          }
          return; // Skip this removal
        }

        if (orderId > 0) {
          if (kDebugMode) {
            dev.log(
              'Trading WS: /ws/po Remove pending order: $orderId (format: ${message.length} elements)',
            );
          }
          _tradingController.removePendingOrder(orderId);
          print(
            '✅ PENDING ORDER REMOVED via _handlePendingOrderMessage: Order $orderId',
          );
        }
        return;
      }

      // Handle add or update: ["a", "po", ...] or ["u", "po", ...]
      // Format: ["a","po", orderId, account, symbol, action, volume, price_order, price_current, price_sl, price_tp, server_type, opened_at, swap, digits]
      if ((firstElement == 'a' || firstElement == 'u') &&
          secondElement == 'po' &&
          message.length >= 12) {
        // Parse pending order array format
        // [0] = "a" or "u" (add/update)
        // [1] = "po" (pending order identifier)
        // [2] = orderId
        // [3] = account
        // [4] = symbol
        // [5] = action
        // [6] = volume
        // [7] = price_order
        // [8] = price_current
        // [9] = price_sl
        // [10] = price_tp
        // [11] = server_type
        // [12] = opened_at (Unix timestamp in seconds)
        // [13] = swap
        // [14] = digits
        final orderId = int.tryParse(message[2].toString()) ?? 0;
        final account = message[3].toString();

        // Validate account number matches current account
        if (currentAccount != null && account != currentAccount) {
          if (kDebugMode) {
            dev.log(
              'Trading WS: Rejecting pending order $orderId - account mismatch. Expected: $currentAccount, Got: $account',
            );
          }
          return; // Skip this order
        }

        // Also check _lastSubscribedAccount for additional safety
        if (_lastSubscribedAccount != null &&
            account != _lastSubscribedAccount) {
          if (kDebugMode) {
            dev.log(
              'Trading WS: Rejecting pending order $orderId - subscription account mismatch. Expected: $_lastSubscribedAccount, Got: $account',
            );
          }
          return; // Skip this order
        }

        final accountInt = int.tryParse(account) ?? 0;
        final symbol = message[4].toString();
        // Action is a numeric code: 0, 1, 2, 3, 4, 5
        // 0 = buyMarket, 1 = sellMarket, 2 = buyLimit, 3 = sellLimit, 4 = buyStop, 5 = sellStop
        final actionCode = int.tryParse(message[5].toString()) ?? 0;
        final volume = double.tryParse(message[6].toString()) ?? 0.0;
        final priceOrder = double.tryParse(message[7].toString()) ?? 0.0;
        final priceCurrent = double.tryParse(message[8].toString()) ?? 0.0;
        // Parse price_sl and price_tp - handle empty strings, null, or "0" values
        final priceSLStr =
            message.length > 9 ? message[9].toString().trim() : '0';
        final priceTPStr =
            message.length > 10 ? message[10].toString().trim() : '0';
        final priceSL =
            (priceSLStr.isEmpty ||
                    priceSLStr == '0' ||
                    priceSLStr == 'null' ||
                    priceSLStr == '-')
                ? 0.0
                : (double.tryParse(priceSLStr) ?? 0.0);
        final priceTP =
            (priceTPStr.isEmpty ||
                    priceTPStr == '0' ||
                    priceTPStr == 'null' ||
                    priceTPStr == '-')
                ? 0.0
                : (double.tryParse(priceTPStr) ?? 0.0);
        // server_type at [11] - not used in PendingOrder model
        // Parse opened_at (index 12) - Unix timestamp in seconds
        final openedAt =
            message.length > 12
                ? (int.tryParse(message[12].toString()) ?? 0)
                : 0;
        // Parse digits - digits is always the last element
        // Format: [..., opened_at, swap?, digits]
        // If message has 14 elements: [12]=opened_at, [13]=digits (no swap)
        // If message has 15 elements: [12]=opened_at, [13]=swap, [14]=digits
        final digits =
            message.length > 12
                ? (int.tryParse(message[message.length - 1].toString()) ?? 0)
                : 0;
        // Note: swap is not used in PendingOrder model, but parsed for potential future use
        // final swap =
        //     message.length > 14
        //         ? (double.tryParse(message[message.length - 2].toString()) ?? 0.0)
        //         : 0.0;

        // Convert opened_at timestamp to ISO8601 string for timeCreate
        final timeCreate =
            openedAt > 0
                ? DateTime.fromMillisecondsSinceEpoch(
                  openedAt * 1000,
                ).toIso8601String()
                : DateTime.now().toIso8601String();

        if (kDebugMode) {
          dev.log(
            'Trading WS: /ws/po Parsing order - ID: $orderId, ActionCode: $actionCode, Symbol: $symbol, PriceOrder: $priceOrder, PriceCurrent: $priceCurrent, Digits: $digits, MessageLength: ${message.length}',
          );
        }

        // Convert action code to proper format
        String action;
        // Map action code to OrderType enum
        // For pending orders, action codes 0-1 (market) shouldn't appear, but handle them
        if (actionCode >= 2 && actionCode <= 5) {
          // Valid pending order types: 2=Buy Limit, 3=Sell Limit, 4=Buy Stop, 5=Sell Stop
          final orderType = OrderType.fromValue(actionCode);
          action = orderType.displayName;
        } else if (actionCode == 0 || actionCode == 1) {
          // Market orders (0 or 1) shouldn't be pending, but if they appear, determine from price
          // This is a fallback - determine order type from price relationship
          if (priceOrder > 0 && priceCurrent > 0) {
            if (priceOrder < priceCurrent) {
              // Buy below current price = Buy Limit
              action = 'Buy Limit';
            } else {
              // Sell above current price = Sell Limit
              action = 'Sell Limit';
            }
          } else {
            action = 'Buy Limit'; // Default fallback
          }
        } else {
          // Invalid action code - determine from price relationship
          if (priceOrder > 0 && priceCurrent > 0) {
            if (priceOrder < priceCurrent) {
              // Buy below current price = Buy Limit
              action = 'Buy Limit';
            } else if (priceOrder > priceCurrent) {
              // Sell above current price = Sell Limit
              action = 'Sell Limit';
            } else {
              // Prices equal - default to Buy Limit
              action = 'Buy Limit';
            }
          } else {
            action = 'Buy Limit'; // Default fallback
          }
        }

        final pendingOrder = PendingOrder(
          mt5Account: accountInt,
          order: orderId,
          action: action,
          symbol: symbol,
          priceOrder: priceOrder,
          priceCurrent: priceCurrent,
          volume: volume,
          priceSL: priceSL,
          priceTP: priceTP,
          timeCreate: timeCreate, // Parsed from opened_at timestamp
          state: 'PLACED', // Pending orders are in PLACED state
          logo: '', // Will be set later if needed
          digits: digits > 0 ? digits : 0, // Parse digits from message array
        );

        if (kDebugMode) {
          // dev.log(
          //   'Trading WS: /ws/po ${firstElement == 'a' ? 'Add' : 'Update'} pending order: $symbol $action $volume @ $priceOrder (ID: $orderId, SL: $priceSL, TP: $priceTP, timeCreate: $timeCreate)',
          // );
        }

        // Add or update pending order incrementally
        _tradingController.addOrUpdatePendingOrder(pendingOrder);
        return;
      }

      // Handle array of arrays: [["a", "po", ...], ["u", "po", ...], ["r", orderId]]
      if (message[0] is List) {
        for (final item in message) {
          if (item is List) {
            _handlePendingOrderMessage(item);
          }
        }
        return;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        dev.log('Trading WS: Error handling /ws/po message: $e\n$stackTrace');
      }
    }
  }

  // Handle pending orders array format from subscribe_pending_orders (legacy)
  // Response format: [[778926, 76356, "USDJPY", 154.091, 152.1, 0.01, "buy", 0.0, 0.0], ...]
  // Format: [MT5Account, OrderID, Symbol, PriceOrder, PriceCurrent, Volume, Action, PriceSL?, PriceTP?]
  // Action is string: "buy", "sell", "Buy Limit", "Sell Limit", etc.
  // PriceSL and PriceTP are optional (indices 7 and 8)
  void _handlePendingOrdersArrayFormat(List<dynamic> pendingOrdersArray) {
    try {
      // Guard: Block data if _lastSubscribedAccount is null (during unsubscribe)
      if (_lastSubscribedAccount == null) {
        if (kDebugMode) {
          dev.log(
            'Trading WS: Rejecting pending orders array - account transition in progress',
          );
        }
        return;
      }

      final List<PendingOrder> pendingOrders = [];
      final currentAccount =
          _accountController.activeMT5Account?.metaAccountNumber;

      for (final orderData in pendingOrdersArray) {
        // Accept arrays with 7, 8, or 9 elements
        if (orderData is! List || orderData.length < 7) {
          if (kDebugMode) {
            dev.log(
              'Trading WS: Skipping invalid pending order data (length: ${orderData is List ? orderData.length : 'not a list'}): $orderData',
            );
          }
          continue;
        }

        try {
          // Parse pending order array format
          // [0]: MT5Account, [1]: OrderID, [2]: Symbol, [3]: PriceOrder,
          // [4]: PriceCurrent, [5]: Volume, [6]: Action (string)
          // [7]: PriceSL (optional), [8]: PriceTP (optional)
          final mt5AccountStr = orderData[0].toString();

          // Validate account number matches current account
          if (currentAccount != null && mt5AccountStr != currentAccount) {
            if (kDebugMode) {
              dev.log(
                'Trading WS: Rejecting pending order - account mismatch. Expected: $currentAccount, Got: $mt5AccountStr',
              );
            }
            continue; // Skip this order
          }

          // Also check _lastSubscribedAccount for additional safety
          if (_lastSubscribedAccount != null &&
              mt5AccountStr != _lastSubscribedAccount) {
            if (kDebugMode) {
              dev.log(
                'Trading WS: Rejecting pending order - subscription account mismatch. Expected: $_lastSubscribedAccount, Got: $mt5AccountStr',
              );
            }
            continue; // Skip this order
          }

          final mt5Account = int.tryParse(mt5AccountStr) ?? 0;
          final orderId = int.tryParse(orderData[1].toString()) ?? 0;
          final symbol = orderData[2].toString();
          final priceOrder = double.tryParse(orderData[3].toString()) ?? 0.0;
          final priceCurrent = double.tryParse(orderData[4].toString()) ?? 0.0;
          final volume = double.tryParse(orderData[5].toString()) ?? 0.0;
          final actionStr = orderData[6].toString().toLowerCase();

          // Parse optional SL and TP (indices 7 and 8)
          final priceSL =
              orderData.length > 7
                  ? (double.tryParse(orderData[7].toString()) ?? 0.0)
                  : 0.0;
          final priceTP =
              orderData.length > 8
                  ? (double.tryParse(orderData[8].toString()) ?? 0.0)
                  : 0.0;

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
            priceSL: priceSL,
            priceTP: priceTP,
            timeCreate: '', // Not in array
            state: 'pending',
            logo: '', // Will be set later if needed
          );

          pendingOrders.add(pendingOrder);
          if (kDebugMode) {
            // Commented out to reduce noise - fires for every pending order
            // dev.log('Trading WS: Parsed pending order: $symbol $action $volume @ $priceOrder (Current: $priceCurrent) SL: $priceSL TP: $priceTP');
          }
        } catch (e) {
          if (kDebugMode) {
            dev.log('Trading WS: Error parsing pending order: $e');
            // Log order data in a cleaner format to avoid showing raw arrays
            try {
              if (orderData.length >= 3) {
                dev.log(
                  'Trading WS: Failed order - Symbol: ${orderData[2]}, OrderID: ${orderData[1]}',
                );
              }
            } catch (_) {
              // Skip if can't parse
            }
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

  // Handle /ws/op single position format:
  // Format 1: ["a","op", position_id, account, symbol, action, volume, price_open, price_current, profit, price_sl, price_tp, server_type, opened_at] - Add
  // Format 2: ["u","op", position_id, account, symbol, action, volume, price_open, price_current, profit, price_sl, price_tp, server_type, opened_at] - Update
  // Format 3: ["op", position_id, account, symbol, action, volume, price_open, price_current, profit, price_sl, price_tp, server_type, opened_at] - Update (legacy)
  void _handleSinglePositionOpFormat(List item) {
    try {
      // Guard: Block data if _lastSubscribedAccount is null (during unsubscribe)
      if (_lastSubscribedAccount == null) {
        if (kDebugMode) {
          dev.log(
            'Trading WS: Rejecting single position - account transition in progress',
          );
        }
        return;
      }

      if (item.length < 13) return;

      // Check format: ["a","op",...], ["u","op",...] or ["op",...]
      // New format includes swap and digits: length should be 16 for ["a","op",...] or ["u","op",...]
      // Or 15 for ["op",...] format
      final firstElement = item[0].toString();
      bool isAFormat =
          firstElement == 'a' &&
          item.length >= 16 &&
          item[1].toString() == 'op';
      bool isUFormat =
          firstElement == 'u' &&
          item.length >= 16 &&
          item[1].toString() == 'op';
      bool isOpFormat = firstElement == 'op' && item.length >= 15;

      if (!isAFormat && !isUFormat && !isOpFormat) return;

      // Determine operation type: "a" = add only, "u" or "op" = update (or add if not exists)
      final isAddOnly = isAFormat;
      final isUpdate = isUFormat || isOpFormat;

      // Parse based on format
      int offset =
          (isAFormat || isUFormat)
              ? 2
              : 1; // Skip ["a","op"], ["u","op"] or ["op"]

      final positionId = int.tryParse(item[offset].toString()) ?? 0;
      final account = item[offset + 1].toString();

      // Validate account number matches current account
      final currentAccount =
          _accountController.activeMT5Account?.metaAccountNumber;
      if (currentAccount != null && account != currentAccount) {
        if (kDebugMode) {
          dev.log(
            'Trading WS: Rejecting single position $positionId - account mismatch. Expected: $currentAccount, Got: $account',
          );
        }
        return; // Skip this position
      }

      // Also check _lastSubscribedAccount for additional safety
      if (_lastSubscribedAccount != null && account != _lastSubscribedAccount) {
        if (kDebugMode) {
          dev.log(
            'Trading WS: Rejecting single position $positionId - subscription account mismatch. Expected: $_lastSubscribedAccount, Got: $account',
          );
        }
        return; // Skip this position
      }
      final symbol = item[offset + 2].toString();
      final action =
          int.tryParse(item[offset + 3].toString()) ?? 0; // 0 = BUY, 1 = SELL
      final volume = double.tryParse(item[offset + 4].toString()) ?? 0.0;
      final priceOpen = double.tryParse(item[offset + 5].toString()) ?? 0.0;
      final priceCurrent = double.tryParse(item[offset + 6].toString()) ?? 0.0;
      final profit = double.tryParse(item[offset + 7].toString()) ?? 0.0;
      // Parse swap (index 10) - NEW position
      final swap =
          item.length > offset + 8
              ? (double.tryParse(item[offset + 8].toString()) ?? 0.0)
              : 0.0;
      // Parse price_sl and price_tp - handle empty strings, null, or "0" values
      // New format: swap is at index 10, price_sl at index 11, price_tp at index 12
      final priceSLStr =
          item.length > offset + 9 ? item[offset + 9].toString().trim() : '0';
      final priceTPStr =
          item.length > offset + 10 ? item[offset + 10].toString().trim() : '0';
      final priceSL =
          (priceSLStr.isEmpty ||
                  priceSLStr == '0' ||
                  priceSLStr == 'null' ||
                  priceSLStr == '-')
              ? 0.0
              : (double.tryParse(priceSLStr) ?? 0.0);
      final priceTP =
          (priceTPStr.isEmpty ||
                  priceTPStr == '0' ||
                  priceTPStr == 'null' ||
                  priceTPStr == '-')
              ? 0.0
              : (double.tryParse(priceTPStr) ?? 0.0);
      // server_type is at offset+11, opened_at is at offset+12
      // digits is always the last element in the array
      final openedAt =
          item.length > offset + 12
              ? (int.tryParse(item[offset + 12].toString()) ?? 0)
              : 0;
      // Parse digits from last element of array
      final digits =
          item.length > offset + 12
              ? (int.tryParse(item[item.length - 1].toString()) ?? 5)
              : 5;

      // Convert to TradingPosition format
      // Handle TP/SL: preserve actual values, only use '0' if truly 0.0
      final position = TradingPosition(
        mt5Account: int.tryParse(account) ?? 0,
        position: positionId,
        action: action == 0 ? 'Buy' : 'Sell',
        volume: volume.toString(),
        priceOpen: priceOpen.toString(),
        priceSL: priceSL == 0.0 ? '0' : priceSL.toString(),
        priceTP: priceTP == 0.0 ? '0' : priceTP.toString(),
        priceCurrent: priceCurrent.toString(),
        closeTime: '-',
        timeCreate:
            openedAt > 0
                ? DateTime.fromMillisecondsSinceEpoch(
                  openedAt * 1000,
                ).toIso8601String()
                : DateTime.now().toIso8601String(),
        symbol: symbol,
        logo: '',
        profit: profit,
        digits: digits,
        swap: swap,
      );

      // Get current positions and update
      final currentPositions =
          _tradingController.marketPositions
              .map(
                (p) => TradingPosition(
                  mt5Account: int.tryParse(p.accountId) ?? 0,
                  position: int.tryParse(p.orderId) ?? 0,
                  action: p.action,
                  volume: p.volume.toString(),
                  priceOpen: p.entryPrice,
                  priceSL:
                      p.stopLoss.isEmpty || p.stopLoss == '-'
                          ? '0'
                          : p.stopLoss,
                  priceTP:
                      p.takeProfit.isEmpty || p.takeProfit == '-'
                          ? '0'
                          : p.takeProfit,
                  priceCurrent: p.currentPrice,
                  closeTime: p.closeTime,
                  timeCreate: p.openTime,
                  symbol: p.symbol,
                  logo: p.flag,
                  profit: p.profitLoss,
                  digits:
                      p.digits > 0
                          ? p.digits
                          : 5, // Use digits from TradePosition
                  swap: p.swap,
                ),
              )
              .toList();

      // Handle add vs update to avoid conflicts
      final index = currentPositions.indexWhere(
        (p) => p.position == position.position,
      );

      if (isAddOnly) {
        // "a" flag: Only add if position doesn't exist
        if (index == -1) {
          currentPositions.add(position);
          if (kDebugMode) {
            dev.log(
              'Trading WS: Added new position ${position.symbol} (ID: ${position.position})',
            );
          }
        } else {
          if (kDebugMode) {
            dev.log(
              'Trading WS: Position ${position.position} already exists, skipping add operation',
            );
          }
          // Position already exists, skip add to avoid conflict
          return;
        }
      } else if (isUpdate) {
        // "u" flag or "op" format: Update if exists, add if doesn't exist
        if (index != -1) {
          currentPositions[index] = position;
          if (kDebugMode) {
            // dev.log(
            //   'Trading WS: Updated position ${position.symbol} (ID: ${position.position})',
            // );
          }
        } else {
          currentPositions.add(position);
          if (kDebugMode) {
            // dev.log(
            //   'Trading WS: Position ${position.position} not found, adding as new',
            // );
          }
        }
      }

      // Update TradingController
      _tradingController.updateWebSocketData(
        WebSocketTradingResponse(
          openPositions: OpenPositionsData(
            positions: currentPositions,
            accountinfo: [],
          ),
          pendingOrders: null,
          realtime: true,
          serverTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );

      if (kDebugMode) {
        // dev.log(
        //   'Trading WS: Updated position ${position.symbol} (ID: ${position.position}) from /ws/op',
        // );
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error parsing /ws/op position: $e');
      }
    }
  }

  // Handle /ws/op positions chunk format
  void _handlePositionsOpFormat(List chunk) {
    try {
      // Guard: Block data if _lastSubscribedAccount is null (during unsubscribe)
      if (_lastSubscribedAccount == null) {
        if (kDebugMode) {
          dev.log(
            'Trading WS: Rejecting positions - account transition in progress',
          );
        }
        return;
      }

      final List<TradingPosition> positions = [];
      final currentAccount =
          _accountController.activeMT5Account?.metaAccountNumber;

      for (final item in chunk) {
        if (item is! List || item.length < 13) continue;

        // Check format: ["a","op",...], ["u","op",...] or ["op",...]
        final firstElement = item[0].toString();
        bool isAFormat =
            firstElement == 'a' &&
            item.length >= 14 &&
            item[1].toString() == 'op';
        bool isUFormat =
            firstElement == 'u' &&
            item.length >= 14 &&
            item[1].toString() == 'op';
        bool isOpFormat = firstElement == 'op' && item.length >= 13;

        if (!isAFormat && !isUFormat && !isOpFormat) continue;

        // Parse based on format (for batch operations, we add all positions)
        int offset =
            (isAFormat || isUFormat)
                ? 2
                : 1; // Skip ["a","op"], ["u","op"] or ["op"]

        final positionId = int.tryParse(item[offset].toString()) ?? 0;
        final account = item[offset + 1].toString();

        // Validate account number matches current account
        if (currentAccount != null && account != currentAccount) {
          if (kDebugMode) {
            dev.log(
              'Trading WS: Rejecting position $positionId - account mismatch. Expected: $currentAccount, Got: $account',
            );
          }
          continue; // Skip this position
        }

        // Also check _lastSubscribedAccount for additional safety
        if (_lastSubscribedAccount != null &&
            account != _lastSubscribedAccount) {
          if (kDebugMode) {
            dev.log(
              'Trading WS: Rejecting position $positionId - subscription account mismatch. Expected: $_lastSubscribedAccount, Got: $account',
            );
          }
          continue; // Skip this position
        }

        final symbol = item[offset + 2].toString();
        final action = int.tryParse(item[offset + 3].toString()) ?? 0;
        final volume = double.tryParse(item[offset + 4].toString()) ?? 0.0;
        final priceOpen = double.tryParse(item[offset + 5].toString()) ?? 0.0;
        final priceCurrent =
            double.tryParse(item[offset + 6].toString()) ?? 0.0;
        final profit = double.tryParse(item[offset + 7].toString()) ?? 0.0;
        // Parse swap (index 10) - NEW position
        final swap =
            item.length > offset + 8
                ? (double.tryParse(item[offset + 8].toString()) ?? 0.0)
                : 0.0;
        // Parse price_sl and price_tp - New format: swap at index 10, price_sl at index 11, price_tp at index 12
        final priceSLStr =
            item.length > offset + 9 ? item[offset + 9].toString().trim() : '0';
        final priceTPStr =
            item.length > offset + 10
                ? item[offset + 10].toString().trim()
                : '0';
        final priceSL =
            (priceSLStr.isEmpty ||
                    priceSLStr == '0' ||
                    priceSLStr == 'null' ||
                    priceSLStr == '-')
                ? 0.0
                : (double.tryParse(priceSLStr) ?? 0.0);
        final priceTP =
            (priceTPStr.isEmpty ||
                    priceTPStr == '0' ||
                    priceTPStr == 'null' ||
                    priceTPStr == '-')
                ? 0.0
                : (double.tryParse(priceTPStr) ?? 0.0);
        // server_type is at offset+11, opened_at is at offset+12
        // digits is always the last element in the array
        final openedAt =
            item.length > offset + 12
                ? (int.tryParse(item[offset + 12].toString()) ?? 0)
                : 0;
        // Parse digits from last element of array
        final digits =
            item.length > offset + 12
                ? (int.tryParse(item[item.length - 1].toString()) ?? 5)
                : 5;

        final position = TradingPosition(
          mt5Account: int.tryParse(account) ?? 0,
          position: positionId,
          action: action == 0 ? 'Buy' : 'Sell',
          volume: volume.toString(),
          priceOpen: priceOpen.toString(),
          priceSL: priceSL == 0.0 ? '0' : priceSL.toString(),
          priceTP: priceTP == 0.0 ? '0' : priceTP.toString(),
          priceCurrent: priceCurrent.toString(),
          closeTime: '-',
          timeCreate:
              openedAt > 0
                  ? DateTime.fromMillisecondsSinceEpoch(
                    openedAt * 1000,
                  ).toIso8601String()
                  : DateTime.now().toIso8601String(),
          symbol: symbol,
          logo: '',
          profit: profit,
          digits: digits,
          swap: swap,
        );

        positions.add(position);
      }

      if (positions.isNotEmpty || chunk.isEmpty) {
        _tradingController.updateWebSocketData(
          WebSocketTradingResponse(
            openPositions: OpenPositionsData(
              positions: positions,
              accountinfo: [],
            ),
            pendingOrders: null,
            realtime: true,
            serverTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        );

        if (kDebugMode) {
          dev.log(
            'Trading WS: Updated ${positions.length} positions from /ws/op chunk',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error parsing /ws/op chunk: $e');
      }
    }
  }

  // Handle /ws/op positions_delta format
  void _handlePositionsDeltaOpFormat(List changes) {
    try {
      // Guard: Block data if _lastSubscribedAccount is null (during unsubscribe)
      if (_lastSubscribedAccount == null) {
        if (kDebugMode) {
          dev.log(
            'Trading WS: Rejecting position delta - account transition in progress',
          );
        }
        return;
      }

      final currentAccount =
          _accountController.activeMT5Account?.metaAccountNumber;

      for (final change in changes) {
        if (change is Map<String, dynamic>) {
          final action = change['action']?.toString();
          final data = change['data'] as List?;

          if (data == null || data.length < 13) continue;

          // Check format: ["a","op",...], ["u","op",...] or ["op",...]
          final firstElement = data[0].toString();
          bool isAFormat =
              firstElement == 'a' &&
              data.length >= 14 &&
              data[1].toString() == 'op';
          bool isUFormat =
              firstElement == 'u' &&
              data.length >= 14 &&
              data[1].toString() == 'op';
          bool isOpFormat = firstElement == 'op' && data.length >= 13;

          if (!isAFormat && !isUFormat && !isOpFormat) continue;

          // Extract account number for validation
          int offset = (isAFormat || isUFormat) ? 2 : 1;
          if (data.length > offset + 1) {
            final account = data[offset + 1].toString();

            // Validate account number matches current account
            if (currentAccount != null && account != currentAccount) {
              if (kDebugMode) {
                dev.log(
                  'Trading WS: Rejecting position delta - account mismatch. Expected: $currentAccount, Got: $account',
                );
              }
              continue; // Skip this change
            }

            // Also check _lastSubscribedAccount for additional safety
            if (_lastSubscribedAccount != null &&
                account != _lastSubscribedAccount) {
              if (kDebugMode) {
                dev.log(
                  'Trading WS: Rejecting position delta - subscription account mismatch. Expected: $_lastSubscribedAccount, Got: $account',
                );
              }
              continue; // Skip this change
            }
          }

          if (action == 'add' || action == 'update') {
            _handleSinglePositionOpFormat(data);
          } else if (action == 'remove') {
            // Remove position
            final positionId = int.tryParse(data[1].toString()) ?? 0;
            final currentPositions =
                _tradingController.marketPositions
                    .where((p) => p.orderId != positionId.toString())
                    .toList();

            _tradingController.updateWebSocketData(
              WebSocketTradingResponse(
                openPositions: OpenPositionsData(
                  positions:
                      currentPositions
                          .map(
                            (p) => TradingPosition(
                              mt5Account: int.tryParse(p.accountId) ?? 0,
                              position: int.tryParse(p.orderId) ?? 0,
                              action: p.action,
                              volume: p.volume.toString(),
                              priceOpen: p.entryPrice,
                              priceSL:
                                  p.stopLoss.isEmpty || p.stopLoss == '-'
                                      ? '0'
                                      : p.stopLoss,
                              priceTP:
                                  p.takeProfit.isEmpty || p.takeProfit == '-'
                                      ? '0'
                                      : p.takeProfit,
                              priceCurrent: p.currentPrice,
                              closeTime: p.closeTime,
                              timeCreate: p.openTime,
                              symbol: p.symbol,
                              logo: p.flag,
                              profit: p.profitLoss,
                              digits:
                                  p.digits > 0
                                      ? p.digits
                                      : 5, // Use digits from TradePosition
                              swap: p.swap,
                            ),
                          )
                          .toList(),
                  accountinfo: [],
                ),
                pendingOrders: null,
                realtime: true,
                serverTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              ),
            );

            if (kDebugMode) {
              dev.log('Trading WS: Removed position $positionId from /ws/op');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error parsing /ws/op delta: $e');
      }
    }
  }

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
        // ✅ CRITICAL: Close raw WebSocket first to stop ping/pong
        _rawWebSocket?.close();
        _rawWebSocket = null;

        // Then close channel
        _channel?.sink.close();
        _channel = null; // Keep this line to nullify the channel

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
    _currentEndpoint = null;
    _isConnecting = false;
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

  // Unsubscribe and resubscribe with new account (keeps socket active)
  Future<void> unsubscribeAndResubscribe() async {
    if (_isDisposed) {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot unsubscribeAndResubscribe - disposed');
      }
      return;
    }

    // Prevent concurrent reconnection attempts
    if (_isConnecting) {
      if (kDebugMode) {
        dev.log(
          'Trading WS: Already connecting, skipping unsubscribeAndResubscribe',
        );
      }
      return;
    }

    // If not connected, just initialize normally
    if (!isConnected.value) {
      if (kDebugMode) {
        dev.log('Trading WS: Not connected, initializing normally');
      }
      _tradingController.clearAllTradingData();
      _initializeWebSocket();
      return;
    }

    try {
      if (kDebugMode) {
        dev.log(
          'Trading WS: Unsubscribing and resubscribing for account change',
        );
      }

      // Step 1: Clear trading data and block incoming data BEFORE unsubscribe
      _tradingController.clearAllTradingData();
      _lastSubscribedAccount =
          null; // Block all incoming data during transition

      // Step 2: Unsubscribe from current subscription
      _unsubscribeCompleter = Completer<void>();
      _sendEvent({"type": "unsubscribe"});

      // Step 3: Wait for unsubscribe confirmation (with timeout)
      try {
        await _unsubscribeCompleter!.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            if (kDebugMode) {
              dev.log('Trading WS: Unsubscribe timeout, proceeding anyway');
            }
            if (_unsubscribeCompleter != null &&
                !_unsubscribeCompleter!.isCompleted) {
              _unsubscribeCompleter!.complete();
              _unsubscribeCompleter = null;
            }
          },
        );
      } catch (e) {
        if (kDebugMode) {
          dev.log('Trading WS: Error waiting for unsubscribe: $e');
        }
      }

      // Step 4: Small delay to let in-flight messages clear
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 5: Resubscribe with new account
      if (kDebugMode) {
        dev.log('Trading WS: Resubscribing with new account');
      }
      _requestTradingData();

      if (kDebugMode) {
        dev.log('Trading WS: Resubscribed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error in unsubscribeAndResubscribe: $e');
      }
      // Fallback: if unsubscribe/resubscribe fails, do full reconnect
      _disconnectWebSocket();
      await Future.delayed(const Duration(milliseconds: 150));
      _reconnectAttempts = 0;
      if (!_isDisposed) {
        _initializeWebSocket();
      }
    }
  }

  // Disconnect and reconnect with new account (for account switching)
  // This ensures clean connection with new account number
  Future<void> disconnectAndReconnect() async {
    if (_isDisposed) {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot disconnectAndReconnect - disposed');
      }
      return;
    }

    if (kDebugMode) {
      dev.log('Trading WS: Disconnecting and reconnecting for account change');
    }

    // ✅ FIX: Disconnect ALL WebSocket channels, not just main channel
    // This ensures old MT5/Self-hosted endpoints are fully closed
    _disconnectWebSocket();
    _disconnectOpenPositions();
    _disconnectPendingOrders();
    _disconnectMarketWatch();
    _disconnectSymbols();

    // Reset reconnection attempts for fresh start
    _reconnectAttempts = 0;

    // Reconnect with new account immediately (will use correct endpoints based on new account type)
    if (!_isDisposed) {
      print('🔄 TRADING WS: Starting reconnection after account switch');
      _initializeWebSocket();
      // Reconnect all channels simultaneously
      _initializeAllConnections();
      if (kDebugMode) {
        dev.log('Trading WS: Reconnected with new account');
      }
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

  // Force endpoint switch when account type changes
  Future<void> forceEndpointSwitch(String accountType) async {
    if (kDebugMode) {
      dev.log('Trading WS: Force endpoint switch to $accountType');
    }

    // Clear all trading data caches
    _clearAllTradingCaches();

    // Force reconnection with new endpoints
    await disconnectAndReconnect();

    if (kDebugMode) {
      dev.log('Trading WS: Endpoint switch completed for $accountType');
    }
  }

  // Clear all trading caches when switching account types
  void _clearAllTradingCaches() {
    try {
      if (kDebugMode) {
        dev.log('Trading WS: Clearing all trading caches');
      }

      // Clear all trading data using the controller method
      // This clears openPositions, pendingOrders, and all other trading data
      _tradingController.clearAllTradingData();

      // Disconnect all channels to force reconnection with new endpoints
      _disconnectOpenPositions();
      _disconnectPendingOrders();
      _disconnectMarketWatch();
      _disconnectSymbols();

      // Reset session state
      _lastDataReceived = null;
      _lastSubscribedAccount = null;

      // Reset reconnect attempts for fresh start
      _openPositionsReconnectAttempts = 0;
      _pendingOrdersReconnectAttempts = 0;
      _marketWatchReconnectAttempts = 0;
      _symbolsReconnectAttempts = 0;

      if (kDebugMode) {
        dev.log('Trading WS: Trading cache clearing completed');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Trading WS: Error clearing trading caches: $e');
      }
    }
  }

  // Subscribe to single symbol for MT5 accounts
  void subscribeToSingleSymbol(String symbol) async {
    final activeAccount = _accountController.activeMT5Account;
    if (activeAccount == null) {
      if (kDebugMode) {
        dev.log(
          'Trading WS: Cannot subscribe to single symbol - no active account',
        );
      }
      return;
    }

    // Use symbols channel for MT5 accounts, main channel for self-hosted
    final isMT5Account = activeAccount.tradingServer.toUpperCase() == "MT5";
    final targetChannel = isMT5Account ? _symbolsChannel : _channel;
    final isChannelConnected =
        isMT5Account ? isSymbolsConnected.value : isConnected.value;

    if (!isChannelConnected || targetChannel == null) {
      if (kDebugMode) {
        dev.log(
          'Trading WS: Cannot subscribe to symbol - ${isMT5Account ? 'symbols channel' : 'main channel'} not connected',
        );
      }
      return;
    }

    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) {
      if (kDebugMode) {
        dev.log('Trading WS: Cannot subscribe to symbol - no auth token');
      }
      return;
    }

    final event = {
      "authID": authId,
      "trading_account": activeAccount.metaAccountNumber,
      "symbol": symbol,
      "type": "subscribe_symbols",
    };

    if (isMT5Account) {
      _sendEventToChannel(targetChannel, event);
    } else {
      _sendEvent(event);
    }

    if (kDebugMode) {
      dev.log(
        'Trading WS: Subscribed to single symbol: $symbol for ${isMT5Account ? 'MT5' : 'self-hosted'} account',
      );
    }
  }

  // Unsubscribe from single symbol
  void unsubscribeFromSingleSymbol(String symbol) async {
    final activeAccount = _accountController.activeMT5Account;
    if (activeAccount == null) return;

    final isMT5Account = activeAccount.tradingServer.toUpperCase() == "MT5";
    final targetChannel = isMT5Account ? _symbolsChannel : _channel;
    final isChannelConnected =
        isMT5Account ? isSymbolsConnected.value : isConnected.value;

    if (!isChannelConnected || targetChannel == null) return;

    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) return;

    final event = {
      "authID": authId,
      "trading_account": activeAccount.metaAccountNumber,
      "symbol": symbol,
      "type": "unsubscribe_symbols",
    };

    if (isMT5Account) {
      _sendEventToChannel(targetChannel, event);
    } else {
      _sendEvent(event);
    }

    if (kDebugMode) {
      dev.log('Trading WS: Unsubscribed from single symbol: $symbol');
    }
  }

  // Connect to market watch endpoint
  void connectToMarketWatch() {
    if (!isMarketWatchConnected.value) {
      _connectToMarketWatch();
    }
  }

  // Connect to symbols endpoint
  void connectToSymbols() {
    if (!isSymbolsConnected.value) {
      _connectToSymbols();
    }
  }

  // Disconnect from market watch
  void disconnectFromMarketWatch() {
    _disconnectMarketWatch();
  }

  // Disconnect from symbols
  void disconnectFromSymbols() {
    _disconnectSymbols();
  }
}
