import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/models/mt5_account.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/services/trading_websocket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AccountWebSocketService extends GetxService with WidgetsBindingObserver {
  // Connection state
  final RxBool isConnected = false.obs;
  final RxBool isReconnecting = false.obs;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  bool _isDisposed = false;
  bool _isConnecting = false; // Guard to prevent concurrent connections
  WebSocketChannel? channel;

  // Unsubscribe/resubscribe state
  Completer<void>? _unsubscribeCompleter;

  // Account type tracking for endpoint switching
  String? _lastAccountType; // 'mt5' or 'selfhosted'

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

    // Listen to active account changes and handle endpoint switching
    // This ensures proper endpoint switching when account type changes (MT5 vs self-hosted)
    ever(_accountController.activeMT5AccountRx, (MT5Account? account) {
      if (account != null && !_isDisposed) {
        final currentAccountType = _getAccountType(account);

        if (kDebugMode) {
          dev.log(
            'Account WS: Active account changed to: ${account.metaAccountNumber} (${currentAccountType}), last type: $_lastAccountType',
          );
        }

        // Check if account type changed (MT5 vs self-hosted)
        final accountTypeChanged = _lastAccountType != null && _lastAccountType != currentAccountType;

        if (accountTypeChanged) {
          if (kDebugMode) {
            dev.log('Account WS: Account type changed from $_lastAccountType to $currentAccountType, forcing reconnection');
          }

          // Account type changed - force full reconnection with new endpoints
          // This ensures all services switch to correct endpoints simultaneously
          _forceEndpointSwitch(currentAccountType);
        } else {
          // Same account type - just refresh subscription
          if (isConnected.value) {
            _requestAccountData();
          } else {
            _initializeWebSocket();
          }
        }

        _lastAccountType = currentAccountType;
      }
    });

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
            dev.log('Account WS: App resumed, reconnecting...');
          }
          _initializeWebSocket();
        }
        break;
      case AppLifecycleState.paused:
        if (kDebugMode) {
          dev.log('Account WS: App paused, maintaining connection');
        }
        break;
      case AppLifecycleState.detached:
        if (kDebugMode) {
          dev.log('Account WS: App detached, closing connection');
        }
        _disconnectWebSocket();
        break;
      case AppLifecycleState.inactive:
        if (kDebugMode) {
          dev.log('Account WS: App inactive');
        }
        break;
      case AppLifecycleState.hidden:
        if (kDebugMode) {
          dev.log('Account WS: App hidden');
        }
        break;
    }
  }

  // Check if primary account has trading_server="MT5"
  bool _isMT5Account() {
    try {
      final primaryAccount = _accountController.primaryMT5Account;
      return primaryAccount?.tradingServer == "MT5";
    } catch (e) {
      if (kDebugMode) {
        dev.log('Account WS: Error checking MT5 account: $e');
      }
      return false;
    }
  }

  // Get account type string for tracking changes
  String _getAccountType(MT5Account account) {
    return account.tradingServer == "MT5" ? 'mt5' : 'selfhosted';
  }

  // Force endpoint switch when account type changes
  // This ensures all WebSocket services switch endpoints simultaneously
  void _forceEndpointSwitch(String newAccountType) async {
    if (kDebugMode) {
      dev.log('Account WS: Forcing endpoint switch to $newAccountType');
    }

    // Clear all caches first
    await _clearAllCaches();

    // Disconnect current connection
    await disconnectAndReconnect();

    // Notify trading service to switch endpoints too
    final tradingService = Get.find<TradingWebSocketService>();
    await tradingService.forceEndpointSwitch(newAccountType);

    // Small delay to ensure clean switching
    await Future.delayed(const Duration(milliseconds: 200));

    if (kDebugMode) {
      dev.log('Account WS: Endpoint switch completed for $newAccountType');
    }
  }

  // Clear all caches when switching account types
  Future<void> _clearAllCaches() async {
    try {
      if (kDebugMode) {
        dev.log('Account WS: Clearing all caches for account type switch');
      }

      // Clear trading controller caches
      _tradingController.clearAllTradingData();

      if (kDebugMode) {
        dev.log('Account WS: Cache clearing completed');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Account WS: Error clearing caches: $e');
      }
    }
  }

  // Get WebSocket URL based on account type (same base URL, conditional endpoint)
  String _getWebSocketUrl() {
    final isMT5Account = _isMT5Account();
    final endpoint = isMT5Account ? '/ws/mt5/accounts' : '/ws/accounts';
    final wsUrl = '${ApiConstants.socketUrl}$endpoint';

    if (kDebugMode) {
      dev.log('Account WS: Using ${isMT5Account ? 'MT5' : 'regular'} endpoint: $wsUrl');
    }
    return wsUrl;
  }

  // Initialize WebSocket connection
  void _initializeWebSocket() {
    if (isConnected.value || _isConnecting) return;

    _isConnecting = true;

    try {
      final wsUrl = _getWebSocketUrl();

      channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      isConnected.value = true;
      _reconnectAttempts = 0;
      isReconnecting.value = false;
      _isConnecting = false;

      if (kDebugMode) {
        dev.log('Account WS: Connected successfully to $wsUrl');
      }

      channel!.stream.listen(
        (message) => _handleSocketMessage(message),
        onError: (error) {
          if (kDebugMode) {
            dev.log('Account WS error: $error');
          }
          isConnected.value = false;
          _isConnecting = false;
          _scheduleReconnect();
        },
        onDone: () {
          if (kDebugMode) {
            dev.log('Account WS: Connection closed');
          }
          isConnected.value = false;
          _isConnecting = false;
          _scheduleReconnect();
        },
      );

      // Request account data after connection with proper delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (isConnected.value && !_isDisposed) {
          _requestAccountData();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        dev.log('Account WS: Initialization failed: $e');
      }
      isConnected.value = false;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  // Request account data from WebSocket
  void _requestAccountData() async {
    if (_isDisposed || !isConnected.value || channel == null) {
      if (kDebugMode) {
        dev.log('Account WS: Cannot request data - disposed or not connected');
      }
      return;
    }

    // Get active account number
    final activeAccount = _accountController.activeMT5Account;
    final accountNumber = activeAccount?.metaAccountNumber ?? "0";

    if (accountNumber == "0" || accountNumber.isEmpty) {
      if (kDebugMode) {
        dev.log('Account WS: Invalid account number, retrying in 2 seconds...');
      }
      Timer(const Duration(seconds: 2), () {
        if (isConnected.value && !_isDisposed) {
          _requestAccountData();
        }
      });
      return;
    }

    if (kDebugMode) {
      dev.log('Account WS: Requesting data for account: $accountNumber');
    }

    // Check if this is an MT5 account
    if (_isMT5Account()) {
      // For MT5 accounts, send: { "type": "subscribe_accounts", "account": "400012" }
      _sendEvent({"type": "subscribe_accounts", "account": accountNumber});
    } else {
      // For regular accounts, get auth token and send: { "authID": "user_token", "trading_account": "301023" }
      final authId = await SecureStorageService.getAuthToken();
      if (authId == null || authId.isEmpty) {
        if (kDebugMode) {
          dev.log('Account WS: No auth token, retrying in 2 seconds...');
        }
        Timer(const Duration(seconds: 2), () {
          if (isConnected.value && !_isDisposed) {
            _requestAccountData();
          }
        });
        return;
      }
      _sendEvent({"authID": authId, "trading_account": accountNumber});
    }
  }

  // Handle incoming WebSocket messages
  void _handleSocketMessage(dynamic message) {
    if (_isDisposed) return;

    try {
      final String messageStr = message.toString();
      if (kDebugMode) {
        // dev.log('Account WS: Received message: $messageStr');
      }

      final dynamic decodedData = jsonDecode(messageStr);

      // Handle array responses (account data)
      // Format: [["ac","1000003",7164.04,7163.87,1.3,7162.57,551066.92,-0.17,0]]
      if (decodedData is List && decodedData.isNotEmpty) {
        // Array of arrays (multiple account updates)
        if (decodedData[0] is List) {
          for (final accountArray in decodedData) {
            if (accountArray is List && accountArray.isNotEmpty) {
              _parseAccountArray(accountArray);
            }
          }
        }
        // Single array (one account update)
        else if (decodedData[0] is String && decodedData.length >= 5) {
          _parseAccountArray(decodedData);
        }
        return;
      }

      // Handle JSON object responses (authentication, errors, etc.)
      if (decodedData is Map<String, dynamic>) {
        _handleJsonResponse(decodedData);
        return;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        dev.log('Account WS: Error parsing message: $e\n$stackTrace');
      }
    }
  }

  // Parse account array response
  // Format: ["ac", account, balance, equity, margin, free_margin, margin_level, profit, swap]
  // [0] = "ac" (type identifier)
  // [1] = account (meta_account_number, e.g., "1000003")
  // [2] = balance (cash balance, doesn't include unrealized P&L)
  // [3] = equity (balance + unrealized P&L + swap)
  // [4] = margin (margin currently used by open positions)
  // [5] = free_margin (available margin = equity - margin)
  // [6] = margin_level (percentage = equity / margin * 100)
  // [7] = profit (unrealized P&L across open positions)
  // [8] = swap (accumulated swap/overnight interest)
  void _parseAccountArray(List accountArray) {
    try {
      if (accountArray.isEmpty) return;

      // Check if first element is "ac" (account type identifier)
      if (accountArray[0]?.toString().toLowerCase() != 'ac') {
        if (kDebugMode) {
          // dev.log(
          //   'Account WS: Not an account array (first element: ${accountArray[0]})',
          // );
        }
        return;
      }

      // Validate minimum array length (should have at least "ac" and account)
      if (accountArray.length < 2) {
        if (kDebugMode) {
          // dev.log(
          //   'Account WS: Invalid account array length: ${accountArray.length} (expected at least 2)',
          // );
        }
        return;
      }

      // Parse array elements with safe defaults
      // Index 0: "ac" (type identifier) - already checked
      // Index 1: account (meta_account_number)
      final metaAccountNumber =
          accountArray.length > 1 ? accountArray[1].toString() : '';
      // Index 2: balance
      final balance =
          accountArray.length > 2
              ? double.tryParse(accountArray[2].toString()) ?? 0.0
              : 0.0;
      // Index 3: equity
      final equity =
          accountArray.length > 3
              ? double.tryParse(accountArray[3].toString()) ?? 0.0
              : 0.0;
      // Index 4: margin
      final margin =
          accountArray.length > 4
              ? double.tryParse(accountArray[4].toString()) ?? 0.0
              : 0.0;
      // Index 5: free_margin
      final freeMargin =
          accountArray.length > 5
              ? double.tryParse(accountArray[5].toString()) ?? 0.0
              : 0.0;
      // Index 6: margin_level (percentage)
      final marginLevel =
          accountArray.length > 6
              ? double.tryParse(accountArray[6].toString()) ?? 0.0
              : 0.0;
      // Index 7: profit (unrealized P&L)
      final profit =
          accountArray.length > 7
              ? double.tryParse(accountArray[7].toString()) ?? 0.0
              : 0.0;
      // Index 8: swap (accumulated swap)
      final swap =
          accountArray.length > 8
              ? double.tryParse(accountArray[8].toString()) ?? 0.0
              : 0.0;

      if (kDebugMode) {
        // dev.log(
        //   'Account WS: Parsed account data for $metaAccountNumber - Balance: $balance, Equity: $equity, Margin: $margin, Free Margin: $freeMargin, Margin Level: $marginLevel%, Profit: $profit, Swap: $swap',
        // );
      }

      // Create AccountInfo from parsed data
      final accountInfo = AccountInfo(
        assets: balance, // Assets = Balance (cash balance)
        balance: balance, // Cash balance (doesn't include unrealized P&L)
        blockedCommission: 0.0, // Not in array
        blockedProfit: 0.0, // Not in array
        credit: 0.0, // Not in array
        currencyDigits: 2, // Default
        equity: equity, // Balance + unrealized P&L + swap
        floating: profit, // Floating profit/loss (unrealized P&L)
        liabilities: 0.0, // Not in array
        login: int.tryParse(metaAccountNumber) ?? 0,
        margin: margin, // Margin currently used by open positions
        marginFree: freeMargin, // Available margin (equity - margin)
        marginInitial: 0.0, // Not in array
        marginLevel: marginLevel, // Percentage (equity / margin * 100)
        marginLeverage: 0, // Not in array
        marginMaintenance: 0.0, // Not in array
        profit: profit, // Unrealized P&L across open positions
        soActivation: 0.0, // Not in array
        soEquity: 0.0, // Not in array
        soLevel: 0.0, // Not in array
        soMargin: 0.0, // Not in array
        soTime: 0.0, // Not in array
        storage: swap, // Accumulated swap (overnight interest)
      );

      // Update TradingController with account info
      _tradingController.updateAccountInfoFromWebSocket(accountInfo);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        dev.log('Account WS: Error parsing account array: $e\n$stackTrace');
      }
    }
  }

  // Handle JSON object responses (authentication, errors, etc.)
  void _handleJsonResponse(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    // Handle unsubscribe confirmation
    if (type == 'unsubscribed') {
      if (kDebugMode) {
        dev.log('Account WS: ✅ Unsubscribed successfully');
      }
      if (_unsubscribeCompleter != null &&
          !_unsubscribeCompleter!.isCompleted) {
        _unsubscribeCompleter!.complete();
        _unsubscribeCompleter = null;
      }
      return;
    }

    // Handle authentication success messages
    if (type == 'accounts_joined' ||
        type == 'authenticated' ||
        type == 'account_subscribed') {
      final status = data['status']?.toString();
      final message = data['message']?.toString();

      if (status == 'success') {
        if (kDebugMode) {
          dev.log('Account WS: ✅ Authenticated: $message');
        }
        if (type == 'accounts_joined') {
          if (kDebugMode) {
            dev.log(
              'Account WS: ✅ Subscribed to account: ${data['trading_account']}',
            );
          }
        }
      }
      return;
    }

    // Handle error responses
    if (type == 'error') {
      final errorMessage = data['message']?.toString() ?? 'Unknown error';
      if (kDebugMode) {
        dev.log('Account WS: ❌ Error: $errorMessage');
      }
      // Complete unsubscribe completer even on error to avoid hanging
      if (_unsubscribeCompleter != null &&
          !_unsubscribeCompleter!.isCompleted) {
        _unsubscribeCompleter!.complete();
        _unsubscribeCompleter = null;
      }
      return;
    }

    // Handle other JSON responses
    if (kDebugMode) {
      dev.log('Account WS: 📨 Received JSON response: $data');
    }
  }

  // Send event with parameters over WebSocket
  void _sendEvent(Map<String, dynamic> event) {
    try {
      if (channel == null || !isConnected.value) {
        if (kDebugMode) {
          dev.log(
            'Account WS: Cannot send event - channel is null or not connected',
          );
        }
        return;
      }
      final encoded = jsonEncode(event);
      channel!.sink.add(encoded);
      if (kDebugMode) {
        dev.log('Account WS: Sent event: $encoded');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Account WS: Error sending event: $e');
      }
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        // dev.log('Account WS: Max reconnection attempts reached');
      }
      return;
    }

    if (_reconnectTimer?.isActive == true) return;

    _reconnectAttempts++;
    isReconnecting.value = true;

    if (kDebugMode) {
      // dev.log(
      // 'Account WS: Scheduling reconnection attempt $_reconnectAttempts in ${_reconnectDelay.inSeconds} seconds',
      // );
    }

    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectWebSocket();
    });
  }

  // Reconnect WebSocket
  void _reconnectWebSocket() {
    if (isConnected.value) return;

    if (kDebugMode) {
      // dev.log('Account WS: Attempting to reconnect...');
    }
    isReconnecting.value = true;

    try {
      _disconnectWebSocket();
      _initializeWebSocket();
    } catch (e) {
      if (kDebugMode) {
        dev.log('Account WS: Reconnection failed: $e');
      }
      isReconnecting.value = false;
      _scheduleReconnect();
    }
  }

  // Disconnect WebSocket
  void _disconnectWebSocket() {
    try {
      if (channel != null) {
        channel!.sink.close();
        channel = null;
      }
      isConnected.value = false;
      isReconnecting.value = false;
      _isConnecting = false;
      _reconnectTimer?.cancel();
      if (kDebugMode) {
        dev.log('Account WS: Disconnected');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Account WS: Error disconnecting: $e');
      }
    }
  }

  // Public method to manually reconnect
  void reconnect() {
    _reconnectAttempts = 0; // Reset attempts for manual reconnect
    _reconnectWebSocket();
  }

  // Public method to refresh account data
  void refreshAccountData() {
    if (isConnected.value && !_isDisposed) {
      _requestAccountData();
    } else if (!isConnected.value) {
      _initializeWebSocket();
    }
  }

  // Subscribe to single symbol data (for MT5 accounts)
  void subscribeToSymbol(String symbol) async {
    final activeAccount = _accountController.activeMT5Account;
    if (activeAccount == null || !isConnected.value || channel == null) {
      if (kDebugMode) {
        dev.log('Account WS: Cannot subscribe to symbol - no account or not connected');
      }
      return;
    }

    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) {
      if (kDebugMode) {
        dev.log('Account WS: Cannot subscribe to symbol - no auth token');
      }
      return;
    }

    final event = {
      "authID": authId,
      "trading_account": activeAccount.metaAccountNumber,
      "symbol": symbol,
      "type": "subscribe_symbols"
    };

    _sendEvent(event);

    if (kDebugMode) {
      dev.log('Account WS: Subscribed to symbol: $symbol for account: ${activeAccount.metaAccountNumber}');
    }
  }

  // Unsubscribe from single symbol data
  void unsubscribeFromSymbol(String symbol) async {
    final activeAccount = _accountController.activeMT5Account;
    if (activeAccount == null || !isConnected.value || channel == null) return;

    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) return;

    final event = {
      "authID": authId,
      "trading_account": activeAccount.metaAccountNumber,
      "symbol": symbol,
      "type": "unsubscribe_symbols"
    };

    _sendEvent(event);

    if (kDebugMode) {
      dev.log('Account WS: Unsubscribed from symbol: $symbol');
    }
  }

  // Public method to force endpoint switch (called by account controller)
  Future<void> forceEndpointSwitch(String accountType) async {
    if (kDebugMode) {
      dev.log('Account WS: External force endpoint switch requested for $accountType');
    }

    _lastAccountType = accountType;
    await disconnectAndReconnect();
  }

  // Unsubscribe and resubscribe with new account (keeps socket active)
  Future<void> unsubscribeAndResubscribe() async {
    if (_isDisposed) {
      if (kDebugMode) {
        dev.log('Account WS: Cannot unsubscribeAndResubscribe - disposed');
      }
      return;
    }

    // Prevent concurrent reconnection attempts
    if (_isConnecting) {
      if (kDebugMode) {
        dev.log(
          'Account WS: Already connecting, skipping unsubscribeAndResubscribe',
        );
      }
      return;
    }

    // If not connected, just initialize normally
    if (!isConnected.value) {
      if (kDebugMode) {
        dev.log('Account WS: Not connected, initializing normally');
      }
      _initializeWebSocket();
      return;
    }

    try {
      if (kDebugMode) {
        dev.log(
          'Account WS: Unsubscribing and resubscribing for account change',
        );
      }

      // Step 1: Unsubscribe from current subscription
      _unsubscribeCompleter = Completer<void>();
      _sendEvent({"type": "unsubscribe"});

      // Step 2: Wait for unsubscribe confirmation (with timeout)
      try {
        await _unsubscribeCompleter!.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            if (kDebugMode) {
              dev.log('Account WS: Unsubscribe timeout, proceeding anyway');
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
          dev.log('Account WS: Error waiting for unsubscribe: $e');
        }
      }

      // Step 3: Resubscribe with new account
      if (kDebugMode) {
        dev.log('Account WS: Resubscribing with new account');
      }
      _requestAccountData();

      if (kDebugMode) {
        dev.log('Account WS: Resubscribed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Account WS: Error in unsubscribeAndResubscribe: $e');
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
  // This ensures clean connection with new account number and new URL if needed
  Future<void> disconnectAndReconnect() async {
    if (_isDisposed) {
      if (kDebugMode) {
        dev.log('Account WS: Cannot disconnectAndReconnect - disposed');
      }
      return;
    }

    // Prevent concurrent reconnection attempts
    if (_isConnecting) {
      if (kDebugMode) {
        dev.log(
          'Account WS: Already connecting, skipping disconnectAndReconnect',
        );
      }
      return;
    }

    if (kDebugMode) {
      dev.log('Account WS: Disconnecting and reconnecting for account change');
    }

    // Fully disconnect WebSocket
    _disconnectWebSocket();

    // Wait for clean disconnect
    await Future.delayed(const Duration(milliseconds: 200));

    // Reset reconnection attempts for fresh start
    _reconnectAttempts = 0;

    // Reconnect with new account (will use new URL if trading_server changed)
    if (!_isDisposed && !_isConnecting) {
      _initializeWebSocket();
      if (kDebugMode) {
        dev.log('Account WS: Reconnected with new account');
      }
    }
  }
}
