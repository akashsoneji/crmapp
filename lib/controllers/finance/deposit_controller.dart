import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/widgets/custom_toast.dart';

import '../../constants/api_const.dart';
import '../../services/secure_storage_service.dart';
// import your DepositService here when ready

class DepositController extends GetxController {
  // Observable states
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _successMessage = ''.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get successMessage => _successMessage.value;

  // Deposit methods list
  final depositMethod = Rxn<Map<String, dynamic>>(); // store single API object
  final selectedPaymentMethod =
      Rxn<Map<String, dynamic>>(); // currently selected one

  // Transfer-to accounts list (depends on deposit_slug)
  final transferAccounts = <Map<String, dynamic>>[].obs;
  final selectedTransferAccount = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    // fetchDepositPaymentMethodsLists(); // automatically call when controller is created
  }

  /// Call deposit API
  Future<void> submitDepositForTopUpDemo(
    Map<String, dynamic> requestData,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      // TODO: Replace with your actual API call
      final token = await SecureStorageService.getAuthToken();

      final response = await ApiService.post(
        endpoint: ApiConstants.topupDemoAccount,
        token: token,
        data: requestData,
      );

      if (response.success) {
        Get.back();
        _setLoading(false);
        CustomToastService.showSuccess(
          message: response.message ?? 'Deposited successfully!',
        );
      } else {
        _setLoading(false);
        CustomToastService.showError(
          message: response.message ?? 'Deposited error!',
        );
      }
    } catch (e) {
      _setLoading(false);
      CustomToastService.showError(message: 'Error while depositing: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set selected payment method and fetch accounts based on deposit_slug
  void setSelectedPaymentMethod(Map<String, dynamic> method) {
    selectedPaymentMethod.value = method;
    final slug = method['deposit_slug'];
    if (slug != null) {
      fetchAccountsForPaymentMethod(slug);
    }
  }

  Future<void> fetchAccountsForPaymentMethod(String slug) async {
    final token = await SecureStorageService.getAuthToken();
    final response = await ApiService.get(
      endpoint: "${ApiConstants.depositList}/$slug",
      token: token,
    );

    if (response.success && response.data != null) {
      final root = response.data as Map<String, dynamic>;
      final data = root['data'] as Map<String, dynamic>?; // go inside "data"

      if (data != null) {
        final depositMethod = data['depositMethod'] as Map<String, dynamic>?;
        if (depositMethod != null) {
          this.depositMethod.value = depositMethod; // store single object
          selectedPaymentMethod.value =
              depositMethod; // set currently selected method
        }

        // Extract MT5 accounts
        List<Map<String, dynamic>> mt5Accounts =
            List<Map<String, dynamic>>.from(data['userMT5Accounts'] ?? []);

        // Add wallet entry if available
        final wallet = data['wallet'];
        if (wallet != null) {
          final walletAccount = {
            "id": wallet['id'],
            "user_id": wallet['user_id'],
            "account_type": "Wallet",
            "master_group_id": "Wallet",
            "meta_account_number": wallet['wallet_id'],
            "mt5_name": "Wallet",
            "balance": wallet['wallet_balance'],
            "currency": "USD",
          };
          mt5Accounts.add(walletAccount);
        }

        // Assign to observable
        transferAccounts.assignAll(mt5Accounts);

        // Auto-select first
        if (mt5Accounts.isNotEmpty) {
          selectedTransferAccount.value = mt5Accounts.first;
        }
      }
    } else {
      transferAccounts.clear();
      Get.back();
      CustomToastService.showError(message: response.message ?? "");
    }
  }

  // Helpers
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void clearMessages() {
    _errorMessage.value = '';
    _successMessage.value = '';
  }
}
