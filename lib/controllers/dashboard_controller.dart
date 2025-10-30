import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';

import 'package:pipze/models/mt5_account.dart';
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
import '../services/trading_websocket_service.dart';

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

  void setNavigationCallback(Function(int) callback) {
    onNavigateToTab = callback;
  }

  @override
  void onInit() {
    super.onInit();

    checkMT5Accounts();
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
      print('DashboardController: Starting checkMT5Accounts...');
      isLoadingMT5Accounts.value = true;
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
          print('MT5 accounts API error: ${data['message']}');
          // _redirectToAccountOpening();
        }
      } else {
        // API call failed
        hasMT5Accounts.value = false;
        mt5Accounts.clear();
        print('Failed to fetch MT5 accounts: ${response.message}');
        // _redirectToAccountOpening();
      }
    } catch (e, t) {
      hasMT5Accounts.value = false;
      mt5Accounts.clear();
      print('Exception in checkMT5Accounts: $e');
      print('Exception in checkMT5Accounts: $t');
      // _redirectToAccountOpening();
    } finally {
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
        print('Failed to fetch MT5 accounts: ${response.message}');
        CustomToastService.showError(message: response.message!);
        // _redirectToAccountOpening();
      }
    } catch (e) {
      hasMT5Accounts.value = false;
      isLoadingMT5Accounts.value = false;
      print('Exception in changePrimaryAccount: $e');
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
    print(accountNumber);
    // Get.to(() => DepositRealScreen(accountNumber: accountNumber));
    await Get.to(() => PaymentMethodsScreen(accountNumber: accountNumber));
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

  // Refresh MT5 accounts data
  Future<void> refreshMT5Accounts() async {
    await checkMT5Accounts();
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
        errorMessage.value = response.message ?? 'Failed to create MT5 account';
        print(
          'DashboardController: Failed to create MT5 account: ${response.message}',
        );
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error creating MT5 account: $e';
      print('DashboardController: Error creating MT5 account: $e');
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
}
