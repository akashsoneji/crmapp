import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';

import 'package:pipze/models/mt5_account.dart';
import 'package:pipze/models/websocket_trading_response.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/screens/home/create_pipze_account_screen.dart';
import 'package:pipze/controllers/account_controller.dart';
import 'package:pipze/controllers/instruments_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/screens/home/more/finance/deposit_screen.dart';
import 'package:pipze/screens/home/more/finance/payment_methods_screen.dart';

import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/controllers/auth_controller.dart';
import '../services/trading_websocket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../screens/home/dashboard_screen.dart';

class Account {
  final String accountNumber;
  final String type; // MT5
  final String status; // Standard
  final String label; // REAL, DEMO
  final double equity;
  final String currency;
  final List<String> actions;

  Account({
    required this.accountNumber,
    required this.type,
    required this.status,
    required this.label,
    required this.equity,
    required this.currency,
    required this.actions,
  });
}

class DashboardController extends GetxController {
  var accounts = <Account>[].obs;
  var mt5Accounts = <MT5Account>[].obs;
  var isBottomSheetOpen = false.obs;
  var isLoadingMT5Accounts = false.obs;
  var hasMT5Accounts = false.obs;
  var errorMessage = ''.obs;
  Function(int)? onNavigateToTab;

  // Single-flight + token ordering + throttle
  bool _isFetching = false;
  int _refreshToken = 0;
  DateTime? _lastFetchAt;

  // WebSocket for account data
  WebSocketChannel? _channel;
  final RxBool _isWebSocketConnected = false.obs;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  bool _isDisposed = false;
  DateTime? _lastReconnectAt;

  // Unsubscribe/resubscribe state
  Completer<void>? _unsubscribeCompleter;

  // Store AccountInfo for each account by account number
  final Map<String, AccountInfo> _accountInfoMap = {};
  final RxMap<String, AccountInfo> accountInfoMap = <String, AccountInfo>{}.obs;

  void setNavigationCallback(Function(int) callback) {
    onNavigateToTab = callback;
  }

