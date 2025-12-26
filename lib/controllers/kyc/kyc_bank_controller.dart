import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/models/bank_withdralList_model.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/models/currency_list_model.dart';

class KycBankController extends GetxController {
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isOtpLoading = false.obs;
  final RxBool hasLoadedOnce = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  // Account type selection
  final RxString selectedAccountType = 'Bank'.obs;
  final RxString selectedRelationship = 'Other'.obs;
  final RxList<String> accountTypes = ['Bank', 'Crypto', 'UPI'].obs;
  final RxList<String> relationShips =
      ['Other', 'Mother', 'Father', 'Son', 'Wife', 'Daughter'].obs;
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

  // OTP Countdown Timer
  final RxInt otpCountdownSeconds = 0.obs;
  final RxBool isOtpCountdownActive = false.obs;
  Timer? _otpCountdownTimer;

  // App lifecycle handling
  late AppLifecycleListener _appLifecycleListener;
  DateTime? _backgroundTime;

  // File upload
  final Rx<File?> proofFile = Rx<File?>(null);
  var isBankList = false.obs;

  // Navigation callback
  Function()? onNavigationCallback;

  @override
  void onInit() {
    super.onInit();

    fetchCurrencyList();

    // Initialize app lifecycle listener
    _appLifecycleListener = AppLifecycleListener(
      onDetach: () {
        print('📱 App detached - stopping timer');
        _otpCountdownTimer?.cancel();
        _otpCountdownTimer = null;
      },
      onHide: () {
        print('📱 App hidden - pausing timer');
        _backgroundTime = DateTime.now();
        _otpCountdownTimer?.cancel();
        _otpCountdownTimer = null;
      },
      onShow: () {
        print('📱 App shown - resuming timer');
        if (_backgroundTime != null && isOtpCountdownActive.value) {
          final backgroundDuration = DateTime.now().difference(
            _backgroundTime!,
          );
          final remainingSeconds =
              otpCountdownSeconds.value - backgroundDuration.inSeconds;

          if (remainingSeconds > 0) {
            otpCountdownSeconds.value = remainingSeconds;
            _startOtpCountdown();
          } else {
            isOtpCountdownActive.value = false;
            otpCountdownSeconds.value = 0;
          }
        }
        _backgroundTime = null;
      },
    );
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
      hasLoadedOnce.value = true; // Mark first load complete
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

  void setRelationShip(String relation) {
    selectedRelationship.value = relation;
    clearFormFields();
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
        // Use API response message instead of static text
        successMessage.value = response.message ?? 'OTP sent successfully';

        // Start countdown timer (60 seconds = 1 minute)
        _startOtpCountdown();

        CustomToastService.show(
          message: response.message ?? 'OTP sent',
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

      // Use multipart upload for file submission
      ApiResponse response;
      if (proofFile.value != null) {
        response = await _uploadWithdrawalWithFile(token!);
      } else {
        // Fallback to regular POST if no file
        response = await ApiService.post(
          endpoint: ApiConstants.withdrawalRequest,
          token: token,
          data: _buildWithdrawalRequestParams(),
        );
      }

      if (response.success) {
        print('✅ Withdrawal submitted successfully');
        // Use API response message instead of static text
        successMessage.value = response.message ?? 'Withdrawal request submitted successfully';
        CustomToastService.show(
          message: response.message ?? 'Withdrawal request submitted successfully',
          type: ToastType.success,
        );
        // Reset form
        clearFormFields();
        selectedAccountType.value = 'Bank';
        selectedCurrency.value = 'USD';

        print('isBankList: ${isBankList.value}');
        if (isBankList.value) {
          // Add a small delay to ensure the success message is shown
          Future.delayed(Duration(milliseconds: 500), () {
            _safeNavigateToBankList();
          });
        } else {
          Get.toNamed(AppPages.KYC_SUCCESS);
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
      "relationship": selectedRelationship.value.toLowerCase(),
      "holder_name": accountHolderName.value,
    });

    return params;
  }

  // Build withdrawal request parameters
  Map<String, dynamic> _buildWithdrawalRequestParams() {
    final params = _buildOtpRequestParams();
    params.addAll({'otp': otp.value});

    // Add proof image with method-specific field name
    String proofFieldName = _getProofFieldName();
    if (proofFile.value != null) {
      params[proofFieldName] = proofFile.value!.path;
    }

    return params;
  }

  // Get the correct proof field name based on withdrawal method
  String _getProofFieldName() {
    switch (selectedAccountType.value.toLowerCase()) {
      case 'bank':
        return 'bank_proof_img';
      case 'upi':
        return 'upi_proof_img';
      case 'crypto':
        return 'crypto_proof_img';
      default:
        return 'deposit_proof';
    }
  }

  // Upload withdrawal request with file using multipart
  Future<ApiResponse> _uploadWithdrawalWithFile(String token) async {
    try {
      final params = _buildWithdrawalRequestParams();
      final proofFieldName = _getProofFieldName();

      // Remove the proof file path from params as it will be handled by multipart
      params.remove(proofFieldName);

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.withdrawalRequest}',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(headers);

      // Add form data
      params.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add file with the correct field name
      request.files.add(
        await http.MultipartFile.fromPath(
          proofFieldName,
          proofFile.value!.path,
        ),
      );

      print('📤 Uploading withdrawal with file:');
      print('   Field name: $proofFieldName');
      print('   File path: ${proofFile.value!.path}');
      print('   Form data: $params');

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Withdrawal upload response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final responseData = json.decode(response.body);

      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: responseData['message'] ?? 'Upload completed',
        data: responseData,
      );
    } catch (e) {
      print('❌ Error uploading withdrawal with file: $e');
      return ApiResponse(
        success: false,
        message: 'Upload failed: $e',
        data: null,
      );
    }
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

    // Clear timer and reset countdown
    _otpCountdownTimer?.cancel();
    _otpCountdownTimer = null;
    isOtpCountdownActive.value = false;
    otpCountdownSeconds.value = 0;
  }

