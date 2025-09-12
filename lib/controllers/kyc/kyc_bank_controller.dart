import 'dart:io';
import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/models/bank_withdralList_model.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/models/currency_list_model.dart';

class KycBankController extends GetxController {
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isOtpLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  // Account type selection
  final RxString selectedAccountType = 'Bank'.obs;
  final RxList<String> accountTypes = ['Bank', 'Crypto', 'UPI'].obs;
  final RxList<String> ifscIbanList = ['IFSC', 'IBAN'].obs;

  // Currency list
  final RxList<String> currencies = <String>[].obs;
  final RxList<WithdrawalMethods> bankWithdrawalList =
      <WithdrawalMethods>[].obs;
  final RxString selectedCurrency = 'USD'.obs;
  final RxString selectedIfscIban = 'IFSCs'.obs;

  // Form fields
  final RxString ifscIbanType = ''.obs;
  final RxString bankName = ''.obs;
  final RxString accountHolderName = ''.obs;
  final RxString bankAccountNumber = ''.obs;
  final RxString confirmBankAccountNumber = ''.obs;
  final RxString bankSwiftCode = ''.obs;
  final RxString cryptoAddress = ''.obs;
  final RxString upiAddress = ''.obs;
  final RxString optRadio = 'IFSC'.obs; // For IFSC/IBAN selection
  final RxString ifscIbanCode = ''.obs; // For IFSC/IBAN selection

  // OTP
  final RxString otp = ''.obs;
  final RxBool isOtpSent = false.obs;

  // File upload
  final Rx<File?> proofFile = Rx<File?>(null);
  var isBankList = false.obs;

  // Navigation callback
  Function()? onNavigationCallback;

  @override
  void onInit() {
    super.onInit();

    fetchCurrencyList();
  }

