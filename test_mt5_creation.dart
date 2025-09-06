// Test file for MT5 account creation
// This file demonstrates how to use the MT5 account creation functionality

import 'package:get/get.dart';
import 'lib/controllers/account_controller.dart';

/// Test method to create a demo MT5 account
/// Call this method to test the MT5 account creation functionality
Future<void> testMT5AccountCreation() async {
  print('🧪 Starting MT5 Account Creation Test...');

  try {
    // Get the account controller
    final accountController = Get.find<AccountController>();

    print(
      '📋 Current MT5 accounts before creation: ${accountController.mt5Accounts.length}',
    );

    // Create a demo MT5 account
    final success = await accountController.createMT5Account(
      groupId: 1, // Demo account group
      mainPassword: 'test123', // Main trading password
      investorPassword: 'investor123', // Investor password
      accountType: 'demo', // Account type: "demo" or "real"
    );

    if (success) {
      print('✅ MT5 account created successfully!');
      print(
        '📊 Total MT5 accounts after creation: ${accountController.mt5Accounts.length}',
      );

      // List all MT5 accounts
      for (var account in accountController.mt5Accounts) {
        print('   - Account: ${account.metaAccountNumber}');
        print('     Type: ${account.accountType}');
        print('     Balance: ${account.balance}');
        print('     Primary: ${account.isPrimaryAccount}');
        print('     ---');
      }
    } else {
      print('❌ MT5 account creation failed!');
      print('Error: ${accountController.errorMessage}');
    }
  } catch (e) {
    print('💥 Error during test: $e');
  }

  print('🏁 MT5 Account Creation Test completed');
}

/// Test method to create a real MT5 account
Future<void> testRealMT5AccountCreation() async {
  print('🧪 Starting Real MT5 Account Creation Test...');

  try {
    final accountController = Get.find<AccountController>();

    final success = await accountController.createMT5Account(
      groupId: 2, // Real account group
      mainPassword: 'real123', // Main trading password
      investorPassword: 'investor123', // Investor password
      accountType: 'real', // Account type: "real"
    );

    if (success) {
      print('✅ Real MT5 account created successfully!');
    } else {
      print('❌ Real MT5 account creation failed!');
      print('Error: ${accountController.errorMessage}');
    }
  } catch (e) {
    print('💥 Error during real account test: $e');
  }
}

/// Example usage in a Flutter widget
/// Add this to any screen's onPressed method to test
void onTestButtonPressed() {
  testMT5AccountCreation();
}
