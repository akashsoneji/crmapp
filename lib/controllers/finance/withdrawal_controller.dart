// WithdrawalMethodDetailResponse model
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_const.dart';
import '../../models/mt5_account.dart';
import '../../services/api_service.dart';
import '../../services/secure_storage_service.dart';
import '../../widgets/custom_toast.dart';

class WithdrawalMethodDetailResponse {
  final bool? status;
  final String? message;
  final WithdrawalMethodDetailData? data;

  WithdrawalMethodDetailResponse({this.status, this.message, this.data});

  factory WithdrawalMethodDetailResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawalMethodDetailResponse(
      status: json['status'],
      message: json['message'],
      data:
          json['data'] != null
              ? WithdrawalMethodDetailData.fromJson(json['data'])
              : null,
    );
  }
}

class WithdrawalMethodDetailData {
  final WithdrawalMethod? withdrawalMethod;
  final List<dynamic>? userWithdrawalMethods;
  final List<MT5Account>? userMT5Accounts;
  final Wallet? wallet;
  final IbAccount? ibaccount;

  WithdrawalMethodDetailData({
    this.withdrawalMethod,
    this.userWithdrawalMethods,
    this.userMT5Accounts,
    this.wallet,
    this.ibaccount,
  });

  factory WithdrawalMethodDetailData.fromJson(Map<String, dynamic> json) {
    return WithdrawalMethodDetailData(
      withdrawalMethod:
          json['withdrawalMethod'] != null
              ? WithdrawalMethod.fromJson(json['withdrawalMethod'])
              : null,
      userWithdrawalMethods: json['userWithdrawalMethods'] ?? [],
      userMT5Accounts:
          json['userMT5Accounts'] != null && json['userMT5Accounts'] is List
              ? List<MT5Account>.from(
                json['userMT5Accounts'].map((x) => MT5Account.fromJson(x)),
              )
              : [],
      wallet: json['wallet'] != null ? Wallet.fromJson(json['wallet']) : null,
      ibaccount:
          json['ibaccount'] != null && json['ibaccount'] is Map<String, dynamic>
              ? IbAccount.fromJson(json['ibaccount'])
              : null,
    );
  }
}

class Wallet {
  final int? id;
  final String? walletId;
  final String? walletStatus;
  final String? walletBalance;

  Wallet({this.id, this.walletId, this.walletStatus, this.walletBalance});

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? ''),
      walletId: json['wallet_id']?.toString(),
      walletStatus: json['wallet_status']?.toString(),
      walletBalance: json['wallet_balance']?.toString(),
    );
  }
}

class IbAccount {
  final int? id;
  final String? promotionTool;
  final String? status;

  IbAccount({this.id, this.promotionTool, this.status});

