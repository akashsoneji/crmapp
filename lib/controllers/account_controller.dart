import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pipze/models/account_models.dart';
import 'package:pipze/models/mt5_account.dart';
import 'package:pipze/controllers/dashboard_controller.dart';
import 'package:pipze/controllers/instruments_controller.dart';
import 'package:pipze/controllers/chart_socket_controller.dart';
import 'package:pipze/controllers/trading_controller.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/services/websocket_endpoint_helper.dart';
import '../services/account_service.dart';
import '../services/trading_websocket_service.dart';
import '../services/account_websocket_service.dart';

class AccountController extends GetxController {
  final AccountService _accountService = Get.find<AccountService>();
  late final DashboardController _dashboardController;

  // Observable states
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _accounts = <AccountModel>[].obs;
  final _activeAccount = Rxn<AccountModel>();
  final _successMessage = ''.obs;

  // MT5 Account integration
  final _mt5Accounts = <MT5Account>[].obs;
  final _activeMT5Account = Rxn<MT5Account>();
  final _isInitialized = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  List<AccountModel> get accounts => _accounts;
  AccountModel? get activeAccount => _activeAccount.value;
  String get successMessage => _successMessage.value;

  // MT5 Account getters
  List<MT5Account> get mt5Accounts => _mt5Accounts;
  MT5Account? get activeMT5Account => _activeMT5Account.value;
  Rxn<MT5Account> get activeMT5AccountRx =>
      _activeMT5Account; // Expose observable for listeners
  bool get isInitialized => _isInitialized.value;
  List<MT5Account> get realMT5Accounts =>
      _mt5Accounts.where((account) => account.isRealAccount).toList();
  List<MT5Account> get demoMT5Accounts =>
      _mt5Accounts.where((account) => account.isDemoAccount).toList();

  // Wait for AccountController to be ready before proceeding
  Future<void> waitForInitialization() async {
    if (_isInitialized.value) return;

    // Wait for initialization to complete
    await _isInitialized.stream.firstWhere((initialized) => initialized);

    // Small additional delay to ensure MT5 accounts are synced
    await Future.delayed(const Duration(milliseconds: 100));
  }

