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
import 'package:pipze/screens/home/more/finance/withdrawal_screen.dart';

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
  String? _currentWebSocketEndpoint; // Track current endpoint to detect changes

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
        print(
          'Failed to fetch MT5 accounts from dashboard controller: $errorMsg',
        );
        // CustomToastService.showError(message: errorMsg);
        // _redirectToAccountOpening();
      }
    } catch (e, t) {
      hasMT5Accounts.value = false;
      mt5Accounts.clear();
      final errorMsg = e.toString();
      errorMessage.value = errorMsg;
      print('Exception in checkMT5Accounts: $e');
      print('Exception in checkMT5Accounts: $t');
      // CustomToastService.showError(message: errorMsg);
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
        print(
          'Failed to fetch MT5 accounts from dashboard controller: $errorMsg',
        );
        // CustomToastService.showError(message: errorMsg);
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

  void onWithdraw(String accountNumber) async {
    await Get.to(() => WithdrawalScreen(accountNumber: accountNumber));
    // Refresh MT5 accounts when returning from withdrawal
    await refreshMT5Accounts();
  }

  void onSettings(String accountNumber) {
    // Navigate to More tab (index 4) in bottom navigation
    if (onNavigateToTab != null) {
      onNavigateToTab!(4); // Index 4 is the More tab
    }
  }

  void switchToTrade(String accountNumber) async {
    await changePrimaryAccount(accountNumber);
    // Navigate to Trade screen (index 2) and update bottom navigation
    if (onNavigateToTab != null) {
      onNavigateToTab!(2); // Trade screen is at index 2
    }
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

  // Mark MT5 accounts data as stale (for refresh when returning to dashboard)
  // This doesn't call the API immediately, but ensures data refreshes when user returns
  void markMT5AccountsAsStale() {
    print('DashboardController: Marking MT5 accounts data as stale');
    _lastFetchAt =
        null; // Reset last fetch time so data refreshes on next appearance
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
      // ✅ FIX: Check primary account's tradingServer to determine correct endpoint
      final primaryAccount = primaryMT5Account;
      final isMT5Account = primaryAccount?.tradingServer == "MT5";
      final wsUrl =
          isMT5Account
              ? '${ApiConstants.socketUrl}/ws/mt5/account' // MT5 endpoint for MT5 accounts
              : '${ApiConstants.socketUrl}/ws/accounts'; // Self-hosted endpoint (note: /ws/account not /ws/accounts)

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isWebSocketConnected.value = true;
      _reconnectAttempts = 0;
      _currentWebSocketEndpoint = wsUrl; // Store current endpoint

      if (kDebugMode) {
        dev.log(
          'Dashboard WS: Connected successfully to $wsUrl (Primary Account: ${primaryAccount?.metaAccountNumber}, Trading Server: ${primaryAccount?.tradingServer ?? "N/A"}, Is MT5: $isMT5Account)',
        );
      }

      // print('Dashboard WS: Connected to $wsUrl');
      // print('  Primary Account: ${primaryAccount?.metaAccountNumber ?? "N/A"}');
      // print('  Trading Server: ${primaryAccount?.tradingServer ?? "N/A"}');
      // print('  Is MT5: $isMT5Account');

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

      // Request account data after connection - minimal delay for faster initialization
      Future.delayed(const Duration(milliseconds: 10), () {
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

    // ✅ FIX: Use primary account number instead of all accounts
    final primaryAccount = primaryMT5Account;
    if (primaryAccount != null) {
      final accountNumber = primaryAccount.metaAccountNumber;
      if (accountNumber.isNotEmpty && accountNumber != "0") {
        if (kDebugMode) {
          dev.log(
            'Dashboard WS: Requesting data for PRIMARY account: $accountNumber (Trading Server: ${primaryAccount.tradingServer})',
          );
        }
        print(
          'Dashboard WS: Requesting data for PRIMARY account: $accountNumber',
        );
        print('  Trading Server: ${primaryAccount.tradingServer}');

        // Send request with primary account number
        _sendEvent({"authID": authId, "trading_account": accountNumber});
      } else {
        if (kDebugMode) {
          dev.log(
            'Dashboard WS: Primary account number is empty or invalid: $accountNumber',
          );
        }
        print(
          '⚠️ Dashboard WS: Primary account number is empty or invalid: $accountNumber',
        );
      }
    } else {
      if (kDebugMode) {
        dev.log(
          'Dashboard WS: No primary account found, cannot request account data',
        );
      }
      print(
        '⚠️ Dashboard WS: No primary account found, cannot request account data',
      );
    }
  }

  // Handle incoming WebSocket messages
  void _handleSocketMessage(dynamic message) {
    if (_isDisposed) return;

    try {
      final String messageStr = message.toString();
      final dynamic decodedData = jsonDecode(messageStr);

      // Log WebSocket response for AccountInfoBottomSheet data - Always log
      final primaryAccount = primaryMT5Account;
      final isMT5Account = primaryAccount?.tradingServer == "MT5";
      final endpoint =
          _isWebSocketConnected.value
              ? (isMT5Account
                  ? "${ApiConstants.socketUrl}/ws/mt5/account"
                  : "${ApiConstants.socketUrl}/ws/accounts")
              : "Not connected";

      // dev.log(
      //   '═══════════════════════════════════════════════════════════',
      //   name: 'DASHBOARD_WS_RESPONSE',
      // );
      // dev.log(
      //   '📥 WEBSOCKET RESPONSE (Dashboard - AccountInfoBottomSheet Data Source)',
      //   name: 'DASHBOARD_WS_RESPONSE',
      // );
      // dev.log('Endpoint: $endpoint', name: 'DASHBOARD_WS_RESPONSE');
      // dev.log('Response:', name: 'DASHBOARD_WS_RESPONSE');

      // print('═══════════════════════════════════════════════════════════');
      // print('📥 DASHBOARD_WS_RESPONSE - AccountInfoBottomSheet Data Source');
      // print('Endpoint: $endpoint');
      // print('Response:');

      try {
        if (decodedData is Map) {
          final formatted = JsonEncoder.withIndent('  ').convert(decodedData);
          // dev.log(formatted, name: 'DASHBOARD_WS_RESPONSE');
          print(formatted);
        } else if (decodedData is List) {
          // dev.log(
          //   'Array with ${decodedData.length} items:',
          //   name: 'DASHBOARD_WS_RESPONSE',
          // );
          // print('Array with ${decodedData.length} items:');
          if (decodedData.length <= 10) {
            final formatted = JsonEncoder.withIndent('  ').convert(decodedData);
            // dev.log(formatted, name: 'DASHBOARD_WS_RESPONSE');
            // print(formatted);
          } else {
            // dev.log(
            //   '  [First 5 items shown, total: ${decodedData.length}]',
            //   name: 'DASHBOARD_WS_RESPONSE',
            // );
            print('  [First 5 items shown, total: ${decodedData.length}]');
            final firstFive = decodedData.take(5).toList();
            final formatted = JsonEncoder.withIndent('  ').convert(firstFive);
            // dev.log(formatted, name: 'DASHBOARD_WS_RESPONSE');
            // print(formatted);
          }
        } else {
          // dev.log('  $decodedData', name: 'DASHBOARD_WS_RESPONSE');
          // print('  $decodedData');
        }
      } catch (e) {
        // dev.log('  $messageStr', name: 'DASHBOARD_WS_RESPONSE');
        // print('  $messageStr');
      }
      // dev.log(
      //   '═══════════════════════════════════════════════════════════',
      //   name: 'DASHBOARD_WS_RESPONSE',
      // );
      // print('═══════════════════════════════════════════════════════════');

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
  // Format NEW (Length >= 10): ["ac", account, balance, credit, equity, margin, free_margin, margin_level, profit, swap]
  // Format OLD (Length < 10):  ["ac", account, balance, equity, margin, free_margin, margin_level, profit, swap]
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

      // Determine format version using heuristic check logic
      // We compare which format yields a consistent Account Equation:
      // Equity = Eq(Balance + Credit + Profit + Swap)

      bool isNewFormat = false;

      // Check heuristic if length is sufficient (at least 9 for either format)
      if (accountArray.length >= 9) {
        // Calculate Error for NEW FORMAT
        // [2]=Bal, [3]=Cred, [4]=Eq, [8]=Prof, [9]=Swap (if exists)
        final nBal = double.tryParse(accountArray[2].toString()) ?? 0.0;
        final nCred = double.tryParse(accountArray[3].toString()) ?? 0.0;
        final nEq = double.tryParse(accountArray[4].toString()) ?? 0.0;
        final nProf = double.tryParse(accountArray[8].toString()) ?? 0.0;
        // Swap might be missing in length 9 array
        final nSwap =
            accountArray.length > 9
                ? (double.tryParse(accountArray[9].toString()) ?? 0.0)
                : 0.0;

        // Expected Equity = Bal + Cred + Prof + Swap
        final nDiff = (nEq - (nBal + nCred + nProf + nSwap)).abs();

        // Calculate Error for OLD FORMAT
        // [2]=Bal, [3]=Eq, [7]=Prof, [8]=Swap
        // Assuming Credit is 0 in old format (or implicit)
        final oBal = double.tryParse(accountArray[2].toString()) ?? 0.0;
        final oEq = double.tryParse(accountArray[3].toString()) ?? 0.0;
        final oProf = double.tryParse(accountArray[7].toString()) ?? 0.0;
        final oSwap = double.tryParse(accountArray[8].toString()) ?? 0.0;

        final oDiff = (oEq - (oBal + oProf + oSwap)).abs();

        // If New Format error is significantly smaller, use it
        if (nDiff < oDiff && nDiff < 5.0) {
          isNewFormat = true;
        } else if (oDiff < nDiff && oDiff < 5.0) {
          isNewFormat = false; // Only use Old if Old Math is clearly better
        } else {
          // Fallback: If length is >= 10, it's most likely the NEW format.
          // The extra field (Credit) is present.
          isNewFormat = true;
        }
      } else {
        // Not enough data for New Format, must be Old
        isNewFormat = false;
      }

      // Parse array elements
      final metaAccountNumber =
          accountArray.length > 1 ? accountArray[1].toString() : '';

      final balance =
          accountArray.length > 2
              ? double.tryParse(accountArray[2].toString()) ?? 0.0
              : 0.0;

      // Conditional parsing based on format
      double credit = 0.0;
      double equity = 0.0;
      double margin = 0.0;
      double freeMargin = 0.0;
      double marginLevel = 0.0;
      double profit = 0.0;
      double swap = 0.0;

      if (isNewFormat) {
        // NEW FORMAT: [..., balance, credit, equity, ...]
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
        // OLD FORMAT: [..., balance, equity, margin, ...]
        // Credit is missing, defaulting to 0.0
        credit = 0.0;

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
            'Dashboard WS: Detected OLD format (No Credit field). Length: ${accountArray.length}',
          );
        }
      }

      // Create AccountInfo from parsed data
      final accountInfo = AccountInfo(
        assets: balance,
        balance: balance,
        blockedCommission: 0.0,
        blockedProfit: 0.0,
        credit: credit,
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

      // ✅ FIX: Notify TradingController about account info update
      // This ensures the Trade screen displays the correct account metrics
      try {
        if (Get.isRegistered<TradingController>()) {
          final tradingController = Get.find<TradingController>();
          tradingController.updateAccountInfoFromWebSocket(accountInfo);
        }
      } catch (e) {
        if (kDebugMode) {
          dev.log('Dashboard WS: Error notifying TradingController: $e');
        }
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
        // dev.log('Dashboard WS: ✅ Authenticated: ${data['message']}');
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

      // Always log - both dev.log and print for visibility
      final primaryAccount = primaryMT5Account;
      final isMT5Account = primaryAccount?.tradingServer == "MT5";
      final endpoint =
          _isWebSocketConnected.value
              ? (isMT5Account
                  ? "${ApiConstants.socketUrl}/ws/mt5/account"
                  : "${ApiConstants.socketUrl}/ws/accounts")
              : "Not connected";

      dev.log(
        '═══════════════════════════════════════════════════════════',
        name: 'DASHBOARD_WS_REQUEST',
      );
      dev.log(
        '📤 WEBSOCKET REQUEST (Dashboard - AccountInfoBottomSheet Data Source)',
        name: 'DASHBOARD_WS_REQUEST',
      );
      dev.log('Endpoint: $endpoint', name: 'DASHBOARD_WS_REQUEST');
      dev.log('Request:', name: 'DASHBOARD_WS_REQUEST');

      print('═══════════════════════════════════════════════════════════');
      print('📤 DASHBOARD_WS_REQUEST - AccountInfoBottomSheet Data Source');
      print('Endpoint: $endpoint');
      print('Request:');

      try {
        final formatted = JsonEncoder.withIndent('  ').convert(event);
        dev.log(formatted, name: 'DASHBOARD_WS_REQUEST');
        print(formatted);
      } catch (e) {
        dev.log('  $event', name: 'DASHBOARD_WS_REQUEST');
        print('  $event');
      }
      dev.log(
        '═══════════════════════════════════════════════════════════',
        name: 'DASHBOARD_WS_REQUEST',
      );
      print('═══════════════════════════════════════════════════════════');
    } catch (e) {
      dev.log(
        'Dashboard WS: Error sending event: $e',
        name: 'DASHBOARD_WS_REQUEST',
      );
      print('❌ DASHBOARD_WS_REQUEST Error: $e');
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
      _currentWebSocketEndpoint = null; // Clear endpoint on disconnect
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

  // Public getter for WebSocket connection status
  bool get isWebSocketConnected => _isWebSocketConnected.value;

  // Ensure WebSocket is initialized (public method for all screens)
  void ensureWebSocketInitialized() {
    if (_isDisposed) return;

    // ✅ FIX: Check if user is authenticated before initializing WebSocket
    // This prevents WebSocket connections when user is logged out
    try {
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) {
        if (kDebugMode) {
          dev.log(
            'Dashboard WS: User not authenticated, skipping WebSocket initialization',
          );
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log(
          'Dashboard WS: AuthController not found, skipping WebSocket: $e',
        );
      }
      return;
    }

    // If accounts are available but WebSocket not connected, initialize it
    if (mt5Accounts.isNotEmpty && !_isWebSocketConnected.value) {
      if (kDebugMode) {
        dev.log(
          'Dashboard WS: Ensuring WebSocket initialization (called from screen)',
        );
      }
      _initializeWebSocket();
    } else if (mt5Accounts.isNotEmpty && _isWebSocketConnected.value) {
      // If already connected, ensure we're subscribed to primary account
      // This handles the case where WebSocket is connected but data not yet received
      final primaryAccount = primaryMT5Account;
      if (primaryAccount != null) {
        final accountNumber = primaryAccount.metaAccountNumber;
        final hasAccountInfo = accountInfoMap.containsKey(accountNumber);
        if (!hasAccountInfo) {
          // Account info not yet received, request it
          if (kDebugMode) {
            dev.log(
              'Dashboard WS: Account info not yet received, requesting data',
            );
          }
          _requestAccountData();
        }
      }
    }
  }

  // Unsubscribe and resubscribe with accounts (keeps socket active)
  Future<void> unsubscribeAndResubscribe() async {
    if (_isDisposed) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Cannot unsubscribeAndResubscribe - disposed');
      }
      return;
    }

    // ✅ FIX: Check if endpoint needs to change based on new primary account
    final primaryAccount = primaryMT5Account;
    final isMT5Account = primaryAccount?.tradingServer == "MT5";
    final expectedEndpoint =
        isMT5Account
            ? '${ApiConstants.socketUrl}/ws/mt5/account'
            : '${ApiConstants.socketUrl}/ws/accounts';

    // If not connected, just initialize normally
    if (!_isWebSocketConnected.value) {
      if (kDebugMode) {
        dev.log(
          'Dashboard WS: Not connected, initializing normally with endpoint: $expectedEndpoint',
        );
      }
      print(
        'Dashboard WS: Not connected, initializing with endpoint: $expectedEndpoint',
      );
      print('  Primary Account: ${primaryAccount?.metaAccountNumber ?? "N/A"}');
      print('  Trading Server: ${primaryAccount?.tradingServer ?? "N/A"}');
      _initializeWebSocket();
      return;
    }

    // ✅ FIX: If endpoint needs to change, do full reconnect instead of just resubscribe
    // Check if we need to switch endpoints (MT5 vs self-hosted)
    final needsEndpointSwitch = _currentWebSocketEndpoint != expectedEndpoint;

    if (needsEndpointSwitch) {
      if (kDebugMode) {
        dev.log('Dashboard WS: Endpoint changed, doing full reconnect');
        dev.log('  Old endpoint: $_currentWebSocketEndpoint');
        dev.log('  New endpoint: $expectedEndpoint');
        dev.log(
          '  Primary Account: ${primaryAccount?.metaAccountNumber ?? "N/A"}',
        );
        dev.log('  Trading Server: ${primaryAccount?.tradingServer ?? "N/A"}');
      }
      print('Dashboard WS: Endpoint changed, doing full reconnect');
      print('  Old endpoint: $_currentWebSocketEndpoint');
      print('  New endpoint: $expectedEndpoint');
      print('  Primary Account: ${primaryAccount?.metaAccountNumber ?? "N/A"}');
      print('  Trading Server: ${primaryAccount?.tradingServer ?? "N/A"}');

      // Disconnect and reconnect with new endpoint
      _disconnectWebSocket();
      await Future.delayed(const Duration(milliseconds: 200));
      _reconnectAttempts = 0; // Reset attempts for fresh start
      _currentWebSocketEndpoint = null; // Clear current endpoint
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
      await Future.delayed(const Duration(milliseconds: 50));
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
    await Future.delayed(const Duration(milliseconds: 50));

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

  // Clear all data and reset state (called on logout)
  void clearAllData() {
    print('DashboardController: Clearing all data...');
    _disconnectWebSocket();
    accounts.clear();
    mt5Accounts.clear();
    _accountInfoMap.clear();
    accountInfoMap.clear();
    hasMT5Accounts.value = false;
    errorMessage.value = '';
    _lastFetchAt = null;
    _lastReconnectAt = null;
    _currentWebSocketEndpoint = null;
    _refreshToken = 0;
    _isFetching = false;
    print('DashboardController: All data cleared');
  }
}