  // Fetch currency list
  Future<void> fetchCurrencyList() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: ApiConstants.currencyList,
        token: token,
      );

      if (response.success) {
        print('✅ Currency list fetched successfully');
        final currencyListModel = CurrencyListModel.fromJson(response.data);
        currencies.value = currencyListModel.data?.currencies ?? [];
        print('💰 Found ${currencies.length} currencies');
      } else {
        errorMessage.value =
            response.message ?? 'Failed to fetch currency list';
        print('❌ Failed to fetch currency list: ${response.message}');
      }
    } catch (e) {
      errorMessage.value = 'Error fetching currency list: $e';
      print('❌ Error fetching currency list: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWithdrawalList() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: ApiConstants.bankWithdrawalList,
        token: token,
      );

      if (response.success) {
        print('✅ Currency list fetched successfully');
        final currencyListModel = BankWithdrawleList.fromJson(response.data);
        bankWithdrawalList.value =
            currencyListModel.data?.withdrawalMethods ?? [];
        print('💰 Found ${currencies.length} currencies');
      } else {
        errorMessage.value =
            response.message ?? 'Failed to fetch currency list';
        print('❌ Failed to fetch currency list: ${response.message}');
      }
    } catch (e) {
      errorMessage.value = 'Error fetching currency list: $e';
      print('❌ Error fetching currency list: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Set account type
  void setAccountType(String accountType) {
    selectedAccountType.value = accountType;
    clearFormFields();
    // Reset OTP state when changing account type
    isOtpSent.value = false;
    otp.value = '';
  }

  // Clear form fields
  void clearFormFields() {
    ifscIbanCode.value = '';
    bankName.value = '';
    accountHolderName.value = '';
    bankAccountNumber.value = '';
    confirmBankAccountNumber.value = '';
    bankSwiftCode.value = '';
    cryptoAddress.value = '';
    upiAddress.value = '';
    otp.value = '';
    isOtpSent.value = false;
    proofFile.value = null;
    accountHolderName.value = "";
  }

  // Send OTP
  Future<void> sendOtp() async {
    try {
      isOtpLoading.value = true;
      errorMessage.value = '';

      // Validate required fields based on account type
      if (!_validateRequiredFields()) {
        return;
      }

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: ApiConstants.withdrawalSendOTPRequest,
        token: token,
        // data: _buildOtpRequestParams(),
      );

      if (response.success) {
        print('✅ OTP sent successfully');
        isOtpSent.value = true;
        successMessage.value = 'OTP sent successfully';
        CustomToastService.show(
          message: 'OTP sent to your registered mobile number',
          type: ToastType.success,
        );
      } else {
        errorMessage.value = response.message ?? 'Failed to send OTP';
        print('❌ Failed to send OTP: ${response.message}');
        CustomToastService.show(
          message: response.message ?? 'Failed to send OTP',
          type: ToastType.error,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error sending OTP: $e';
      print('❌ Error sending OTP: $e');
      CustomToastService.show(
        message: 'Error sending OTP: $e',
        type: ToastType.error,
      );
    } finally {
      isOtpLoading.value = false;
    }
  }

  // Submit withdrawal
  Future<void> submitWithdrawal() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Validate OTP
      if (otp.value.isEmpty) {
        errorMessage.value = 'Please enter OTP';
        CustomToastService.show(
          message: 'Please enter OTP',
          type: ToastType.error,
        );
        return;
      }

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.post(
        endpoint: ApiConstants.withdrawalRequest,
        token: token,
        data: _buildWithdrawalRequestParams(),
      );

      if (response.success) {
        print('✅ Withdrawal submitted successfully');
        successMessage.value = 'Withdrawal request submitted successfully';
        CustomToastService.show(
          message: 'Withdrawal request submitted successfully',
          type: ToastType.success,
        );
        // Reset form
        clearFormFields();
        selectedAccountType.value = 'Bank';
        selectedCurrency.value = 'USD';

        print('isBankList: ${isBankList.value}');
        if (isBankList.value) {
          Future.delayed(Duration.zero, () {
            Get.back();
          });
          // fetchWithdrawalList();
        }

        // Navigate to Bank List screen on success
      } else {
        errorMessage.value = response.message ?? 'Failed to submit withdrawal';
        print('❌ Failed to submit withdrawal: ${response.message}');
        CustomToastService.show(
          message: response.message ?? 'Failed to submit withdrawal',
          type: ToastType.error,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error submitting withdrawal: $e';
      print('❌ Error submitting withdrawal: $e');
      CustomToastService.show(
        message: 'Error submitting withdrawal: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Validate required fields - Dynamic validation based on account type
  bool _validateRequiredFields() {
    // Common validation
    if (selectedAccountType.value.isEmpty) {
      errorMessage.value = 'Please select account type';
      CustomToastService.show(
        message: 'Please select account type',
        type: ToastType.error,
      );
      return false;
    }

    if (selectedCurrency.value.isEmpty) {
      errorMessage.value = 'Please select currency';
      CustomToastService.show(
        message: 'Please select currency',
        type: ToastType.error,
      );
      return false;
    }

    if (accountHolderName.value.isEmpty) {
      errorMessage.value = 'Please enter account holder name';
      CustomToastService.show(
        message: 'Please enter account holder name',
        type: ToastType.error,
      );
      return false;
    }
    if (accountHolderName.value.isEmpty) {
      errorMessage.value = 'Please enter account holder name';
      CustomToastService.show(
        message: 'Please enter account holder name',
        type: ToastType.error,
      );
      return false;
    }

    // Dynamic validation based on account type
    if (selectedAccountType.value.toLowerCase() == "bank") {
      if (ifscIbanCode.value.isEmpty) {
        errorMessage.value = 'Please enter IFSC/IBAN code';
        CustomToastService.show(
          message: 'Please enter IFSC/IBAN code',
          type: ToastType.error,
        );
        return false;
      }
      if (bankName.value.isEmpty) {
        errorMessage.value = 'Please enter bank name';
        CustomToastService.show(
          message: 'Please enter bank name',
          type: ToastType.error,
        );
        return false;
      }
      if (bankAccountNumber.value.isEmpty) {
        errorMessage.value = 'Please enter bank account number';
        CustomToastService.show(
          message: 'Please enter bank account number',
          type: ToastType.error,
        );
        return false;
      }
      if (confirmBankAccountNumber.value.isEmpty) {
        errorMessage.value = 'Please confirm bank account number';
        CustomToastService.show(
          message: 'Please confirm bank account number',
          type: ToastType.error,
        );
        return false;
      }
      if (bankAccountNumber.value != confirmBankAccountNumber.value) {
        errorMessage.value = 'Bank account numbers do not match';
        CustomToastService.show(
          message: 'Bank account numbers do not match',
          type: ToastType.error,
        );
        return false;
      }
    } else if (selectedAccountType.value.toLowerCase() == "crypto") {
      if (cryptoAddress.value.isEmpty) {
        errorMessage.value = 'Please enter crypto address';
        CustomToastService.show(
          message: 'Please enter crypto address',
          type: ToastType.error,
        );
        return false;
      }
    } else {
      // UPI case
      if (upiAddress.value.isEmpty) {
        errorMessage.value = 'Please enter UPI address';
        CustomToastService.show(
          message: 'Please enter UPI address',
          type: ToastType.error,
        );
        return false;
      }
    }

    // Proof validation - Required for all account types
    if (proofFile.value == null) {
      errorMessage.value = 'Please upload proof image';
      CustomToastService.show(
        message: 'Please upload proof image',
        type: ToastType.error,
      );
      return false;
    }

    return true;
  }

  // Build OTP request parameters - Dynamic based on account type
  Map<String, dynamic> _buildOtpRequestParams() {
    final params = <String, dynamic>{};

    // Add conditional parameters based on account type
    if (selectedAccountType.value.toLowerCase() == "bank") {
      params.addAll({
        "ifsc_iban": ifscIbanCode.value,
        "bank_name": bankName.value,
        "bank_holder_name": accountHolderName.value,
        "bank_account_no": bankAccountNumber.value,
        "confirm_bank_account_no": confirmBankAccountNumber.value,
        "swift_code": bankSwiftCode.value,
        "optradio": ifscIbanType.value,
      });
    } else if (selectedAccountType.value.toLowerCase() == "crypto") {
      params.addAll({
        "crypto_holder_name": accountHolderName.value,
        "crypto_address": cryptoAddress.value,
      });
    } else {
      // UPI case
      params.addAll({
        "upi_holder_name": accountHolderName.value,
        "upi_address": upiAddress.value,
      });
    }

    // Add common parameters
    params.addAll({
      "withdrawal_method": selectedAccountType.value.toLowerCase(),
      "currency": selectedCurrency.value,
      "belogns_to": "",
      "relationship": "",
      "holder_name": accountHolderName.value,
    });

    return params;
  }

  // Build withdrawal request parameters
  Map<String, dynamic> _buildWithdrawalRequestParams() {
    final params = _buildOtpRequestParams();
    params.addAll({
      'otp': otp.value,
      'deposit_proof':
          proofFile.value?.path ?? '', // Add deposit proof file path
    });
    return params;
  }

  // Set currency
  void setCurrency(String currency) {
    selectedCurrency.value = currency;
  }

  // Set IFSC/IBAN code
  void setIfscIbanCode(String ifscIbanCode) {
    this.selectedIfscIban.value = ifscIbanCode;
  }

  // Set IFSC/IBAN radio selection
  void setOptRadio(String value) {
    optRadio.value = value;
  }

  // Set proof file
  void setProofFile(File? file) {
    proofFile.value = file;
  }

  void setIsBankList(bool value) {
    isBankList.value = value;
  }

  void setNavigationCallback(Function()? callback) {
    onNavigationCallback = callback;
  }

  // Clear all data
  void clearAllData() {
    clearFormFields();
    selectedAccountType.value = 'Bank';
    selectedCurrency.value = 'USD';
    currencies.clear();
    errorMessage.value = '';
    successMessage.value = '';
  }
}