  MT5Account? get primaryMT5Account {
    try {
      return _mt5Accounts.firstWhere((account) => account.isPrimaryAccount);
    } catch (e) {
      return _mt5Accounts.isNotEmpty ? _mt5Accounts.first : null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    loadAccounts();
  }

  void _initializeControllers() {
    try {
      // Try to get existing DashboardController first
      _dashboardController = Get.find<DashboardController>();
    } catch (e) {
      // If not found, create a new one
      _dashboardController = Get.put(DashboardController());
    }

    // Wait a bit for DashboardController to initialize, then sync
    Future.delayed(Duration(milliseconds: 500), () {
      _syncWithMT5Accounts();
    });
  }

  Future<void> loadAccounts() async {
    try {
      _setLoading(true);
      _clearError();

      final accounts = await _accountService.getAccounts();
      final activeAccount = await _accountService.getActiveAccount();

      _accounts.value = accounts;
      _activeAccount.value = activeAccount;

      // Mark as initialized after loading accounts
      _isInitialized.value = true;
      print('AccountController: Accounts loaded, marked as initialized');
    } catch (e) {
      _setError('Failed to load accounts: $e');
      _isInitialized.value = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setActiveAccount(String accountId) async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.setActiveAccount(accountId);

      // Reload accounts to get updated data
      await loadAccounts();

      _setSuccess('Account switched successfully');
    } catch (e) {
      _setError('Failed to set active account: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAccount(AccountModel account) async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.addAccount(account);
      await loadAccounts();

      _setSuccess('Account added successfully');
    } catch (e) {
      _setError('Failed to add account: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAccount(AccountModel account) async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.updateAccount(account);
      await loadAccounts();

      _setSuccess('Account updated successfully');
    } catch (e) {
      _setError('Failed to update account: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.deleteAccount(accountId);
      await loadAccounts();

      _setSuccess('Account deleted successfully');
    } catch (e) {
      _setError('Failed to delete account: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.updateAccountBalance(accountId, newBalance);
      await loadAccounts();

      _setSuccess('Account balance updated successfully');
    } catch (e) {
      _setError('Failed to update account balance: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshAccounts() async {
    await loadAccounts();
  }

  Future<void> resetToDefaultAccounts() async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.resetToDefaultAccounts();
      await loadAccounts();

      // _setSuccess('Accounts reset to default');
    } catch (e) {
      _setError('Failed to reset accounts: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String error) {
    _errorMessage.value = error;
    if (error.isNotEmpty) {
      Get.snackbar('Error', error, snackPosition: SnackPosition.TOP);
    }
  }

  void _setSuccess(String message) {
    _successMessage.value = message;
    if (message.isNotEmpty) {
      // Get.snackbar('Success', message, snackPosition: SnackPosition.TOP);
      CustomToastService.showSuccess(
        message: message,
        duration: const Duration(seconds: 1),
      );
    }
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void clearMessages() {
    _errorMessage.value = '';
    _successMessage.value = '';
  }

  // MT5 Account Integration Methods

  // Sync with MT5 accounts from dashboard controller
  void _syncWithMT5Accounts() {
    try {
      // Listen to MT5 accounts changes from dashboard controller
      ever(_dashboardController.mt5Accounts, (List<MT5Account> mt5Accounts) {
        print('AccountController: MT5 accounts changed, syncing...');
        _mt5Accounts.assignAll(mt5Accounts);
        _updateActiveMT5Account();
      });

      // Initial sync
      if (_dashboardController.mt5Accounts.isNotEmpty) {
        print(
          'AccountController: Initial sync with ${_dashboardController.mt5Accounts.length} MT5 accounts',
        );
        _mt5Accounts.assignAll(_dashboardController.mt5Accounts);
        _updateActiveMT5Account();

        // ✅ FIX: Update WebSocketEndpointHelper with primary account
        final primaryAccount = primaryMT5Account;
        if (primaryAccount != null) {
          WebSocketEndpointHelper.setPrimaryAccount(primaryAccount);
          print(
            'AccountController: Updated WebSocketEndpointHelper with primary account: ${primaryAccount.metaAccountNumber}',
          );
        }
      } else {
        print('AccountController: No MT5 accounts available for initial sync');
        // Retry after a delay
        Future.delayed(Duration(seconds: 2), () {
          if (_dashboardController.mt5Accounts.isNotEmpty) {
            print(
              'AccountController: Retry sync with ${_dashboardController.mt5Accounts.length} MT5 accounts',
            );
            _mt5Accounts.assignAll(_dashboardController.mt5Accounts);
            _updateActiveMT5Account();
          }
        });
      }
    } catch (e) {
      print('AccountController: Error syncing with MT5 accounts: $e');
    }
  }

  // Force refresh account data
  Future<void> forceRefreshAccountData() async {
    print('AccountController: Force refreshing account data...');
    try {
      // Reload accounts
      await loadAccounts();

      // Force sync with MT5 accounts
      _syncWithMT5Accounts();

      // Debug the current state
      debugAccountData();
    } catch (e) {
      print('AccountController: Error force refreshing account data: $e');
    }
  }

  // Debug method to check account data
  void debugAccountData() {
    print('=== AccountController Debug Info ===');
    print('MT5 Accounts count: ${_mt5Accounts.length}');
    print('Active MT5 Account: ${_activeMT5Account.value?.metaAccountNumber}');
    print('Active MT5 Account Type: ${_activeMT5Account.value?.accountType}');
    print('Active MT5 Account Balance: ${_activeMT5Account.value?.balance}');

    for (int i = 0; i < _mt5Accounts.length; i++) {
      final account = _mt5Accounts[i];
      print(
        'Account $i: ${account.metaAccountNumber} - ${account.accountType} - Balance: ${account.balance}',
      );
    }
    print('=====================================');
  }

  // Method to update MT5 accounts (called by dashboard controller)
  void updateMT5Accounts(List<MT5Account> mt5Accounts) {
    print(
      'AccountController: Updating MT5 accounts: ${mt5Accounts.length} accounts',
    );
    for (var account in mt5Accounts) {
      print(
        'AccountController: Account ${account.metaAccountNumber} - ${account.accountType} - Primary: ${account.isPrimaryAccount}',
      );
    }
    _mt5Accounts.assignAll(mt5Accounts);
    _updateActiveMT5Account();

    // ✅ FIX: Update WebSocketEndpointHelper with primary account
    final primaryAccount = primaryMT5Account;
    if (primaryAccount != null) {
      WebSocketEndpointHelper.setPrimaryAccount(primaryAccount);
      print(
        'AccountController: Updated WebSocketEndpointHelper with primary account: ${primaryAccount.metaAccountNumber}',
      );
    }

    print(
      'AccountController: Updated _mt5Accounts with ${_mt5Accounts.length} accounts',
    );
    print(
      'AccountController: Active MT5 account: ${_activeMT5Account.value?.metaAccountNumber}',
    );

    // Debug account data
    debugAccountData();
  }

  // Update active MT5 account based on primary account
  void _updateActiveMT5Account() {
    print(
      'AccountController: _updateActiveMT5Account called with ${_mt5Accounts.length} accounts',
    );
    final primaryAccount = primaryMT5Account;
    print(
      'AccountController: Primary account found: ${primaryAccount?.metaAccountNumber}',
    );

    if (primaryAccount != null) {
      _activeMT5Account.value = primaryAccount;
      print(
        'AccountController: Set active account to primary: ${primaryAccount.metaAccountNumber}',
      );
    } else if (_mt5Accounts.isNotEmpty) {
      _activeMT5Account.value = _mt5Accounts.first;
      print(
        'AccountController: Set active account to first: ${_mt5Accounts.first.metaAccountNumber}',
      );
    } else {
      _activeMT5Account.value = null;
      print('AccountController: No accounts available, set active to null');
    }
  }

  // Set active MT5 account (this will call dashboard controller's changePrimaryAccount)
  Future<void> setActiveMT5Account(String accountNumber) async {
    try {
      _setLoading(true);
      _clearError();

      // Get the new account details
      final account = _mt5Accounts.firstWhereOrNull(
        (acc) => acc.metaAccountNumber == accountNumber,
      );

      if (account == null) {
        _setError('Account not found');
        return;
      }

      final previousAccount = _activeMT5Account.value;
      final previousAccountType = WebSocketEndpointHelper.getAccountType(
        previousAccount,
      );
      final previousEndpoints = _snapshotWebSocketEndpoints(previousAccount);
      final nextEndpoints = _snapshotWebSocketEndpoints(account);

      // Start switch trace timer
      WebSocketEndpointHelper.beginSwitchTrace(account.metaAccountNumber);

      // Debug: list all socket connections and their URL changes
      print(
        '🔄 ACCOUNT SWITCH: ${previousAccount?.metaAccountNumber ?? "none"} ($previousAccountType) '
        '→ ${account.metaAccountNumber} (${WebSocketEndpointHelper.getAccountType(account)})',
      );
      _logEndpointChanges(previousEndpoints, nextEndpoints);

      // ✅ OPTIMIZATION: Detect account type change early (before API call)
      final currentAccount = _activeMT5Account.value;
      final currentIsMT5 = currentAccount?.tradingServer.toUpperCase() == "MT5";
      final newIsMT5 = account.tradingServer.toUpperCase() == "MT5";
      final accountTypeChanged = currentIsMT5 != newIsMT5;
      // Kick off background disconnect for screen-level sockets while API executes
      final screenDisconnect = _disconnectScreenSockets();

      // Set flag to prevent flickering during account switch
      try {
        if (Get.isRegistered<TradingController>()) {
          final tradingController = Get.find<TradingController>();
          tradingController.setAccountSwitching(true);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error setting account switching flag: $e');
        }
      }

      // ✅ OPTIMIZATION: Optimistic UI update for faster response
      _activeMT5Account.value = account;

      // ✅ OPTIMIZATION: If account type changed (MT5 ↔ self-hosted), disconnect first,
      // then reconnect only after the backend confirms the switch. This prevents reconnecting
      // to the old endpoint and ensures market/watch & accounts data refresh correctly.
      Future<void>? disconnectTask;
      if (accountTypeChanged) {
        print(
          '🔄 ACCOUNT SWITCH: Account type changed (${currentIsMT5 ? "MT5" : "Self-hosted"} → ${newIsMT5 ? "MT5" : "Self-hosted"}), disconnecting websockets before API update',
        );

        disconnectTask = Future.wait([
          // Close Instruments WebSocket
          Future(() async {
            try {
              if (Get.isRegistered<InstrumentsController>()) {
                final instrumentsController = Get.find<InstrumentsController>();
                instrumentsController.stopWebSocket();
                if (kDebugMode) {
                  print('🔌 Closed Instruments WebSocket');
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error closing Instruments WebSocket: $e');
              }
            }
          }),

          // Close Chart WebSocket
          Future(() async {
            try {
              if (Get.isRegistered<ChartSocketController>()) {
                final chartSocketController = Get.find<ChartSocketController>();
                chartSocketController.stopWebSocket();
                if (kDebugMode) {
                  print('🔌 Closed Chart WebSocket');
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error closing Chart WebSocket: $e');
              }
            }
          }),
        ]);
      }

      // Call dashboard controller's method to change primary account
      await _dashboardController.changePrimaryAccount(accountNumber);

      // ✅ FIX: Clear endpoint helper cache to ensure fresh account data
      WebSocketEndpointHelper.clearCache();
      // Set the new primary account for endpoint helper to avoid stale URLs
      WebSocketEndpointHelper.setPrimaryAccount(account);

      // Clear cached websocket/JSON data before reconnecting
      try {
        if (Get.isRegistered<TradingController>()) {
          final tradingController = Get.find<TradingController>();
          tradingController.clearAllTradingData();
        }
      } catch (_) {}
      try {
        // Clear dashboard cached account info so next stream is fresh
        _dashboardController.accountInfoMap.clear();
      } catch (_) {}

      // Ensure disconnects complete before reconnecting with the new endpoints
      if (disconnectTask != null) {
        await disconnectTask;
      }
      await screenDisconnect;

      // ✅ FIX: Add small delay to allow backend to fully process account switch
      // Backend needs time to update internal state before websockets can receive data
      // This prevents websockets from connecting before backend is ready
      if (accountTypeChanged) {
        print(
          '🔄 ACCOUNT SWITCH: Waiting for backend to process account switch...',
        );
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Reconnect all websockets after API so URLs and subscriptions are fresh
      await _reconnectAllSockets(accountNumber, account);

      // Clear account switching flag after a shorter delay for faster updates
      // Flag will also be cleared when real data arrives in _updateMarketPositions
      try {
        if (Get.isRegistered<TradingController>()) {
          final tradingController = Get.find<TradingController>();
          Future.delayed(const Duration(milliseconds: 400), () {
            tradingController.setAccountSwitching(false);
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error clearing account switching flag: $e');
        }
      }

      print(
        '✅ ACCOUNT SWITCH: All operations completed for account: $accountNumber',
      );
      _setSuccess('Account switched successfully');
    } catch (e) {
      _setError('Failed to switch account: $e');
    } finally {
      _setLoading(false);

      // Ensure any open loading dialogs are closed
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // End switch trace
      WebSocketEndpointHelper.endSwitchTrace();
    }
  }

  Map<String, String> _snapshotWebSocketEndpoints(MT5Account? account) {
    return {
      'trading_open_positions': WebSocketEndpointHelper.getOpenPositionsUrl(
        account,
      ),
      'trading_pending_orders': WebSocketEndpointHelper.getPendingOrdersUrl(
        account,
      ),
      'trading_market_watch': WebSocketEndpointHelper.getMarketWatchUrl(
        account,
      ),
      'trading_symbol': WebSocketEndpointHelper.getSymbolUrl(account),
      'account': WebSocketEndpointHelper.getAccountUrl(account),
    };
  }

  void _logEndpointChanges(
    Map<String, String> oldEndpoints,
    Map<String, String> newEndpoints,
  ) {
    print('🔗 WebSocket endpoint updates:');
    oldEndpoints.forEach((key, oldUrl) {
      final newUrl = newEndpoints[key] ?? '';
      print(' - $key: $oldUrl -> $newUrl');
    });
  }

  Future<void> _disconnectScreenSockets() async {
    await Future.wait([
      Future(() async {
        try {
          if (Get.isRegistered<InstrumentsController>()) {
            final c = Get.find<InstrumentsController>();
            WebSocketEndpointHelper.logSwitchStep('Instruments stop');
            c.stopWebSocket();
          }
        } catch (_) {}
      }),
      Future(() async {
        try {
          if (Get.isRegistered<ChartSocketController>()) {
            final c = Get.find<ChartSocketController>();
            WebSocketEndpointHelper.logSwitchStep('Chart stop');
            c.stopWebSocket();
          }
        } catch (_) {}
      }),
    ]);
  }

  Future<void> _reconnectAllSockets(
    String accountNumber,
    MT5Account account,
  ) async {
    // Ensure active is set before reconnects
    _activeMT5Account.value = account;

    // ✅ FIX: First unsubscribe from all connected sockets and clear data
    await Future.wait([
      // Trading WS - Unsubscribe if connected
      Future(() async {
        try {
          if (Get.isRegistered<TradingWebSocketService>()) {
            final tradingWS = Get.find<TradingWebSocketService>();
            if (tradingWS.isConnected.value) {
              WebSocketEndpointHelper.logSwitchStep(
                'Trading unsubscribe start',
              );
              await tradingWS.unsubscribeAndResubscribe();
              WebSocketEndpointHelper.logSwitchStep('Trading unsubscribe done');
            } else {
              // Not connected, just reconnect
              WebSocketEndpointHelper.logSwitchStep('Trading reconnect start');
              await tradingWS.disconnectAndReconnect();
              WebSocketEndpointHelper.logSwitchStep('Trading reconnect done');
            }
          }
        } catch (_) {}
      }),
      // Account WS - Unsubscribe if connected
      Future(() async {
        try {
          if (Get.isRegistered<AccountWebSocketService>()) {
            final accountWS = Get.find<AccountWebSocketService>();
            if (accountWS.isConnected.value) {
              WebSocketEndpointHelper.logSwitchStep(
                'Account unsubscribe start',
              );
              await accountWS.unsubscribeAndResubscribe();
              WebSocketEndpointHelper.logSwitchStep('Account unsubscribe done');
            } else {
              // Not connected, just reconnect
              WebSocketEndpointHelper.logSwitchStep('Account reconnect start');
              await accountWS.disconnectAndReconnect();
              WebSocketEndpointHelper.logSwitchStep('Account reconnect done');
            }
          }
        } catch (_) {}
      }),
      // Instruments WS - Unsubscribe if connected
      Future(() async {
        try {
          if (Get.isRegistered<InstrumentsController>()) {
            final instrumentsController = Get.find<InstrumentsController>();
            if (instrumentsController.isConnected.value) {
              WebSocketEndpointHelper.logSwitchStep(
                'Instruments unsubscribe start',
              );
              // Clear data before unsubscribe
              instrumentsController.clearInstrumentsData();
              await instrumentsController.unsubscribeAndResubscribe(
                accountNumber,
              );
              WebSocketEndpointHelper.logSwitchStep(
                'Instruments unsubscribe done',
              );
            } else {
              // Not connected, just reconnect
              WebSocketEndpointHelper.logSwitchStep(
                'Instruments reconnect start',
              );
              instrumentsController.stopWebSocket();
              await Future.delayed(const Duration(milliseconds: 120));
              instrumentsController.clearInstrumentsData();
              instrumentsController.startWebSocket();
              WebSocketEndpointHelper.logSwitchStep(
                'Instruments reconnect done',
              );
            }
          }
        } catch (_) {}
      }),
      // Chart WS - Unsubscribe if connected
      Future(() async {
        try {
          if (Get.isRegistered<ChartSocketController>()) {
            final chartSocketController = Get.find<ChartSocketController>();
            final currentSymbol = chartSocketController.currentSymbol.value;
            if (chartSocketController.isConnected.value &&
                currentSymbol.isNotEmpty) {
              WebSocketEndpointHelper.logSwitchStep('Chart unsubscribe start');
              await chartSocketController.unsubscribeAndResubscribe(
                accountNumber,
                currentSymbol,
              );
              WebSocketEndpointHelper.logSwitchStep('Chart unsubscribe done');
            } else {
              // Not connected, just reconnect
              WebSocketEndpointHelper.logSwitchStep('Chart reconnect start');
              chartSocketController.stopWebSocket();
              if (currentSymbol.isNotEmpty) {
                await Future.delayed(const Duration(milliseconds: 150));
                chartSocketController.initializeSocketForSymbol(currentSymbol);
              }
              WebSocketEndpointHelper.logSwitchStep('Chart reconnect done');
            }
          }
        } catch (_) {}
      }),
      // Dashboard WS - Unsubscribe if connected
      Future(() async {
        try {
          if (Get.isRegistered<DashboardController>()) {
            final dashboardController = Get.find<DashboardController>();
            // unsubscribeAndResubscribe handles both connected and disconnected cases
            WebSocketEndpointHelper.logSwitchStep(
              'Dashboard unsubscribe start',
            );
            await dashboardController.unsubscribeAndResubscribe();
            WebSocketEndpointHelper.logSwitchStep('Dashboard unsubscribe done');
          }
        } catch (_) {}
      }),
    ]);
  }

  // Convert MT5 account to AccountModel for compatibility
  AccountModel? convertMT5ToAccountModel(MT5Account mt5Account) {
    try {
      return AccountModel(
        id: mt5Account.metaAccountNumber,
        type: mt5Account.isRealAccount ? 'REAL' : 'DEMO',
        balance: double.tryParse(mt5Account.balance) ?? 0.0,
        currency: 'USD', // Default currency
        isActive: mt5Account.isPrimaryAccount,
        createdAt: DateTime.now(), // You might want to get this from API
        metadata: {
          'mt5_account': true,
          'account_type': mt5Account.accountType,
          'master_group_id': mt5Account.masterGroupId,
          'leverage_id': mt5Account.leverageId,
          'equity': mt5Account.equity,
          'margin': mt5Account.margin,
          'free_margin': mt5Account.freeMargin,
          'profit': mt5Account.profit,
        },
      );
    } catch (e) {
      print('Error converting MT5 account to AccountModel: $e');
      return null;
    }
  }

  // Get all accounts (both local and MT5) as AccountModel list
  List<AccountModel> getAllAccountsAsModels() {
    final List<AccountModel> allAccounts = List.from(_accounts);

    // Add MT5 accounts as AccountModel
    for (final mt5Account in _mt5Accounts) {
      final accountModel = convertMT5ToAccountModel(mt5Account);
      if (accountModel != null) {
        allAccounts.add(accountModel);
      }
    }

    return allAccounts;
  }

  // Refresh both local accounts and MT5 accounts
  Future<void> refreshAllAccounts() async {
    await loadAccounts();
    await _dashboardController.refreshMT5Accounts();
  }

  // Force refresh MT5 accounts
  Future<void> forceRefreshMT5Accounts() async {
    print('AccountController: Force refreshing MT5 accounts...');
    await _dashboardController.forceCheckMT5Accounts();
  }

  // Test method to create a demo MT5 account
  // Future<void> testCreateMT5Account() async {
  //   print('🧪 Testing MT5 account creation...');

  //   final success = await createMT5Account(
  //     groupId: 1,
  //     mainPassword: 'test123',
  //     investorPassword: 'investor123',
  //     accountType: 'demo',
  //   );

  //   if (success) {
  //     print('✅ Test MT5 account created successfully!');
  //     print('📊 Total MT5 accounts: ${mt5Accounts.length}');
  //     for (var account in mt5Accounts) {
  //       print('   - ${account.metaAccountNumber} (${account.accountType})');
  //     }
  //   } else {
  //     print('❌ Test MT5 account creation failed: $errorMessage');
  //   }
  // }

  // Create new MT5 account
  Future<Map<String, dynamic>?> createMT5Account({
    int? groupId,
    required String mainPassword,
    required String investorPassword,
    String? leverage,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('AccountController: Creating MT5 account...');
      print('Group ID: $groupId');

      final success;
      if (groupId != null) {
        success = await _dashboardController.createMT5Account(
          groupId: groupId,
          mainPassword: mainPassword,
          investorPassword: investorPassword,
          leverage: leverage,
        );
      } else {
        success = await _dashboardController.createMT5Account(
          mainPassword: mainPassword,
          investorPassword: investorPassword,
          leverage: leverage,
        );
      }

      if (success != null) {
        _successMessage.value = 'MT5 account created successfully';
        print('AccountController: MT5 account created successfully');
        // Refresh all accounts to get the latest data
        await refreshAllAccounts();
        return success; // Return the account data
      } else {
        _errorMessage.value =
            success.message ??
            'Something went wrong'; //'Failed to create MT5 account';
        print('AccountController: Failed to create MT5 account');
        return null;
      }
    } catch (e) {
      _errorMessage.value = 'Something went wrong';
      print('AccountController: Error creating MT5 account: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
}
