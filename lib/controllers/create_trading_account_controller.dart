import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/widgets/custom_toast.dart' show CustomToastService;
import '../widgets/congratulations_dialog.dart';
import '../controllers/account_controller.dart';

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
  final currencyController = TextEditingController();
  final accounts = ['MT5 Demo', 'Pipze Demo'];
  final selected = 'Pipze Demo'.obs; // default selected

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
    currencyController.text = 'USD';
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

      // Get account controller
      final accountController = Get.find<AccountController>();

      // Determine account type and group ID
      String accountType = 'demo'; // Default to demo
      int groupId = 1; // Default group ID for demo accounts

      if (selectedAccountType.value.contains('Real')) {
        accountType = 'real';
        groupId = 2; // Different group ID for real accounts
      }

      print('Creating MT5 account with:');
      print('Group ID: $groupId');
      print('Main Password: ${tradingPassword.value}');
      print('Investor Password: ${investorPassword.value}');
      print('Account Type: $accountType');

      // Call the real API
      final success = await accountController.createMT5Account(
        groupId: groupId,
        mainPassword: tradingPassword.value,
        investorPassword: investorPassword.value,
        accountType: accountType,
      );

      if (success) {
        // Show success message
        Get.snackbar(
          'Success',
          'Account created successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Show congratulations popup
        Get.dialog(
          CongratulationsDialog(
            accountNumber: 'New Account',
            serverName: 'Meta-Right',
          ),
          barrierDismissible: false,
        );
      } else {
        // Show error message
        Get.snackbar(
          'Error',
          accountController.errorMessage.isNotEmpty
              ? accountController.errorMessage
              : 'Failed to create account. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error creating account: $e');
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

  Future<void> createDemoAccount() async {
    // Basic validation
    if (depositAmount.value.isEmpty) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Please enter deposit amount',
      );
      return;
    }

    if (tradingPassword.value.isEmpty || tradingPassword.value == 'xxxxxxxxx') {
      CustomToastService.showError(
        title: 'Error',
        message: 'Please enter trading password',
      );
      return;
    }

    if (investorPassword.value.isEmpty ||
        investorPassword.value == 'xxxxxxxxx') {
      CustomToastService.showError(
        title: 'Error',
        message: 'Please enter investor password',
      );
      return;
    }

    try {
      isLoading.value = true;

      // Get account controller
      final accountController = Get.find<AccountController>();

      // Determine account type and group ID
      String accountType = 'demo'; // Default to demo
      int groupId = 1; // Default group ID for demo accounts

      print('Creating MT5 account with:');
      print('Group ID: $groupId');
      print('Main Password: ${tradingPassword.value}');
      print('Investor Password: ${investorPassword.value}');
      print('Account Type: $accountType');

      // Call the real API
      final success = await accountController.createMT5Account(
        groupId: groupId,
        mainPassword: tradingPassword.value,
        investorPassword: investorPassword.value,
        accountType: accountType,
      );

      if (success) {
        // Show success message
        CustomToastService.showSuccess(
          title: 'Success',
          message: 'Account created successfully!',
        );
        Get.back();
        Get.until((route) => route.isFirst);
        // Show congratulations popup
      } else {
        // Show error message
        CustomToastService.showError(
          title: 'Error',
          message:
              accountController.errorMessage.isNotEmpty
                  ? accountController.errorMessage
                  : 'Failed to create account. Please try again.',
        );
      }
    } catch (e) {
      print('Error creating account: $e');
      CustomToastService.showError(
        title: 'Error',
        message: 'Failed to create account. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
    // try {
    //   isLoading.value = true;

    //   // Simulate API call
    //   await Future.delayed(Duration(seconds: 2));

    //   // Show congratulations popup
    //   Get.back();
    //   Get.until((route) => route.isFirst);
    // } catch (e) {
    //   Get.snackbar(
    //     'Error',
    //     'Failed to create account. Please try again.',
    //     snackPosition: SnackPosition.BOTTOM,
    //     backgroundColor: Colors.red,
    //     colorText: Colors.white,
    //   );
    // } finally {
    //   isLoading.value = false;
    // }
  }

  @override
  void onClose() {
    depositAmountController.dispose();
    tradingPasswordController.dispose();
    investorPasswordController.dispose();
    super.onClose();
  }
}
