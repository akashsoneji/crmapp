import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/dashboard_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/models/mt5_account.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/services/trading_websocket_service.dart';
import 'package:pipze/services/websocket_endpoint_helper.dart';
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

  // Data blocking during account switch
  String? _lastSubscribedAccount; // Track which account we're subscribed to
  bool _isUnsubscribing =
      false; // Flag to block data during unsubscribe/resubscribe

  // Account type tracking for endpoint switching
  String? _lastAccountType; // 'mt5' or 'selfhosted'
  String? _currentUrl; // Track current URL for debug logging
  bool _loggedFirstMessage = false;

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
        final accountTypeChanged =
            _lastAccountType != null && _lastAccountType != currentAccountType;

        if (accountTypeChanged) {
          if (kDebugMode) {
            dev.log(
              'Account WS: Account type changed from $_lastAccountType to $currentAccountType, forcing reconnection',
            );
          }

          // Account type changed - force full reconnection with new endpoints
          // This ensures all services switch to correct endpoints simultaneously
          _forceEndpointSwitch(currentAccountType);
        } else {
          // Same account type - use unsubscribeAndResubscribe for clean transition
          if (isConnected.value) {
            if (kDebugMode) {
              dev.log(
                'Account WS: Same account type switch, using unsubscribeAndResubscribe for clean transition',
              );
            }
            unsubscribeAndResubscribe();
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
      final activeAccount = _accountController.activeMT5Account;
      return activeAccount?.tradingServer.toUpperCase() == "MT5";
    } catch (e) {
      if (kDebugMode) {
        dev.log('Account WS: Error checking MT5 account: $e');
      }
      return false;
    }
  }

  // Get account type string for tracking changes
  String _getAccountType(MT5Account account) {
    return account.tradingServer.toUpperCase() == "MT5" ? 'mt5' : 'selfhosted';
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
  // ✅ Uses centralized WebSocketEndpointHelper for consistent endpoint selection
  String _getWebSocketUrl() {
    try {
      var activeAccount;

      // Try AccountController first
      try {
        activeAccount = _accountController.activeMT5Account;
      } catch (e) {
        // AccountController not available
      }

      // ✅ FIX: Fallback to stored primary account from initialization
      if (activeAccount == null) {
        activeAccount = WebSocketEndpointHelper.getStoredPrimaryAccount();
        if (kDebugMode && activeAccount != null) {
          dev.log(
            'Account WS: Using stored primary account from initialization',
          );
        }
      }

      // Try DashboardController as second fallback
      if (activeAccount == null) {
        try {
          if (Get.isRegistered<DashboardController>()) {
            final dashboardController = Get.find<DashboardController>();
            if (dashboardController.mt5Accounts.isNotEmpty) {
              activeAccount = dashboardController.primaryMT5Account;
              if (kDebugMode) {
                dev.log(
                  'Account WS: Got account from DashboardController: ${activeAccount?.metaAccountNumber ?? "N/A"}',
                );
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            dev.log('Account WS: DashboardController not available: $e');
          }
        }
      }

      // ✅ Use centralized endpoint helper
      final wsUrl = WebSocketEndpointHelper.getAccountUrl(activeAccount);
      final accountType = WebSocketEndpointHelper.getAccountType(activeAccount);

      if (kDebugMode) {
        dev.log(
          'Account WS: Using $accountType endpoint: $wsUrl (Account: ${activeAccount?.metaAccountNumber ?? "N/A"}, trading_server: ${activeAccount?.tradingServer ?? "N/A"})',
        );
      }
      return wsUrl;
    } catch (e) {
      // Fallback to self-hosted endpoint if all else fails
      if (kDebugMode) {
        dev.log(
          'Account WS: Error getting account, using default self-hosted endpoint: $e',
        );
      }
      return WebSocketEndpointHelper.getFullUrl(
        WebSocketEndpointHelper.selfHostedAccount,
      );
    }
  }

  // Initialize WebSocket connection
  void _initializeWebSocket() {
    if (isConnected.value || _isConnecting) return;

    _isConnecting = true;

    try {
      final wsUrl = _getWebSocketUrl();
      if (kDebugMode) {
        WebSocketEndpointHelper.logSwitchStep(
          'Account connect start',
          url: wsUrl,
        );
        dev.log(
          'Account WS: Endpoint change? prev=${_currentUrl ?? "none"} -> new=$wsUrl',
        );
      }

      channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      isConnected.value = true;
      _reconnectAttempts = 0;
      isReconnecting.value = false;
      _isConnecting = false;
      _currentUrl = wsUrl;
      _loggedFirstMessage = false;
      // Reset data blocking flags for new connection
      _isUnsubscribing = false;
      _lastSubscribedAccount = null;

      if (kDebugMode) {
        dev.log('Account WS: Connected successfully to $wsUrl');
      }

      channel!.stream.listen(
        (message) {
          if (!_loggedFirstMessage) {
            _loggedFirstMessage = true;
            WebSocketEndpointHelper.logSwitchStep(
              'Account first message',
              url: _currentUrl,
            );
          }
          _handleSocketMessage(message);
        },
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
          _currentUrl = null;
          _isConnecting = false;
          _scheduleReconnect();
        },
      );

      // Request account data after connection (reduced delay for faster MT5 response)
      Future.delayed(const Duration(milliseconds: 150), () async {
        if (isConnected.value && !_isDisposed) {
          // Ensure account controller is ready before requesting data
          final accountController = Get.find<AccountController>();
          final activeAccount = accountController.activeMT5Account;

          if (!accountController.isInitialized) {
            if (kDebugMode) {
              dev.log(
                'Account WS: Waiting for AccountController before requesting data...',
              );
            }
            await accountController.waitForInitialization();
            if (kDebugMode) {
              dev.log(
                'Account WS: AccountController ready, requesting account data',
              );
            }
          }

          // ✅ FIX: Log account info before requesting
          if (kDebugMode) {
            if (activeAccount != null) {
              dev.log(
                'Account WS: Requesting data for active account: ${activeAccount.metaAccountNumber} (${activeAccount.tradingServer})',
              );
            } else {
              dev.log('Account WS: No active account found, will retry');
            }
          }

          requestAccountData();
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
  void requestAccountData() async {
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
          requestAccountData();
        }
      });
      return;
    }

    // Set subscribed account before sending request
    _lastSubscribedAccount = accountNumber;
    _isUnsubscribing = false;

    if (kDebugMode) {
      dev.log('Account WS: Requesting data for account: $accountNumber');
      if (activeAccount != null) {
        dev.log(
          'Account WS: Active account details - Number: ${activeAccount.metaAccountNumber}, Type: ${activeAccount.tradingServer}',
        );
      }
    }

    // Get auth token for both MT5 and self-hosted accounts
    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) {
      if (kDebugMode) {
        dev.log('Account WS: No auth token, retrying in 2 seconds...');
      }
      Timer(const Duration(seconds: 2), () {
        if (isConnected.value && !_isDisposed) {
          requestAccountData();
        }
      });
      return;
    }

    // Check if this is an MT5 account
    if (_isMT5Account()) {
      // For MT5 accounts, send: { "type": "subscribe_accounts", "account": "400012", "authID": "token" }
      final requestPayload = {
        "type": "subscribe_accounts",
        "account": accountNumber,
        "authID": authId,
      };
      if (kDebugMode) {
        dev.log(
          'Account WS: Sending MT5 subscription request: $requestPayload',
        );
        WebSocketEndpointHelper.logSwitchStep(
          'Account subscribe sent',
          url: _currentUrl,
          payload: requestPayload,
        );
      }
      _sendEvent(requestPayload);
    } else {
      // For regular accounts, send: { "authID": "user_token", "trading_account": "301023" }
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
        if (kDebugMode && decodedData.isNotEmpty) {
          WebSocketEndpointHelper.logSwitchStep(
            'Account data received',
            url: _currentUrl,
          );
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
  // Format NEW (Length >= 10): ["ac", account, balance, credit, equity, margin, free_margin, margin_level, profit, swap]
  // Format OLD (Length < 10):  ["ac", account, balance, equity, margin, free_margin, margin_level, profit, swap]
  void _parseAccountArray(List accountArray) {
    try {
      if (accountArray.isEmpty) return;

      // Check if first element is "ac" (account type identifier)
      if (accountArray[0]?.toString().toLowerCase() != 'ac') {
        if (kDebugMode) {
          dev.log(
            'Account WS: Not an account array (first element: ${accountArray[0]})',
          );
        }
        return;
      }

      // Validate minimum array length (should have at least "ac" and account)
      if (accountArray.length < 2) {
        if (kDebugMode) {
          dev.log(
            'Account WS: Invalid account array length: ${accountArray.length} (expected at least 2)',
          );
        }
        return;
      }

      final metaAccountNumber =
          accountArray.length > 1 ? accountArray[1].toString() : '';

      // Block data if unsubscribing or during transition
      if (_isUnsubscribing) {
        if (kDebugMode) {
          dev.log(
            'Account WS: Blocking data during unsubscribe transition for account: $metaAccountNumber',
          );
        }
        return;
      }

      // Only process data for current active account
      final activeAccount = _accountController.activeMT5Account;
      if (activeAccount != null) {
        // If we have a last subscribed account, only process data for that account
        if (_lastSubscribedAccount != null &&
            metaAccountNumber != _lastSubscribedAccount) {
          if (kDebugMode) {
            dev.log(
              'Account WS: Ignoring data for old account: $metaAccountNumber (expecting: $_lastSubscribedAccount)',
            );
          }
          return;
        }

        // If no last subscribed account set yet, check against active account
        if (_lastSubscribedAccount == null &&
            metaAccountNumber != activeAccount.metaAccountNumber) {
          if (kDebugMode) {
            dev.log(
              'Account WS: Ignoring data for account: $metaAccountNumber (active: ${activeAccount.metaAccountNumber})',
            );
          }
          return;
        }
      }

      final balance =
          accountArray.length > 2
              ? double.tryParse(accountArray[2].toString()) ?? 0.0
              : 0.0;

      // Determine format version using heuristic check logic
      // We compare which format yields a consistent Account Equation:
      // Equity = Eq(Balance + Credit + Profit + Swap)

      bool isNewFormat = false;

      if (accountArray.length >= 9) {
        // Calculate Error for NEW FORMAT
        // [2]=Bal, [3]=Cred, [4]=Eq, [8]=Prof, [9]=Swap (if exists)
        final nBal = double.tryParse(accountArray[2].toString()) ?? 0.0;
        final nCred = double.tryParse(accountArray[3].toString()) ?? 0.0;
        final nEq = double.tryParse(accountArray[4].toString()) ?? 0.0;
        final nProf = double.tryParse(accountArray[8].toString()) ?? 0.0;
        final nSwap =
            accountArray.length > 9
                ? (double.tryParse(accountArray[9].toString()) ?? 0.0)
                : 0.0;

        final nDiff = (nEq - (nBal + nCred + nProf + nSwap)).abs();

        // Calculate Error for OLD FORMAT
        // [2]=Bal, [3]=Eq, [7]=Prof, [8]=Swap
        final oBal = double.tryParse(accountArray[2].toString()) ?? 0.0;
        final oEq = double.tryParse(accountArray[3].toString()) ?? 0.0;
        final oProf = double.tryParse(accountArray[7].toString()) ?? 0.0;
        final oSwap = double.tryParse(accountArray[8].toString()) ?? 0.0;

        final oDiff = (oEq - (oBal + oProf + oSwap)).abs();

        if (nDiff < oDiff && nDiff < 5.0) {
          isNewFormat = true;
        } else if (oDiff < nDiff && oDiff < 5.0) {
          isNewFormat = false;
        } else {
          // Default to New Format if length >= 10
          isNewFormat = true;
        }
      } else {
        isNewFormat = false;
      }

      double credit = 0.0;
      double equity = 0.0;
      double margin = 0.0;
      double freeMargin = 0.0;
      double marginLevel = 0.0;
      double profit = 0.0;
      double swap = 0.0;

      if (isNewFormat) {
        // NEW FORMAT
        credit =
            accountArray.length > 3
                ? double.tryParse(accountArray[3].toString()) ?? 0.0
                : 0.0;

        equity =
            accountArray.length > 4
                ? double.tryParse(accountArray[4].toString()) ?? 0.0
                : 0.0;

        margin =
            accountArray.length > 5
                ? double.tryParse(accountArray[5].toString()) ?? 0.0
                : 0.0;

        freeMargin =
            accountArray.length > 6
                ? double.tryParse(accountArray[6].toString()) ?? 0.0
                : 0.0;

        marginLevel =
            accountArray.length > 7
                ? double.tryParse(accountArray[7].toString()) ?? 0.0
                : 0.0;

        profit =
            accountArray.length > 8
                ? double.tryParse(accountArray[8].toString()) ?? 0.0
                : 0.0;

        swap =
            accountArray.length > 9
                ? double.tryParse(accountArray[9].toString()) ?? 0.0
                : 0.0;
      } else {
        // OLD FORMAT
        credit = 0.0; // Old format does not have a credit field

        equity =
            accountArray.length > 3
                ? double.tryParse(accountArray[3].toString()) ?? 0.0
                : 0.0;

        margin =
            accountArray.length > 4
                ? double.tryParse(accountArray[4].toString()) ?? 0.0
                : 0.0;

        freeMargin =
            accountArray.length > 5
                ? double.tryParse(accountArray[5].toString()) ?? 0.0
                : 0.0;

        marginLevel =
            accountArray.length > 6
                ? double.tryParse(accountArray[6].toString()) ?? 0.0
                : 0.0;

        profit =
            accountArray.length > 7
                ? double.tryParse(accountArray[7].toString()) ?? 0.0
                : 0.0;

        swap =
            accountArray.length > 8
                ? double.tryParse(accountArray[8].toString()) ?? 0.0
                : 0.0;

        if (kDebugMode) {
          dev.log(
            'Account WS: Detected OLD format (No Credit field). Length: ${accountArray.length}',
          );
        }
      }

      if (kDebugMode) {
        // dev.log(
        //   'Account WS: Parsed account data for $metaAccountNumber - Balance: $balance, Credit: $credit, Equity: $equity, Margin: $margin, Free Margin: $freeMargin, Margin Level: $marginLevel%, Profit: $profit, Swap: $swap',
        // );
      }

      // Create AccountInfo from parsed data
      final accountInfo = AccountInfo(
        assets: balance, // Assets = Balance (cash balance)
        balance: balance, // Cash balance (doesn't include unrealized P&L)
        blockedCommission: 0.0, // Not in array
        blockedProfit: 0.0, // Not in array
        credit: credit, // NEW Credit field
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

      // ✅ FIX: Always log parsed account data for debugging
      final accountLogin = accountInfo.login;
      print(
        '📊 Account WS: Parsed account data for $metaAccountNumber (login: $accountLogin) - Balance: $balance, Credit: $credit, Equity: $equity, Margin: $margin, Free Margin: $freeMargin, Margin Level: $marginLevel%, Profit: $profit, Swap: $swap',
      );
      print(
        '📤 Account WS: Calling TradingController.updateAccountInfoFromWebSocket() with login: $accountLogin',
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
      _currentUrl = null;
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
      requestAccountData();
    } else if (!isConnected.value) {
      _initializeWebSocket();
    }
  }

  // Subscribe to single symbol data (for MT5 accounts)
  void subscribeToSymbol(String symbol) async {
    final activeAccount = _accountController.activeMT5Account;
    if (activeAccount == null || !isConnected.value || channel == null) {
      if (kDebugMode) {
        dev.log(
          'Account WS: Cannot subscribe to symbol - no account or not connected',
        );
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
      "type": "subscribe_symbols",
    };

    _sendEvent(event);

    if (kDebugMode) {
      dev.log(
        'Account WS: Subscribed to symbol: $symbol for account: ${activeAccount.metaAccountNumber}',
      );
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
      "type": "unsubscribe_symbols",
    };

    _sendEvent(event);

    if (kDebugMode) {
      dev.log('Account WS: Unsubscribed from symbol: $symbol');
    }
  }

  // Public method to force endpoint switch (called by account controller)
  Future<void> forceEndpointSwitch(String accountType) async {
    if (kDebugMode) {
      dev.log(
        'Account WS: External force endpoint switch requested for $accountType',
      );
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

      // Step 1: Block incoming data BEFORE unsubscribe
      _isUnsubscribing = true;
      _lastSubscribedAccount = null;

      // Step 2: Unsubscribe from current subscription
      _unsubscribeCompleter = Completer<void>();
      _sendEvent({"type": "unsubscribe"});

      // Step 3: Wait for unsubscribe confirmation (with timeout)
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

      // Step 4: Small delay to let in-flight messages clear
      await Future.delayed(const Duration(milliseconds: 150));

      // Step 5: Resubscribe with new account
      final activeAccount = _accountController.activeMT5Account;
      if (activeAccount != null) {
        _lastSubscribedAccount = activeAccount.metaAccountNumber;
      }
      _isUnsubscribing = false;

      if (kDebugMode) {
        dev.log(
          'Account WS: Resubscribing with new account: ${activeAccount?.metaAccountNumber ?? "N/A"}',
        );
      }
      requestAccountData();

      if (kDebugMode) {
        dev.log('Account WS: Resubscribed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Account WS: Error in unsubscribeAndResubscribe: $e');
      }
      // Reset flags on error
      _isUnsubscribing = false;
      _lastSubscribedAccount = null;
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

    // Block data during disconnect
    _isUnsubscribing = true;
    _lastSubscribedAccount = null;

    // Fully disconnect WebSocket
    _disconnectWebSocket();

    // Small delay to ensure disconnect completes
    await Future.delayed(const Duration(milliseconds: 200));

    // Reset reconnection attempts for fresh start
    _reconnectAttempts = 0;

    // Reconnect with new account immediately (will use new URL if trading_server changed)
    if (!_isDisposed && !_isConnecting) {
      _initializeWebSocket();
      if (kDebugMode) {
        dev.log('Account WS: Reconnected with new account');
      }
    }
  }
}
