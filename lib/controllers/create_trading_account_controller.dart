import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../widgets/congratulations_dialog.dart';

class CreateTradingAccountController extends GetxController {
  var selectedAccountType = 'Pipze Demo'.obs;
  var depositAmount = '500.00'.obs;
  var tradingPassword = ''.obs;
  var investorPassword = ''.obs;
  var isLoading = false.obs;
  var showTradingPassword = false.obs;
  var showInvestorPassword = false.obs;
  var accountType = 'Demo'.obs; // 'Real' or 'Demo'

  final depositAmountController = TextEditingController();
  final tradingPasswordController = TextEditingController();
  final investorPasswordController = TextEditingController();

  // Account type options for dropdown
  final List<String> accountOptions = [
    'Pipze Demo',
    'MT5 Demo',
    'Pipze Real',
    'MT5 Real',
  ];

  @override
  void onInit() {
    super.onInit();
    // Set default values
    depositAmountController.text = '500.00';
    tradingPasswordController.text = 'xxxxxxxxx';
    investorPasswordController.text = 'xxxxxxxxx';
  }

  void setAccountType(String type) {
    accountType.value = type;
    // Update default account selection based on type
    if (type == 'Real') {
      selectedAccountType.value = 'Pipze Real';
    } else {
      selectedAccountType.value = 'Pipze Demo';
    }
  }

  void selectAccountType(String account) {
    selectedAccountType.value = account;
    // Update account type based on selection
    if (account.contains('Demo')) {
      accountType.value = 'Demo';
    } else {
      accountType.value = 'Real';
    }
  }

  void toggleTradingPasswordVisibility() {
    showTradingPassword.value = !showTradingPassword.value;
  }

  void toggleInvestorPasswordVisibility() {
    showInvestorPassword.value = !showInvestorPassword.value;
  }

  void updateDepositAmount(String value) {
    depositAmount.value = value;
  }

  void updateTradingPassword(String value) {
    tradingPassword.value = value;
  }

  void updateInvestorPassword(String value) {
    investorPassword.value = value;
  }

  Future<void> createAccount() async {
    // Basic validation
    if (depositAmount.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter deposit amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (tradingPassword.value.isEmpty || tradingPassword.value == 'xxxxxxxxx') {
      Get.snackbar(
        'Error',
        'Please enter trading password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (investorPassword.value.isEmpty ||
        investorPassword.value == 'xxxxxxxxx') {
      Get.snackbar(
        'Error',
        'Please enter investor password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      // Show congratulations popup
      Get.dialog(
        CongratulationsDialog(
          accountNumber: '123456789',
          serverName: 'Meta-Right',
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create account. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    depositAmountController.dispose();
    tradingPasswordController.dispose();
    investorPasswordController.dispose();
    super.onClose();
  }
}
