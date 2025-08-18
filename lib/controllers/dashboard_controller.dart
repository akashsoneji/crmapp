import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/screens/home/create_trading_account_screen.dart';
import 'package:pipze/screens/home/choose_account_screen.dart';

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
  var isBottomSheetOpen = false.obs;
  Function(int)? onNavigateToTab;

  void setNavigationCallback(Function(int) callback) {
    onNavigateToTab = callback;
  }

  @override
  void onInit() {
    super.onInit();
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
    Get.to(() => CreateTradingAccountScreen(accountType: 'Demo'));

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
    Get.snackbar(
      'Switch to Trade',
      'Switching to trade for account $accountNumber',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFF7B2CBF),
      colorText: Colors.white,
    );
  }
}
