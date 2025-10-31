import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pipze/widgets/custom_toast.dart';
import '../services/auth_service.dart';
import 'account_controller.dart'; // Assuming your API logic is in AuthService

class ChangePasswordController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // Observable states
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _successMessage = ''.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get successMessage => _successMessage.value;

  // Text editing controllers (optional — you can also pass directly from screen)

  final newPasswordController = TextEditingController();

  final confirmPassword = ''.obs;

  /// ✅ Main function to change password
  Future<void> changePassword() async {
    try {
      _setLoading(true);
      _clearError();

      final accountController = Get.find<AccountController>();
      final activeAccount = accountController.activeMT5Account?.metaAccountNumber;

      print('🔐 Changing password...');

      // 🧠 Call your backend API from AuthService
      final response = await _authService.changePassword(
        mt5Account: activeAccount.toString(),
        newPassword: newPasswordController.text.trim(),
      );

      print('🔐 Response: $response');
      if (response.success) {
        _setSuccess(response.data?['message'] ?? 'Password changed successfully');
      } else {
        _setError(response.message ?? 'Failed to change password');
      }
    } catch (e) {
      _setError('Error changing password: $e');
      if (kDebugMode) print('ChangePasswordController: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Internal helpers
  void _setLoading(bool value) => _isLoading.value = value;

  void _setError(String message) {
    _errorMessage.value = message;
    if (message.isNotEmpty) {
      CustomToastService.showError(message: message);
    }
  }

  void _setSuccess(String message) {
    _successMessage.value = message;
    if (message.isNotEmpty) {
      CustomToastService.showSuccess(
        message: message,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _clearError() => _errorMessage.value = '';

  void clearMessages() {
    _errorMessage.value = '';
    _successMessage.value = '';
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    super.onClose();
  }
}