  factory IbAccount.fromJson(Map<String, dynamic> json) {
    return IbAccount(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? ''),
      promotionTool: json['promotion_tool']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

// WithdrawalMethodResponse model
class WithdrawalMethodResponse {
  final bool status;
  final String message;
  final List<WithdrawalMethod> data;

  WithdrawalMethodResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory WithdrawalMethodResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawalMethodResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => WithdrawalMethod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data.map((e) => e.toJson()).toList(),
  };
}

// WithdrawalMethod model
class WithdrawalMethod {
  final int? id;
  final String? methodName;
  final String? methodSlug;
  final String? averageLabel;
  final String? uptoLabel;
  final String? minLimit;
  final String? maxLimit;
  final String? fees;
  final String? status;
  final int? updatedBy;
  final String? role;
  final String? icon;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  WithdrawalMethod({
    this.id,
    this.methodName,
    this.methodSlug,
    this.averageLabel,
    this.uptoLabel,
    this.minLimit,
    this.maxLimit,
    this.fees,
    this.status,
    this.updatedBy,
    this.role,
    this.icon,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory WithdrawalMethod.fromJson(Map<String, dynamic> json) {
    return WithdrawalMethod(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? ''),
      methodName: json['method_name']?.toString(),
      methodSlug: json['method_slug']?.toString(),
      averageLabel: json['average_label']?.toString(),
      uptoLabel: json['upto_label']?.toString(),
      minLimit: json['min_limit']?.toString(),
      maxLimit: json['max_limit']?.toString(),
      fees: json['fees']?.toString(),
      status: json['status']?.toString(),
      updatedBy:
          json['updated_by'] is int
              ? json['updated_by']
              : int.tryParse(json['updated_by']?.toString() ?? ''),
      role: json['role']?.toString(),
      icon: json['icon']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'method_name': methodName,
    'method_slug': methodSlug,
    'average_label': averageLabel,
    'upto_label': uptoLabel,
    'min_limit': minLimit,
    'max_limit': maxLimit,
    'fees': fees,
    'status': status,
    'updated_by': updatedBy,
    'role': role,
    'icon': icon,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}

class WithdrawalController extends GetxController {
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _successMessage = ''.obs;

  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get successMessage => _successMessage.value;

  var withdrawalMethods = <WithdrawalMethod>[].obs;
  final selectedAccount = Rxn<String>();
  final selectedBankAccount = Rxn<String>();
  final selectedCryptoAccount = Rxn<String>();
  final withdrawalAmount = ''.obs;
  final selectedPaymentMethod = ''.obs;
  final selectedWithdrawalMethod =
      Rxn<
        WithdrawalMethod
      >(); // Add this to hold the complete withdrawal method object
  final isOtpSent = false.obs;
  final isOtpLoading = false.obs;

  var userMT5Accounts = <MT5Account>[].obs;
  var wallet = Rxn<Wallet>();
  var ibAccount = Rxn<IbAccount>();
  var withdrawalMethodDetail = Rxn<WithdrawalMethodDetailResponse>();

  @override
  void onInit() {
    super.onInit();
    fetchWithdrawalAccounts();
  }

  Future<void> fetchWithdrawalAccounts() async {
    try {
      _setLoading(true);
      _clearError();

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: ApiConstants.withdrawalRequest,
        token: token,
      );

      if (response.success && response.data != null) {
        final data = response.data;
        final withdrawalMethodResponse = WithdrawalMethodResponse.fromJson(
          data,
        );
        if (withdrawalMethodResponse.status &&
            withdrawalMethodResponse.data.isNotEmpty) {
          withdrawalMethods.assignAll(withdrawalMethodResponse.data);

          print("Loaded ${withdrawalMethods.length} withdrawal methods");

          // Auto-select the first withdrawal method and load its details
          final firstMethod = withdrawalMethodResponse.data.first;
          selectedPaymentMethod.value = firstMethod.methodName ?? '';
          selectedWithdrawalMethod.value =
              firstMethod; // Set the complete withdrawal method object
          print(
            "Auto-selected method: ${firstMethod.methodName} with slug: ${firstMethod.methodSlug}",
          );

          if (firstMethod.methodSlug != null) {
            fetchWithdrawalMethodDetails(firstMethod.methodSlug!);
          }
        } else {
          _errorMessage.value =
              withdrawalMethodResponse.message.isNotEmpty
                  ? withdrawalMethodResponse.message
                  : "Something went wrong";
          CustomToastService.showError(message: _errorMessage.value);
          Get.back();
        }
      } else {
        CustomToastService.showError(
          message: response.message ?? "Something went wrong",
        );
        Get.back();
      }
    } catch (e) {
      _errorMessage.value = "Error while fetching withdrawal methods: $e";

      CustomToastService.showError(message: _errorMessage.value);
      Get.back();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchWithdrawalMethodDetails(String slug) async {
    try {
      _setLoading(true);
      _clearError();

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: "${ApiConstants.withdrawalMethods}$slug",
        token: token,
      );

      print("response is on withdraelae Controller-->${response.data}");
      print("userMT5Accounts length: ${userMT5Accounts.length}");
      print("wallet data: ${wallet.value?.walletBalance}");


      if (response.success && response.data != null) {
        try {
          final data = WithdrawalMethodDetailResponse.fromJson(response.data);
          if (data.status == true) {
            withdrawalMethodDetail.value = data;
            userMT5Accounts.assignAll(data.data?.userMT5Accounts ?? []);
            wallet.value = data.data?.wallet;
            ibAccount.value = data.data?.ibaccount;

            print(
              "After loading - userMT5Accounts length: ${userMT5Accounts.length}",
            );
            print(
              "After loading - wallet balance: ${wallet.value?.walletBalance}",
            );
          } else {
            _errorMessage.value = data.message ?? "Something went wrong";
            // CustomToastService.showError(message: _errorMessage.value);
          }
        } catch (parseError) {
          print("JSON parsing error: $parseError");
          _errorMessage.value = "Error parsing response data";
          // CustomToastService.showError(message: _errorMessage.value);
        }
      } else {
        Get.back();
        CustomToastService.showError(
          message: response.message ?? "Something went wrong",
        );
      }
    } catch (e, t) {
      print(" erorore is on withdraelae Controller-->$t");
      _errorMessage.value =
          "Error while fetching withdrawal method details: $e";
      Get.back();
      CustomToastService.showError(message: _errorMessage.value);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitWithdrawal() async {
    try {
      isOtpLoading.value = true;
      _clearError();

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: ApiConstants.withdrawalSendOTPRequest,
        token: token,
        queryParameters: {
          "account_number": selectedAccount.value ?? '',
          "amount":
              withdrawalAmount.value
                  .replaceFirst('\$', "")
                  .replaceFirst(' ', "")
                  .trim(),
          "withdrawalMethod": selectedPaymentMethod.value,
        },
      );

      if (response.success && response.data != null) {
        final data = response.data;

        // Check if data is a Map (object) and has status field
        if (data is Map<String, dynamic> && data.containsKey('status')) {
          if (data['status'] == true) {
            _successMessage.value = data['message'] ?? "OTP sent successfully";
            CustomToastService.showSuccess(message: _successMessage.value);
            // Set OTP sent flag to show OTP input field
            isOtpSent.value = true;
          } else {
            _errorMessage.value = data['message'] ?? "Failed to send OTP";
            CustomToastService.showError(message: _errorMessage.value);
          }
        } else {
          // Handle case where data is empty array or unexpected format
          _errorMessage.value = "Invalid response format";
          CustomToastService.showError(message: _errorMessage.value);
        }
      } else {
        _errorMessage.value = response.message ?? "Something went wrong";
        CustomToastService.showError(message: _errorMessage.value);
      }
    } catch (e) {
      _errorMessage.value = "Error while submitting withdrawal: $e";
      CustomToastService.showError(message: _errorMessage.value);
    } finally {
      isOtpLoading.value = false;
    }
  }

  // Add withdrawal method (Bank, UPI, Crypto, Local) - Updated to match KYC controller logic
  Future<void> addWithdrawalMethod({
    required String withdrawalMethod, // bank, upi, crypto, local
    required String currency, // USD, INR, etc.
    required String otp,
    required String relationship,
    String? bankHolderName,
    String? bankName,
    String? bankAccountNo,
    String? confirmBankAccountNo,
    String? ifscIban,
    String? bankSwiftCode,
    String? upiHolderName,
    String? upiAddress,
    String? cryptoHolderName,
    String? cryptoAddress,
    String? localHolderName,
    String? proofImagePath, // Path to image file
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final token = await SecureStorageService.getAuthToken();

      // Build request parameters using the same logic as KYC controller
      Map<String, dynamic> requestParams = _buildWithdrawalMethodParams(
        withdrawalMethod: withdrawalMethod,
        currency: currency,
        otp: otp,
        relationship: relationship,
        bankHolderName: bankHolderName,
        bankName: bankName,
        bankAccountNo: bankAccountNo,
        confirmBankAccountNo: confirmBankAccountNo,
        ifscIban: ifscIban,
        bankSwiftCode: bankSwiftCode,
        upiHolderName: upiHolderName,
        upiAddress: upiAddress,
        cryptoHolderName: cryptoHolderName,
        cryptoAddress: cryptoAddress,
        localHolderName: localHolderName,
        proofImagePath: proofImagePath,
      );

      // Use the same approach as KYC controller - always use multipart/form-data
      ApiResponse response;
      if (withdrawalMethod.toLowerCase() == 'local' ||
          proofImagePath == null ||
          proofImagePath.isEmpty) {
        // For local method, use postForm (multipart without file)
        response = await ApiService.postForm(
          endpoint: ApiConstants.withdrawalRequest,
          token: token,
          formData: requestParams,
        );
      } else {
        // For methods requiring file upload, use custom multipart method
        response = await _uploadWithdrawalMethodFile(
          endpoint: ApiConstants.withdrawalRequest,
          token: token,
          file: File(proofImagePath),
          formData: requestParams,
          fileFieldName: _getFileFieldName(withdrawalMethod),
        );
      }

      if (response.success && response.data != null) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('status')) {
          if (data['status'] == true) {
            _successMessage.value =
                data['message'] ?? "Withdrawal method added successfully";
            CustomToastService.showSuccess(message: _successMessage.value);
            // Refresh withdrawal methods list
            await fetchWithdrawalAccounts();
            Get.back();
          } else {
            _errorMessage.value =
                data['message'] ?? "Failed to add withdrawal method";
            CustomToastService.showError(message: _errorMessage.value);
          }
        } else {
          _errorMessage.value = "Invalid response format";
          CustomToastService.showError(message: _errorMessage.value);
        }
      } else {
        _errorMessage.value = response.message ?? "Something went wrong";
        CustomToastService.showError(message: _errorMessage.value);
      }
    } catch (e) {
      _errorMessage.value = "Error while adding withdrawal method: $e";
      CustomToastService.showError(message: _errorMessage.value);
    } finally {
      _setLoading(false);
    }
  }

  // Get OTP for withdrawal method addition
  Future<void> sendWithdrawalMethodOTP() async {
    try {
      isOtpLoading.value = true;
      _clearError();

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint:
            ApiConstants
                .withdrawalSendOTPRequest, // GET /api/user/withdrawal/sendOTP
        token: token,
      );

      if (response.success && response.data != null) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('status')) {
          if (data['status'] == true) {
            isOtpSent.value = true;
            CustomToastService.showSuccess(
              message: data['message'] ?? "OTP sent successfully",
            );
          } else {
            _errorMessage.value = data['message'] ?? "Failed to send OTP";
            CustomToastService.showError(message: _errorMessage.value);
          }
        } else {
          _errorMessage.value = "Invalid response format";
          CustomToastService.showError(message: _errorMessage.value);
        }
      } else {
        _errorMessage.value = response.message ?? "Something went wrong";
        CustomToastService.showError(message: _errorMessage.value);
      }
    } catch (e) {
      _errorMessage.value = "Error while sending OTP: $e";
      CustomToastService.showError(message: _errorMessage.value);
    } finally {
      isOtpLoading.value = false;
    }
  }