  // OTP Countdown Timer Methods
  void _startOtpCountdown() {
    // Cancel any existing timer
    _otpCountdownTimer?.cancel();

    otpCountdownSeconds.value = 60; // 1 minute = 60 seconds
    isOtpCountdownActive.value = true;

    // Start countdown timer using Timer.periodic
    _otpCountdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      try {
        if (otpCountdownSeconds.value > 0) {
          otpCountdownSeconds.value--;
        } else {
          // Countdown finished
          timer.cancel();
          isOtpCountdownActive.value = false;
          _otpCountdownTimer = null;
          print('⏰ OTP countdown finished - Resend button enabled');
        }
      } catch (e) {
        print('❌ Error in countdown timer: $e');
        timer.cancel();
        _otpCountdownTimer = null;
        isOtpCountdownActive.value = false;
      }
    });
  }

  // Format countdown time as MM:SS
  String getFormattedCountdown() {
    try {
      final minutes = otpCountdownSeconds.value ~/ 60;
      final seconds = otpCountdownSeconds.value % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } catch (e) {
      print('❌ Error formatting countdown: $e');
      return '00:00';
    }
  }

  // Check if resend button should be enabled
  bool get canResendOtp {
    try {
      return !isOtpCountdownActive.value && !isOtpLoading.value;
    } catch (e) {
      print('❌ Error checking canResendOtp: $e');
      return false;
    }
  }

  /// Safely navigate to bank list screen without snackbar conflicts
  void _safeNavigateToBankList() {
    try {
      // Close any active snackbars first
      try {
        Get.closeCurrentSnackbar();
      } catch (e) {
        print('⚠️ Could not close snackbar: $e');
      }

      // Small delay to ensure snackbar is closed
      Future.delayed(Duration(milliseconds: 100), () {
        try {
          print('🔄 Popping until bank list screen');
          // Try to pop until we reach the existing bank list screen
          // Get.until() will pop routes until the condition is true
          // If bank list is in stack, it will stop there
          // If not found, it will pop all routes and we'll handle it
          try {
            Get.until((route) {
              final routeName = route.settings.name;
              return routeName == AppPages.BANK_LIST;
            });

            // If we reach here, we either found bank list or popped everything
            // Check if current route is now bank list
            Future.delayed(Duration(milliseconds: 100), () {
              if (Get.currentRoute == AppPages.BANK_LIST) {
                print('✅ Found existing bank list screen, popped to it');
                // Refresh the list after popping to existing screen
                Future.delayed(Duration(milliseconds: 200), () {
                  fetchWithdrawalList();
                });
              } else {
                // Bank list not in stack, navigate to it
                print('⚠️ Bank list not in stack, navigating to it');
                Get.offNamed(AppPages.BANK_LIST);
              }
            });
          } catch (untilError) {
            // Get.until() might throw if no routes match, navigate to bank list
            print('⚠️ Could not pop to bank list: $untilError');
            Get.offNamed(AppPages.BANK_LIST);
          }
        } catch (e) {
          print('❌ Error navigating to bank list: $e');
          // Fallback: use offNamed
          try {
            Get.offNamed(AppPages.BANK_LIST);
          } catch (fallbackError) {
            print('❌ Fallback navigation also failed: $fallbackError');
          }
        }
      });
    } catch (e, t) {
      print('❌ Error in safe navigation: $e');
      print('❌ Stack trace: $t');
    }
  }

  @override
  void onClose() {
    // Cancel timer when controller is disposed
    _otpCountdownTimer?.cancel();
    _otpCountdownTimer = null;

    // Dispose app lifecycle listener
    _appLifecycleListener.dispose();

    super.onClose();
  }
}
