
import '../../constants/api_const.dart';
import '../../services/api_service.dart';
import '../../services/secure_storage_service.dart';
import '../../widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/screens/home/more/finance/deposit_screen.dart';


// --- Models ---
class WalletResponse {
  final bool status;
  final String message;
  final List<UserMT5Account> userMT5Accounts;
  final Wallet wallet;
  final IbAccount ibAccount;

  WalletResponse({
    required this.status,
    required this.message,
    required this.userMT5Accounts,
    required this.wallet,
    required this.ibAccount,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? "",
      userMT5Accounts: (json['data']?['userMT5Accounts'] as List? ?? [])
          .map((e) => UserMT5Account.fromJson(e))
          .toList(),
      wallet: Wallet.fromJson(json['data']?['wallet'] ?? {}),
      ibAccount: IbAccount.fromJson(json['data']?['ibaccount'] ?? {}),
    );
  }
}

class UserMT5Account {
  final int id;
  final String metaAccountNumber;
  final String metaAccountName;
  final String masterGroupId;
  final String balance;

  UserMT5Account({
    required this.id,
    required this.metaAccountNumber,
    required this.metaAccountName,
    required this.masterGroupId,
    required this.balance,
  });

  factory UserMT5Account.fromJson(Map<String, dynamic> json) {
    return UserMT5Account(
      id: json['id'] ?? 0,
      metaAccountNumber: json['meta_account_number'] ?? '',
      metaAccountName: json['meta_account_name'] ?? '',
      masterGroupId: json['master_group_id'] ?? '',
      balance: json['balance'] ?? '0.0',
    );
  }
}

class Wallet {
  final int id;
  final String walletId;
  final String walletStatus;
  final String walletBalance;

  Wallet({
    required this.id,
    required this.walletId,
    required this.walletStatus,
    required this.walletBalance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? 0,
      walletId: json['wallet_id'] ?? '',
      walletStatus: json['wallet_status'] ?? '',
      walletBalance: json['wallet_balance'] ?? '0.0',
    );
  }
}

class IbAccount {
  final int id;
  final String promotionTool;
  final String status;
  final String referenceLinkId;

  IbAccount({
    required this.id,
    required this.promotionTool,
    required this.status,
    required this.referenceLinkId,
  });

  factory IbAccount.fromJson(Map<String, dynamic> json) {
    return IbAccount(
      id: json['id'] ?? 0,
      promotionTool: json['promotion_tool'] ?? '',
      status: json['status'] ?? '',
      referenceLinkId: json['reference_link_id'] ?? '',
    );
  }
}
class WalletController extends GetxController {
  var walletId = 'PIPW008'.obs;
  var balance = 100.00.obs;
  var transferFromAccount = ''.obs;
  var transferToAccount = ''.obs;
  var amount = ''.obs;
  var isLoading = false.obs;
  var showTransferFromDropdown = false.obs;

  // Observables for parsed wallet data
  var mt5Accounts = <UserMT5Account>[].obs;
  var wallet = Rxn<Wallet>();
  var ibAccount = Rxn<IbAccount>();

  final transferFromController = TextEditingController();
  final transferToController = TextEditingController();
  final amountController = TextEditingController();

  // Sample account options for dropdown
  final List<String> accountOptions = [
    'MT5 Account Number',
    'MT4 Account Number',
    'Demo Account',
    'Live Account 001',
    'Live Account 002',
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
    fetchWalletData();
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

      // // Show loading overlay
      // Get.find<LoadingService>().showLoading(
      //   message: 'Processing deposit...',
      //   color: Colors.purple,
      // );

      // Simulate API call
      await Future.delayed(Duration(seconds: 3));

      Get.to(() => DepositScreen(accountNumber: ''));

      // Hide loading overlay
      // Get.find<LoadingService>().hideLoading();
    } catch (e) {
      // Hide loading overlay on error
      // Get.find<LoadingService>().hideLoading();

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

  Future<void> fetchWalletData() async {
    try {
      isLoading.value = true;

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: ApiConstants.getWalletData, // placeholder endpoint
        token: token,
      );

      if (response.success && response.data != null) {
        final parsed = WalletResponse.fromJson(response.data);
        print("Wallet API Parsed Response: ${parsed.message}");
        mt5Accounts.assignAll(parsed.userMT5Accounts);
        wallet.value = parsed.wallet;
        ibAccount.value = parsed.ibAccount;
      } else {
        print("Failed to fetch wallet data: ${response.message}");
        CustomToastService.showError(message: response.message ?? "Something went wrong");
      }
    } catch (e) {
      print("Error fetching wallet data: $e");
      CustomToastService.showError(message: "Error while fetching wallet data: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