  @override
  void onInit() {
    super.onInit();

    // Check if user is authenticated before making API calls
    try {
      final authController = Get.find<AuthController>();
      if (authController.isAuthenticated) {
        checkMT5Accounts();
      } else {
        print(
          'DashboardController: User not authenticated, skipping checkMT5Accounts',
        );
      }
    } catch (e) {
      final errorMsg = e.toString();
      errorMessage.value = errorMsg;
      print('DashboardController: Error checking auth status: $e');
      CustomToastService.showError(message: errorMsg);
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    _disconnectWebSocket();
    super.onClose();
  }

  void onResumed() {
    // Called when screen becomes visible again
    print('Called from ON RESUME');
    checkMT5Accounts();
  }

  void loadAccounts() {
    accounts.value = [
      Account(
        accountNumber: '5013314',
        type: 'MT5',
        status: 'Standard',
        label: 'REAL',
        equity: 500.00,
        currency: 'USD',
        actions: ['Deposit', 'Settings'],
      ),
      Account(
        accountNumber: '5013314',
        type: 'MT5',
        status: 'Standard',
        label: 'REAL',
        equity: 500.00,
        currency: 'USD',
        actions: ['Deposit', 'Withdraw'],
      ),
      Account(
        accountNumber: '5013314',
        type: 'MT5',
        status: 'Standard',
        label: 'DEMO',
        equity: 500.00,
        currency: 'USD',
        actions: ['Deposit', 'Settings'],
      ),
      Account(
        accountNumber: '5013314',
        type: 'MT5',
        status: 'Standard',
        label: 'DEMO',
        equity: 500.00,
        currency: 'USD',
        actions: ['Deposit', 'Settings'],
      ),
    ];
  }

  // Check MT5 accounts and redirect to account opening if none exist
  Future<void> checkMT5Accounts() async {
    try {
      if (_isFetching) {
        return;
      }
      _isFetching = true;
      final tokenOrder = ++_refreshToken;

      print('DashboardController: Starting checkMT5Accounts...');
      // Only show blocking loader when list is empty; otherwise refresh silently
      if (mt5Accounts.isEmpty) {
        isLoadingMT5Accounts.value = true;
      }
      final token = await SecureStorageService.getAuthToken();

      if (token == null || token.isEmpty) {
        print('DashboardController: No auth token found');
        isLoadingMT5Accounts.value = false;
        return;
      }

      print(
        'DashboardController: Making API call to ${ApiConstants.getMT5Accounts}',
      );
      final response = await ApiService.get(
        endpoint: ApiConstants.getMT5Accounts,
        token: token,
      );

      print('DashboardController: API response success: ${response.success}');
      print('DashboardController: API response data: ${response.data}');

      // Drop late responses
      if (tokenOrder != _refreshToken) {
        return;
      }

      if (response.success) {
        final data = response.data;
        print('MT5 Accounts Response: $data');

        if (data['status'] == true && data['data'] != null) {
          final accountsData = data['data'] as List;
          print(
            'DashboardController: Found ${accountsData.length} accounts in response',
          );
          hasMT5Accounts.value = false;
          mt5Accounts.clear();

          if (accountsData.isNotEmpty) {
            // User has MT5 accounts
            final parsedAccounts =
                accountsData
                    .map((account) => MT5Account.fromJson(account))
                    .toList();

            print(
              'DashboardController: Parsed ${parsedAccounts.length} MT5 accounts',
            );
            for (var account in parsedAccounts) {
              print(
                'Account: ${account.metaAccountNumber} - ${account.accountType} - Primary: ${account.isPrimaryAccount}',
              );
            }

            // Sort with primary account first
            parsedAccounts.sort((a, b) {
              final ai = a.isPrimaryAccount ? 0 : 1;
              final bi = b.isPrimaryAccount ? 0 : 1;
              return ai.compareTo(bi);
            });

            mt5Accounts.assignAll(parsedAccounts);
            hasMT5Accounts.value = true;
            print(
              'DashboardController: Updated mt5Accounts observable with ${mt5Accounts.length} accounts',
            );

            // Initialize WebSocket connection for account data
            _initializeWebSocket();

            // Notify account controller if it exists
            _notifyAccountController();

            // Also trigger a refresh for any waiting controllers
            _triggerAccountRefresh();
          } else {
            // User has no MT5 accounts - redirect to account opening
            hasMT5Accounts.value = false;
            mt5Accounts.clear();
            print('User has no MT5 accounts - redirecting to account opening');
            // _redirectToAccountOpening();
          }
        } else {
          // API returned error or no data
          hasMT5Accounts.value = false;
          mt5Accounts.clear();
          final errorMsg =
              data['message']?.toString() ?? 'Failed to fetch MT5 accounts';
          errorMessage.value = errorMsg;
          print('MT5 accounts API error: $errorMsg');
          CustomToastService.showError(message: errorMsg);
          // _redirectToAccountOpening();
        }
      } else {
        // API call failed
        hasMT5Accounts.value = false;
        mt5Accounts.clear();
        final errorMsg = response.message ?? 'Failed to fetch MT5 accounts';
        errorMessage.value = errorMsg;
        print('Failed to fetch MT5 accounts: $errorMsg');
        CustomToastService.showError(message: errorMsg);
        // _redirectToAccountOpening();
      }
    } catch (e, t) {
      hasMT5Accounts.value = false;
      mt5Accounts.clear();
      final errorMsg = e.toString();
      errorMessage.value = errorMsg;
      print('Exception in checkMT5Accounts: $e');
      print('Exception in checkMT5Accounts: $t');
      CustomToastService.showError(message: errorMsg);
      // _redirectToAccountOpening();
    } finally {
      _lastFetchAt = DateTime.now();
      _isFetching = false;
      isLoadingMT5Accounts.value = false;
      print(
        'DashboardController: checkMT5Accounts completed. hasMT5Accounts: ${hasMT5Accounts.value}, mt5Accounts count: ${mt5Accounts.length}',
      );
    }
  }

  // Redirect to account opening screen
  Future<void> changePrimaryAccount(String accountNumber) async {
    try {
      isLoadingMT5Accounts.value = true;
      final token = await SecureStorageService.getAuthToken();

      if (token == null || token.isEmpty) {
        print('DashboardController: No auth token found');
        isLoadingMT5Accounts.value = false;
        return;
      }

      final response = await ApiService.post(
        endpoint: ApiConstants.changePrimaryAccount,
        token: token,
        data: {'mt5_account': accountNumber},
      );
      // {
      // "status": true,
      // "message": "Primary account changed successfully",
      // "data": []
      // }

      if (response.success) {
        final data = response.data;
        print('MT5 Accounts Response: $data');

        CustomToastService.showSuccess(message: data['message']);

        // Close loading indicator first
        isLoadingMT5Accounts.value = false;

        // IMPORTANT: Refresh accounts to update primary account status in UI
        await checkMT5Accounts();

        // Unsubscribe and resubscribe WebSocket to refresh account data
        unsubscribeAndResubscribe();

        // Notify WebSocket service about account change
        try {
          final tradingWebSocketService = Get.find<TradingWebSocketService>();
          tradingWebSocketService.forceRefreshTradingData();
          print(
            'DashboardController: Refreshed trading WebSocket data after account change',
          );
        } catch (e) {
          print('TradingWebSocketService not found: $e');
        }
      } else {
        // API call failed
        hasMT5Accounts.value = false;
        isLoadingMT5Accounts.value = false;
        final errorMsg = response.message ?? 'Failed to change primary account';
        errorMessage.value = errorMsg;
        print('Failed to fetch MT5 accounts: $errorMsg');
        CustomToastService.showError(message: errorMsg);
        // _redirectToAccountOpening();
      }
    } catch (e) {
      hasMT5Accounts.value = false;
      isLoadingMT5Accounts.value = false;
      final errorMsg = e.toString();
      errorMessage.value = errorMsg;
      print('Exception in changePrimaryAccount: $e');
      CustomToastService.showError(message: errorMsg);
      // _redirectToAccountOpening();
    }
  }

  // void _redirectToAccountOpening() {
  //   // Show a message to the user
  //   CustomToastService.showInfo(
  //     message: 'You need to open a trading account to continue',
  //     title: 'Account Required',
  //   );

  //   // Navigate to account opening after a short delay
  //   Future.delayed(const Duration(seconds: 2), () {
  //     showOpenAccountSheet();
  //   });
  // }

  void showOpenAccountSheet() {
    isBottomSheetOpen.value = true;
    Get.bottomSheet(
      OpenAccountBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: Duration(milliseconds: 300),
      exitBottomSheetDuration: Duration(milliseconds: 300),
    ).then((_) {
      isBottomSheetOpen.value = false;
    });
  }

  void openRealAccount() {
    Get.back(); // Close bottom sheet
    Get.toNamed(Routes.CHOOSE_ACCOUNT);
  }

  void openDemoAccount() {
    Get.back(); // Close bottom sheet
    // Get.toNamed(Routes.OPEN_ACCOUNT);
    // Get.to(() => CreateTradingAccountScreen(accountType: 'Demo'));
    Get.to(() => CreatePipzeAccountScreen(accountType: 'Demo', isDemo: true));

    // Get.to(() => CreateOpenAccountScreen(accountType: 'Demo'));
  }

  void onDeposit(String accountNumber) async {
    print(accountNumber);
    await Get.to(() => DepositScreen(accountNumber: accountNumber));
    // Refresh MT5 accounts when returning from deposit (demo) flow
    await refreshMT5Accounts();
    // Get.toNamed(AppPages.DEPOSIT);
    // Get.snackbar(
    //   'Deposit',
    //   'Deposit for account $accountNumber',
    //   snackPosition: SnackPosition.BOTTOM,
    // );
  }

  void onDepositRealAccount(String accountNumber) async {
    print(
      'DashboardController: onDepositRealAccount called with accountNumber: $accountNumber (type: ${accountNumber.runtimeType})',
    );
    // Get.to(() => DepositRealScreen(accountNumber: accountNumber));
    await Get.to(
      () => PaymentMethodsScreen(accountNumber: accountNumber.toString()),
    );
    // Refresh MT5 accounts when returning from real deposit flow
    await refreshMT5Accounts();
  }

  void onWithdraw(String accountNumber) {
    Get.toNamed(AppPages.WITHDRAWAL);
    // Get.snackbar(
    //   'Withdraw',
    //   'Withdraw for account $accountNumber',
    //   snackPosition: SnackPosition.BOTTOM,
    // );
  }

  void onSettings(String accountNumber) {
    // Navigate to More tab (index 4) in bottom navigation
    if (onNavigateToTab != null) {
      onNavigateToTab!(4); // Index 4 is the More tab
    }
  }

  void switchToTrade(String accountNumber) {
    changePrimaryAccount(accountNumber);
  }

  // Refresh MT5 accounts data with throttle
  Future<void> refreshMT5Accounts({bool force = false}) async {
    if (_isFetching) return;
    if (!force && _lastFetchAt != null) {
      final diff = DateTime.now().difference(_lastFetchAt!);
      if (diff.inMilliseconds < 1500) {
        return;
      }
    }
    await checkMT5Accounts();
  }

  // Called from UI on each appearance to ensure fresh data without flicker
  void maybeRefreshOnAppear() {
    // Unsubscribe and resubscribe WebSocket when screen appears (fixes logout/login issue)
    // Throttle to prevent too frequent reconnections (max once per 2 seconds)
    if (_lastReconnectAt == null ||
        DateTime.now().difference(_lastReconnectAt!).inSeconds >= 2) {
      unsubscribeAndResubscribe();
    }

    if (_isFetching) return;
    if (_lastFetchAt == null) {
      // First time
      refreshMT5Accounts(force: true);
      return;
    }
    final diff = DateTime.now().difference(_lastFetchAt!);
    if (diff.inMilliseconds > 2000) {
      refreshMT5Accounts();
    }
  }

  // Force check MT5 accounts (public method)
  Future<void> forceCheckMT5Accounts() async {
    print('DashboardController: Force checking MT5 accounts...');
    await checkMT5Accounts();
  }

  // Create new MT5 account
  Future<Map<String, dynamic>?> createMT5Account({
    int? groupId,
    required String mainPassword,
    required String investorPassword,
    required String accountType,
    String? leverage,
  }) async {
    try {
      print('DashboardController: Creating MT5 account...');
      print('Group ID: $groupId');
      print('Account Type: $accountType');

      isLoadingMT5Accounts.value = true;
      errorMessage.value = '';

      final token = await SecureStorageService.getAuthToken();

      Map<String, dynamic> requestData = {};
      if (groupId != null) {
        requestData = {
          'group_id': groupId,
          'main_password': mainPassword,
          'investor_password': investorPassword,
          'account_type': accountType,
          if (leverage != null && leverage.isNotEmpty) 'leverage': leverage,
        };
      } else {
        requestData = {
          'main_password': mainPassword,
          'investor_password': investorPassword,
          'account_type': accountType,
          if (leverage != null && leverage.isNotEmpty) 'leverage': leverage,
        };
      }

      print(
        'DashboardController: Making API call to ${ApiConstants.createMT5Account}',
      );
      print('DashboardController: Request data: $requestData');

      final response = await ApiService.post(
        endpoint: ApiConstants.createMT5Account,
        data: requestData,
        token: token,
      );

      print(
        'DashboardController: Create account API response success: ${response.success}',
      );
      print(
        'DashboardController: Create account API response data: ${response.data}',
      );

      if (response.success) {
        print('DashboardController: MT5 account created successfully');

        // Refresh MT5 accounts after successful creation
        await checkMT5Accounts();

        // Return the account data including account number
        return response.data;
      } else {
        final errorMsg = response.message ?? 'Failed to create MT5 account';
        errorMessage.value = errorMsg;
        print('DashboardController: Failed to create MT5 account: $errorMsg');
        CustomToastService.showError(message: errorMsg);
        return null;
      }
    } catch (e) {
      final errorMsg = e.toString();
      errorMessage.value = errorMsg;
      print('DashboardController: Error creating MT5 account: $e');
      CustomToastService.showError(message: errorMsg);
      return null;
    } finally {
      isLoadingMT5Accounts.value = false;
    }
  }

  // Get primary MT5 account
  MT5Account? get primaryMT5Account {
    try {
      return mt5Accounts.firstWhere((account) => account.isPrimaryAccount);
    } catch (e) {
      return mt5Accounts.isNotEmpty ? mt5Accounts.first : null;
    }
  }

  // Get real MT5 accounts only
  List<MT5Account> get realMT5Accounts {
    return mt5Accounts.where((account) => account.isRealAccount).toList();
  }

  // Get demo MT5 accounts only
  List<MT5Account> get demoMT5Accounts {
    return mt5Accounts.where((account) => account.isDemoAccount).toList();
  }

  // Notify account controller about MT5 account changes
  void _notifyAccountController() {
    try {
      // Check if account controller exists and notify it
      if (Get.isRegistered<AccountController>()) {
        final accountController = Get.find<AccountController>();
        // Force update the account controller's MT5 accounts
        accountController.updateMT5Accounts(mt5Accounts);
        print(
          'Notified AccountController about MT5 account changes: ${mt5Accounts.length} accounts',
        );

        // Force refresh account data to ensure UI updates
        Future.delayed(Duration(milliseconds: 100), () {
          accountController.forceRefreshAccountData();
        });
      }
    } catch (e) {
      print('AccountController not found or error notifying: $e');
    }
  }

  void _triggerAccountRefresh() {
    // Trigger refresh for any controllers that depend on account data
    try {
      if (Get.isRegistered<InstrumentsController>()) {
        final instrumentsController = Get.find<InstrumentsController>();
        instrumentsController.refreshSocketData();
        print(
          'DashboardController: Refreshed InstrumentsController socket data',
        );
      }
    } catch (e) {
      print('Error refreshing InstrumentsController: $e');
    }

    try {
      if (Get.isRegistered<TradingController>()) {
        // TradingController found, account data updated
        print(
          'DashboardController: TradingController found, account data updated',
        );
      }
    } catch (e) {
      print('Error refreshing TradingController: $e');
    }
  }

  // Initialize WebSocket connection to /ws/accounts
  void _initializeWebSocket() {
    if (_isWebSocketConnected.value || _isDisposed) return;

    try {
      final wsUrl = '${ApiConstants.socketUrl}/ws/accounts';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isWebSocketConnected.value = true;
      _reconnectAttempts = 0;

      if (kDebugMode) {
        dev.log('Dashboard WS: Connected successfully to $wsUrl');
      }

      _channel!.stream.listen(
        (message) => _handleSocketMessage(message),
        onError: (error) {
          if (kDebugMode) {
            dev.log('Dashboard WS error: $error');
          }
          _isWebSocketConnected.value = false;
          _scheduleReconnect();
        },
        onDone: () {
          if (kDebugMode) {
            dev.log('Dashboard WS: Connection closed');
          }
          _isWebSocketConnected.value = false;
          _scheduleReconnect();
        },
      );

      // Request account data after connection with proper delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_isWebSocketConnected.value && !_isDisposed) {
          _requestAccountData();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Initialization failed: $e');
      }
      _isWebSocketConnected.value = false;
      _scheduleReconnect();
    }
  }

