import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WalletController extends GetxController {
  var walletId = 'PIPW008'.obs;
  var balance = 100.00.obs;
  var transferFromAccount = ''.obs;
  var transferToAccount = ''.obs;
  var amount = ''.obs;
  var isLoading = false.obs;
  var showTransferFromDropdown = false.obs;

  final transferFromController = TextEditingController();
  final transferToController = TextEditingController();
  final amountController = TextEditingController();

  // Sample account options for dropdown
  final List<String> accountOptions = [
    'MT5 Account Number',
    'MT4 Account Number',
    'Demo Account',
    'Live Account 001',
    'Live Account 002'
  ];

  @override
  void onInit() {
    super.onInit();
    // Set default values
    transferFromAccount.value = accountOptions[0];
    transferFromController.text = accountOptions[0];
    transferToController.text = accountOptions[0];
    amountController.text = '\$500.00';
    amount.value = '\$500.00';
  }

  void selectTransferFromAccount(String account) {
    transferFromAccount.value = account;
    transferFromController.text = account;
    showTransferFromDropdown.value = false;
  }

  void toggleTransferFromDropdown() {
    showTransferFromDropdown.value = !showTransferFromDropdown.value;
  }

  void updateTransferToAccount(String value) {
    transferToAccount.value = value;
  }

  void updateAmount(String value) {
    amount.value = value;
  }

  Future<void> depositWallet() async {
    try {
      isLoading.value = true;
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      Get.snackbar(
        'Success',
        'Wallet deposit initiated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to initiate deposit',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendOTP() async {
    if (transferToAccount.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter transfer to account',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (amount.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      Get.snackbar(
        'OTP Sent',
        'OTP has been sent to your registered mobile number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send OTP',
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
    transferFromController.dispose();
    transferToController.dispose();
    amountController.dispose();
    super.onClose();
  }
}

