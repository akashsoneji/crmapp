import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';

import 'package:pipze/models/mt5_account.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/screens/home/create_pipze_account_screen.dart';
import 'package:pipze/controllers/account_controller.dart';

import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/widgets/custom_toast.dart';

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
  Function(int)? onNavigateToTab;

  void setNavigationCallback(Function(int) callback) {
    onNavigateToTab = callback;
  }

  @override
  void onInit() {
    super.onInit();

    checkMT5Accounts();
    loadAccounts();
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
      isLoadingMT5Accounts.value = true;
      final token = await SecureStorageService.getAuthToken();

      if (token == null || token.isEmpty) {
        print('DashboardController: No auth token found');
        return;
      }

      final response = await ApiService.get(
        endpoint: ApiConstants.getMT5Accounts,
        token: token,
      );

      if (response.success) {
        final data = response.data;
        print('MT5 Accounts Response: $data');

        if (data['status'] == true && data['data'] != null) {
          final accountsData = data['data'] as List;

          if (accountsData.isNotEmpty) {
            // User has MT5 accounts
            mt5Accounts.assignAll(
              accountsData
                  .map((account) => MT5Account.fromJson(account))
                  .toList(),
            );
            hasMT5Accounts.value = true;
            print('User has ${mt5Accounts.length} MT5 accounts');

            // Notify account controller if it exists
            _notifyAccountController();
          } else {
            // User has no MT5 accounts - redirect to account opening
            hasMT5Accounts.value = false;
            print('User has no MT5 accounts - redirecting to account opening');
            _redirectToAccountOpening();
          }
        } else {
          // API returned error or no data
          hasMT5Accounts.value = false;
          print('MT5 accounts API error: ${data['message']}');
          _redirectToAccountOpening();
        }
      } else {
        // API call failed
        hasMT5Accounts.value = false;
        print('Failed to fetch MT5 accounts: ${response.message}');
        _redirectToAccountOpening();
      }
    } catch (e) {
      hasMT5Accounts.value = false;
      print('Exception in checkMT5Accounts: $e');
      _redirectToAccountOpening();
    } finally {
      isLoadingMT5Accounts.value = false;
    }
  }

  // Redirect to account opening screen
  Future<void> changePrimaryAccount(String accountNumber) async {
    try {
      isLoadingMT5Accounts.value = true;
      final token = await SecureStorageService.getAuthToken();

      if (token == null || token.isEmpty) {
        print('DashboardController: No auth token found');
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

        CustomToastService.showSuccess(
          message: data['message'],
          title: 'Primary account changed successfully',
        );
        checkMT5Accounts();
      } else {
        // API call failed
        hasMT5Accounts.value = false;
        print('Failed to fetch MT5 accounts: ${response.message}');
        _redirectToAccountOpening();
      }
    } catch (e) {
      hasMT5Accounts.value = false;
      print('Exception in checkMT5Accounts: $e');
      _redirectToAccountOpening();
    } finally {
      isLoadingMT5Accounts.value = false;
    }
  }

  void _redirectToAccountOpening() {
    // Show a message to the user
    CustomToastService.showInfo(
      message: 'You need to open a trading account to continue',
      title: 'Account Required',
    );

    // Navigate to account opening after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      showOpenAccountSheet();
    });
  }

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

  void onDeposit(String accountNumber) {
    Get.toNamed(AppPages.DEPOSIT);
    // Get.snackbar(
    //   'Deposit',
    //   'Deposit for account $accountNumber',
    //   snackPosition: SnackPosition.BOTTOM,
    // );
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
        Get.find<AccountController>();
        // The account controller will automatically sync via the ever() listener
        print('Notified AccountController about MT5 account changes');
      }
    } catch (e) {
      print('AccountController not found or error notifying: $e');
    }
  }
}