  // Helper method to get the correct file field name based on withdrawal method
  String _getFileFieldName(String withdrawalMethod) {
    // Use the same field name as KYC controller
    return 'deposit_proof';
  }

  // Build withdrawal method request parameters - Based on KYC controller logic
  Map<String, dynamic> _buildWithdrawalMethodParams({
    required String withdrawalMethod,
    required String currency,
    required String otp,
    required String relationship,
    String? bankHolderName,
    String? bankName,
    String? bankAccountNo,
    String? confirmBankAccountNo,
    String? ifscIban,
    String? bankSwiftCode,
    String? upiHolderName,
    String? upiAddress,
    String? cryptoHolderName,
    String? cryptoAddress,
    String? localHolderName,
    String? proofImagePath,
  }) {
    final params = <String, dynamic>{};

    // Add conditional parameters based on withdrawal method
    if (withdrawalMethod.toLowerCase() == "bank") {
      params.addAll({
        "ifsc_iban": ifscIban ?? '',
        "bank_name": bankName ?? '',
        "bank_holder_name": bankHolderName ?? '',
        "bank_account_no": bankAccountNo ?? '',
        "confirm_bank_account_no": confirmBankAccountNo ?? '',
        "swift_code": bankSwiftCode ?? '',
        "optradio": "IFSC", // Default to IFSC
      });
    } else if (withdrawalMethod.toLowerCase() == "crypto") {
      params.addAll({
        "crypto_holder_name": cryptoHolderName ?? '',
        "crypto_address": cryptoAddress ?? '',
      });
    } else if (withdrawalMethod.toLowerCase() == "upi") {
      params.addAll({
        "upi_holder_name": upiHolderName ?? '',
        "upi_address": upiAddress ?? '',
      });
    } else if (withdrawalMethod.toLowerCase() == "local") {
      params.addAll({"local_holder_name": localHolderName ?? ''});
    }

    // Add common parameters - matching KYC controller structure
    params.addAll({
      "withdrawal_method": withdrawalMethod.toLowerCase(),
      "selectedMethod":
          withdrawalMethod.toLowerCase(), // Must match withdrawal_method
      "currency": currency,
      "belogns_to":
          "", // Note: keeping the typo as it appears in KYC controller
      "relationship": relationship,
      "holder_name":
          bankHolderName ??
          upiHolderName ??
          cryptoHolderName ??
          localHolderName ??
          '',
      "otp": otp,
    });

    // Add proof file path if provided
    if (proofImagePath != null && proofImagePath.isNotEmpty) {
      params['deposit_proof'] = proofImagePath;
    }

    return params;
  }

