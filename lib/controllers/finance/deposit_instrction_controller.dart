import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pipze/routes/app_pages.dart';
import 'dart:io';

import '../../constants/api_const.dart';
import '../../controllers/dashboard_controller.dart';
import '../../services/api_service.dart';
import '../../services/secure_storage_service.dart';
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

  /// Submit deposit instruction (Bank, Crypto, Local, etc.)
  Future<void> submitDepositInstruction(
    Map<String, dynamic> requestData,
  ) async {
    if (selectedImage.value == null) {
      CustomToastService.showError(
        message: 'Please upload a payment proof file',
      );
      return;
    }

    try {
      isLoading.value = true;
      final token = await SecureStorageService.getAuthToken();

      final response = await ApiService.uploadImageDepositRequest(
        endpoint: ApiConstants.depositRequest,
        file: selectedImage.value!,
        token: token,
        formData: requestData,
      );

      if (response.success) {
        CustomToastService.showSuccess(
          message: response.message ?? 'Deposit request submitted successfully',
        );

        // Mark dashboard MT5 accounts as stale so it refreshes when user returns to dashboard
        // Don't call API here since we're navigating away from dashboard
        try {
          final dashboardController = Get.find<DashboardController>();
          dashboardController.markMT5AccountsAsStale();
        } catch (_) {}

        Get.toNamed(AppPages.TRANSACTION_HISTORY,arguments: {'from': 'dashboard'});

        amountController.clear();
        selectedImage.value = null;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Deposit submission failed',
        );
      }
    } catch (e, t) {
      print("object   imsgr error $t");
      print("object   imsgr error $e");
      CustomToastService.showError(
        message: 'Error while submitting deposit: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit deposit instruction (Bank, Crypto, Local, etc.)
  Future<void> submitDepositInstructionForCrypto(
    Map<String, dynamic> requestData,
  ) async {
    if (selectedImage.value == null) {
      CustomToastService.showError(
        message: 'Please upload a payment proof file',
      );
      return;
    }

    try {
      isLoading.value = true;
      final token = await SecureStorageService.getAuthToken();

      final response = await ApiService.uploadImageDepositRequest(
        endpoint: ApiConstants.depositRequest,
        file: selectedImage.value!,
        token: token,
        formData: requestData,
      );

      if (response.success) {
        CustomToastService.showSuccess(
          message: response.message ?? 'Deposit request submitted successfully',
        );

        // Mark dashboard MT5 accounts as stale so it refreshes when user returns to dashboard
        // Don't call API here since we're navigating away from dashboard
        try {
          final dashboardController = Get.find<DashboardController>();
          dashboardController.markMT5AccountsAsStale();
        } catch (_) {}

        Get.toNamed(AppPages.TRANSACTION_HISTORY,arguments: {'from': 'finance'});

        amountController.clear();
        selectedImage.value = null;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Deposit submission failed',
        );
      }
    } catch (e, t) {
      print("object   imsgr error $t");
      print("object   imsgr error $e");
      CustomToastService.showError(
        message: 'Error while submitting deposit: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