  // Request account data from WebSocket for all accounts
  void _requestAccountData() async {
    if (_isDisposed || !_isWebSocketConnected.value || _channel == null) {
      return;
    }

    // Get auth token
    final authId = await SecureStorageService.getAuthToken();
    if (authId == null || authId.isEmpty) {
      Timer(const Duration(seconds: 2), () {
        if (_isWebSocketConnected.value && !_isDisposed) {
          _requestAccountData();
        }
      });
      return;
    }

    // Subscribe to all MT5 accounts
    for (final account in mt5Accounts) {
      final accountNumber = account.metaAccountNumber;
      if (accountNumber.isNotEmpty && accountNumber != "0") {
        if (kDebugMode) {
          dev.log('Dashboard WS: Requesting data for account: $accountNumber');
        }
        _sendEvent({"authID": authId, "trading_account": accountNumber});
        // Small delay between subscriptions
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  // Handle incoming WebSocket messages
  void _handleSocketMessage(dynamic message) {
    if (_isDisposed) return;

    try {
      final String messageStr = message.toString();
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
        dev.log('Dashboard WS: Error parsing message: $e\n$stackTrace');
      }
    }
  }

  // Parse account array response
  // Format: ["ac", account, balance, equity, margin, free_margin, margin_level, profit, swap]
  void _parseAccountArray(List accountArray) {
    try {
      if (accountArray.isEmpty) return;

      // Check if first element is "ac" (account type identifier)
      if (accountArray[0]?.toString().toLowerCase() != 'ac') {
        return;
      }

      if (accountArray.length < 2) {
        return;
      }

      // Parse array elements
      final metaAccountNumber =
          accountArray.length > 1 ? accountArray[1].toString() : '';
      final balance =
          accountArray.length > 2
              ? double.tryParse(accountArray[2].toString()) ?? 0.0
              : 0.0;
      final equity =
          accountArray.length > 3
              ? double.tryParse(accountArray[3].toString()) ?? 0.0
              : 0.0;
      final margin =
          accountArray.length > 4
              ? double.tryParse(accountArray[4].toString()) ?? 0.0
              : 0.0;
      final freeMargin =
          accountArray.length > 5
              ? double.tryParse(accountArray[5].toString()) ?? 0.0
              : 0.0;
      final marginLevel =
          accountArray.length > 6
              ? double.tryParse(accountArray[6].toString()) ?? 0.0
              : 0.0;
      final profit =
          accountArray.length > 7
              ? double.tryParse(accountArray[7].toString()) ?? 0.0
              : 0.0;
      final swap =
          accountArray.length > 8
              ? double.tryParse(accountArray[8].toString()) ?? 0.0
              : 0.0;

      // Create AccountInfo from parsed data
      final accountInfo = AccountInfo(
        assets: balance,
        balance: balance,
        blockedCommission: 0.0,
        blockedProfit: 0.0,
        credit: 0.0,
        currencyDigits: 2,
        equity: equity,
        floating: profit,
        liabilities: 0.0,
        login: int.tryParse(metaAccountNumber) ?? 0,
        margin: margin,
        marginFree: freeMargin,
        marginInitial: 0.0,
        marginLevel: marginLevel,
        marginLeverage: 0,
        marginMaintenance: 0.0,
        profit: profit,
        soActivation: 0.0,
        soEquity: 0.0,
        soLevel: 0.0,
        soMargin: 0.0,
        soTime: 0.0,
        storage: swap,
      );

      // Update account info map
      _accountInfoMap[metaAccountNumber] = accountInfo;
      accountInfoMap[metaAccountNumber] = accountInfo;

      if (kDebugMode) {
        dev.log(
          'Dashboard WS: Updated account info for $metaAccountNumber - Balance: $balance, Equity: $equity',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Error parsing account array: $e\n$stackTrace');
      }
    }
  }

  // Handle JSON object responses (authentication, errors, etc.)
  void _handleJsonResponse(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    // Handle unsubscribe confirmation
    if (type == 'unsubscribed') {
      if (kDebugMode) {
        dev.log('Dashboard WS: ✅ Unsubscribed successfully');
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
      if (status == 'success' && kDebugMode) {
        dev.log('Dashboard WS: ✅ Authenticated: ${data['message']}');
      }
      return;
    }

    // Handle error responses
    if (type == 'error') {
      final errorMessage = data['message']?.toString() ?? 'Unknown error';
      if (kDebugMode) {
        dev.log('Dashboard WS: ❌ Error: $errorMessage');
      }
      // Complete unsubscribe completer even on error to avoid hanging
      if (_unsubscribeCompleter != null &&
          !_unsubscribeCompleter!.isCompleted) {
        _unsubscribeCompleter!.complete();
        _unsubscribeCompleter = null;
      }
      return;
    }
  }

  // Send event with parameters over WebSocket
  void _sendEvent(Map<String, dynamic> event) {
    try {
      if (_channel == null) return;
      final encoded = jsonEncode(event);
      _channel!.sink.add(encoded);
      if (kDebugMode) {
        dev.log('Dashboard WS: Sent event: $encoded');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Error sending event: $e');
      }
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _isDisposed) {
      return;
    }

    if (_reconnectTimer?.isActive == true) return;

    _reconnectAttempts++;
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectWebSocket();
    });
  }

  // Reconnect WebSocket
  void _reconnectWebSocket() {
    if (_isWebSocketConnected.value || _isDisposed) return;

    try {
      _disconnectWebSocket();
      _initializeWebSocket();
    } catch (e) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Reconnection failed: $e');
      }
      _scheduleReconnect();
    }
  }

