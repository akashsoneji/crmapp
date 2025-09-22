// WithdrawalMethodDetailResponse model
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

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
      data: json['data'] != null ? WithdrawalMethodDetailData.fromJson(json['data']) : null,
    );
  }
}

class WithdrawalMethodDetailData {
  final WithdrawalMethod? withdrawalMethod;
  final List<dynamic>? userWithdrawalMethods;
  final List<MT5Account>? userMT5Accounts;
  final Wallet? wallet;
  final IbAccount? ibaccount;

  WithdrawalMethodDetailData({this.withdrawalMethod, this.userWithdrawalMethods, this.userMT5Accounts, this.wallet, this.ibaccount});

  factory WithdrawalMethodDetailData.fromJson(Map<String, dynamic> json) {
    return WithdrawalMethodDetailData(
      withdrawalMethod: json['withdrawalMethod'] != null ? WithdrawalMethod.fromJson(json['withdrawalMethod']) : null,
      userWithdrawalMethods: json['userWithdrawalMethods'] ?? [],
      userMT5Accounts: json['userMT5Accounts'] != null
          ? List<MT5Account>.from(json['userMT5Accounts'].map((x) => MT5Account.fromJson(x)))
          : [],
      wallet: json['wallet'] != null ? Wallet.fromJson(json['wallet']) : null,
      ibaccount: json['ibaccount'] != null ? IbAccount.fromJson(json['ibaccount']) : null,
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
      id: json['id'],
      walletId: json['wallet_id'],
      walletStatus: json['wallet_status'],
      walletBalance: json['wallet_balance'],
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
      id: json['id'],
      promotionTool: json['promotion_tool'],
      status: json['status'],
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
      data: (json['data'] as List<dynamic>?)
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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      methodName: json['method_name']?.toString(),
      methodSlug: json['method_slug']?.toString(),
      averageLabel: json['average_label']?.toString(),
      uptoLabel: json['upto_label']?.toString(),
      minLimit: json['min_limit']?.toString(),
      maxLimit: json['max_limit']?.toString(),
      fees: json['fees']?.toString(),
      status: json['status']?.toString(),
      updatedBy: json['updated_by'] is int
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
        final withdrawalMethodResponse = WithdrawalMethodResponse.fromJson(data);
        if (withdrawalMethodResponse.status && withdrawalMethodResponse.data.isNotEmpty) {
          withdrawalMethods.assignAll(withdrawalMethodResponse.data);
        } else {

          _errorMessage.value = withdrawalMethodResponse.message.isNotEmpty
              ? withdrawalMethodResponse.message
              : "Something went wrong";
          CustomToastService.showError(message: _errorMessage.value);
          Get.back();
        }
      } else {

        CustomToastService.showError(
            message: response.message ?? "Something went wrong");
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

      if (response.success && response.data != null) {
        final data = WithdrawalMethodDetailResponse.fromJson(response.data);
        if (data.status == true) {
          withdrawalMethodDetail.value = data;
          userMT5Accounts.assignAll(data.data?.userMT5Accounts ?? []);
          wallet.value = data.data?.wallet;
          ibAccount.value = data.data?.ibaccount;
        } else {
          _errorMessage.value = data.message ?? "Something went wrong";
          CustomToastService.showError(message: _errorMessage.value);

        }
      } else {
        CustomToastService.showError(message: response.message ?? "Something went wrong");
      }
    } catch (e) {
      _errorMessage.value = "Error while fetching withdrawal method details: $e";
      Get.back();
      CustomToastService.showError(message: _errorMessage.value);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitWithdrawal() async {
    try {
      _setLoading(true);
      _clearError();

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.post(
        endpoint: ApiConstants.withdrawalSendOTPRequest,
        token: token,
        data: {
          "account_number": selectedAccount.value ?? '',
          "amount": withdrawalAmount.value,
          "withdrawalMethod": selectedPaymentMethod.value,
        },
      );

      if (response.success && response.data != null) {
        final data = response.data;
        if (data['status'] == true) {
          _successMessage.value = data['message'] ?? "Withdrawal successful";
          CustomToastService.showSuccess(message: _successMessage.value);
        } else {
          _errorMessage.value = data['message'] ?? "Withdrawal failed";
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