  // Custom method for uploading withdrawal method files with correct field names
  Future<ApiResponse> _uploadWithdrawalMethodFile({
    required String endpoint,
    required File file,
    required Map<String, dynamic> formData,
    required String fileFieldName,
    String? token,
  }) async {
    try {
      // If no token provided, try to get from secure storage
      String? authToken = token;
      if (authToken == null) {
        authToken = await SecureStorageService.getAuthToken();
      }

      final headers = {
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request =
          http.MultipartRequest('POST', uri)
            ..headers.addAll(headers)
            ..fields.addAll(
              formData.map((key, value) => MapEntry(key, value.toString())),
            );

      // Check if file exists and is readable
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty: ${file.path}');
      }

      // Add file with the correct field name for withdrawal methods
      request.files.add(
        await http.MultipartFile.fromPath(
          fileFieldName, // Use the correct field name (bank_proof_img, upi_proof_img, etc.)
          file.path,
        ),
      );

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      // Check for 401 status code
      if (response.statusCode == 401) {
        return ApiResponse(success: false, message: 'Unauthorized', data: null);
      }

      // Parse response
      try {
        final responseData = jsonDecode(response.body);
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: responseData['message'] ?? 'Request completed',
          data: responseData,
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          message: 'Invalid response format: $e',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Upload failed: $e',
        data: null,
      );
    }
  }

