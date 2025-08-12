import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/home/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    // Get.to(() => CreateOpenAccountScreen(accountType: 'Real'));
  }

  void openDemoAccount() {
    Get.back(); // Close bottom sheet
    // Get.to(() => CreateOpenAccountScreen(accountType: 'Demo'));
  }

  void onDeposit(String accountNumber) {
    Get.snackbar(
      'Deposit',
      'Deposit for account $accountNumber',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onWithdraw(String accountNumber) {
    Get.snackbar(
      'Withdraw',
      'Withdraw for account $accountNumber',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onSettings(String accountNumber) {
    Get.snackbar(
      'Settings',
      'Settings for account $accountNumber',
      snackPosition: SnackPosition.BOTTOM,
    );
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