import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Controller
class DepositController extends GetxController {
  final RxString selectedPaymentMode = 'Bitcoin'.obs;
  final RxString accountNumber = '5013314'.obs;
  final RxString accountType = 'Standard'.obs;
  final RxDouble accountBalance = 0.00.obs;
  final RxString selectedCurrency = 'USD'.obs;
  final RxDouble depositAmount = 100.00.obs;
  final RxDouble usdtAmount = 101.00.obs;
  final RxDouble finalAmount = 0.003.obs;

  final List<String> paymentModes = ['Bitcoin', 'Ethereum', 'USDT', 'Bank Transfer'];
  final List<String> currencies = ['USD', 'EUR', 'GBP', 'INR'];

  void updatePaymentMode(String mode) {
    selectedPaymentMode.value = mode;
    // Update conversion rates based on payment mode
    _updateConversion();
  }

  void updateCurrency(String currency) {
    selectedCurrency.value = currency;
    _updateConversion();
  }

  void updateDepositAmount(double amount) {
    depositAmount.value = amount;
    _updateConversion();
  }

  void _updateConversion() {
    // Simulate conversion logic
    if (selectedPaymentMode.value == 'Bitcoin') {
      finalAmount.value = depositAmount.value * 0.000003; // Example rate
      usdtAmount.value = depositAmount.value * 1.01;
    }
  }

  void proceedDeposit() {
    // Handle deposit logic
    Get.snackbar(
      'Deposit Initiated',
      'Processing ${finalAmount.value} ${selectedPaymentMode.value}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