  Future<void> submitWithdrawalWithOtp(String otp) async {
    try {
      _setLoading(true);
      _clearError();

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.post(
        endpoint: ApiConstants.withdrawalSubmitRequest,
        token: token,
        data: {
          // "withdrawal_method_id":
          // selectedWithdrawalMethod.value?.methodName ?? 1,
          "amount": withdrawalAmount.value,
          "currency": "USD",
          "otp": otp,
          "mt5_account_id": selectedAccount.value ?? '',
        },
      );

      if (response.success && response.data != null) {
        final data = response.data;

        // Check if data is a Map (object) and has status field
        if (data is Map<String, dynamic> && data.containsKey('status')) {
          if (data['status'] == true) {
            _successMessage.value =
                data['message'] ?? "Withdrawal submitted successfully";
            CustomToastService.showSuccess(message: _successMessage.value);
            // Reset OTP sent flag
            isOtpSent.value = false;
            // Navigate back or to success screen
            Get.back();
          } else {
            _errorMessage.value = data['message'] ?? "Withdrawal failed";
            CustomToastService.showError(message: _errorMessage.value);
          }
        } else {
          // Handle case where data is empty array or unexpected format
          _errorMessage.value = "Invalid response format";
          CustomToastService.showError(message: _errorMessage.value);
        }
      } else {
        _errorMessage.value = response.message ?? "Something went wrong";
        CustomToastService.showError(message: _errorMessage.value);
      }
    } catch (e) {
      _errorMessage.value = "Error while submitting withdrawal: $e";
      CustomToastService.showError(message: _errorMessage.value);
    } finally {
      _setLoading(false);
    }
  }

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