  // Disconnect WebSocket
  void _disconnectWebSocket() {
    try {
      _channel?.sink.close();
      _isWebSocketConnected.value = false;
      _reconnectTimer?.cancel();
    } catch (e) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Error disconnecting: $e');
      }
    }
  }

  // Get AccountInfo for a specific account
  AccountInfo? getAccountInfo(String accountNumber) {
    return accountInfoMap[accountNumber];
  }

  // Unsubscribe and resubscribe with accounts (keeps socket active)
  Future<void> unsubscribeAndResubscribe() async {
    if (_isDisposed) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Cannot unsubscribeAndResubscribe - disposed');
      }
      return;
    }

    // If not connected, just initialize normally
    if (!_isWebSocketConnected.value) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Not connected, initializing normally');
      }
      _initializeWebSocket();
      return;
    }

    try {
      if (kDebugMode) {
        dev.log(
          'Dashboard WS: Unsubscribing and resubscribing for screen appearance',
        );
      }

      // Update last reconnect time
      _lastReconnectAt = DateTime.now();

      // Step 1: Unsubscribe from current subscriptions
      _unsubscribeCompleter = Completer<void>();
      _sendEvent({"type": "unsubscribe"});

      // Step 2: Wait for unsubscribe confirmation (with timeout)
      try {
        await _unsubscribeCompleter!.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            if (kDebugMode) {
              dev.log('Dashboard WS: Unsubscribe timeout, proceeding anyway');
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
          dev.log('Dashboard WS: Error waiting for unsubscribe: $e');
        }
      }

      // Step 3: Resubscribe with all accounts
      if (kDebugMode) {
        dev.log('Dashboard WS: Resubscribing with accounts');
      }
      _requestAccountData();

      if (kDebugMode) {
        dev.log('Dashboard WS: Resubscribed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Error in unsubscribeAndResubscribe: $e');
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

  // Disconnect and reconnect WebSocket (for logout/login scenarios)
  Future<void> disconnectAndReconnect() async {
    if (_isDisposed) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Cannot disconnectAndReconnect - disposed');
      }
      return;
    }

    if (kDebugMode) {
      dev.log(
        'Dashboard WS: Disconnecting and reconnecting for screen appearance',
      );
    }

    // Update last reconnect time
    _lastReconnectAt = DateTime.now();

    // Fully disconnect WebSocket
    _disconnectWebSocket();

    // Wait for clean disconnect
    await Future.delayed(const Duration(milliseconds: 150));

    // Reset reconnection attempts for fresh start
    _reconnectAttempts = 0;

    // Reconnect with accounts
    if (!_isDisposed) {
      _initializeWebSocket();
      if (kDebugMode) {
        dev.log('Dashboard WS: Reconnected after screen appearance');
      }
    }
  }
}
