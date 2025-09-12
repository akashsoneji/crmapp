import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../services/api_service.dart';
import '../../widgets/custom_toast.dart';

class DepositInstructionController extends GetxController {
  // Observable variables

  final isLoading = false.obs;
  final amount = ''.obs;
  final cryptoAddress = 'UGIGfjdsofijofijwesef'.obs;
  var selectedImage = Rx<File?>(null);

  // Text editing controller
  final amountController = TextEditingController();

  // API service (you can inject this)
  final ApiService _apiService = Get.find<ApiService>();

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    // Initialize any data or fetch crypto address from API
    fetchCryptoAddress();
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  // Fetch crypto address from API
  Future<void> fetchCryptoAddress() async {
    try {
      isLoading.value = true;

      // Example API call
      // final response = await _apiService.getCryptoAddress();
      // cryptoAddress.value = response.address;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      cryptoAddress.value = 'UGIGfjdsofijofijwesef';

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch crypto address: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Handle image picking
  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
      }
    } catch (e) {
      print(e);
    }
  }

  // Copy crypto address to clipboard
  void copyCryptoAddress() {
    // Clipboard.setData(ClipboardData(text: cryptoAddress.value));

    CustomToastService.showSuccess(message: 'Copied');
  }

  // Submit deposit request
  Future<void> submitDeposit() async {
    if (amountController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter the amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedImage.value == null) {
      Get.snackbar(
        'Error',
        'Please upload a payment proof file',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Example API call for deposit submission
      // final response = await _apiService.submitDeposit(
      //   amount: double.parse(amountController.text),
      //   file: selectedImage.value!,
      //   cryptoAddress: cryptoAddress.value,
      // );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      Get.snackbar(
        'Success',
        'Deposit request submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Reset form
      amountController.clear();
      selectedImage.value = null;

      // Navigate back or to success page
      // Get.back();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit deposit: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
