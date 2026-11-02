import '../../constants/api_const.dart';
import '../../services/api_service.dart';
import '../../services/secure_storage_service.dart';
import '../../widgets/custom_toast.dart';
import '../../utils/precision_helper.dart';
import '../../controllers/app_notification_controller.dart';
import '../../services/crm_settings_service.dart';
import '../../services/language_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:crm_app/screens/home/more/finance/deposit_screen.dart';

// --- Models ---
class WalletResponse {
  final bool status;
  final String message;
  final List<UserMT5Account> userMT5Accounts;
  final Wallet wallet;
  final IbAccount ibAccount;
  final IbmWallet? ibmWallet;

  WalletResponse({
    required this.status,
    required this.message,
    required this.userMT5Accounts,
    required this.wallet,
    required this.ibAccount,
    this.ibmWallet,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    // `data` can come back as a non-map (e.g. empty list) on error responses.
    final rawData = json['data'];
    final Map<String, dynamic> data =
        rawData is Map<String, dynamic> ? rawData : {};
    final ibaccountData = data['ibaccount'];
    final ibmWalletData = data['ibmWallet'];

    return WalletResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? "",
      userMT5Accounts:
          (data['userMT5Accounts'] as List? ?? [])
              .map((e) => UserMT5Account.fromJson(e))
              .toList(),
      wallet: Wallet.fromJson(
        data['wallet'] is Map<String, dynamic> ? data['wallet'] : {},
      ),
      ibAccount:
          ibaccountData is Map<String, dynamic>
              ? IbAccount.fromJson(ibaccountData)
              : IbAccount(
                id: 0,
                promotionTool: "",
                status: "",
                referenceLinkId: "",
              ),
      ibmWallet: ibmWalletData is Map<String, dynamic>
          ? IbmWallet.fromJson(ibmWalletData)
          : null,
    );
  }
}

class IbmWallet {
  final int id;
  final String referenceLinkId;
  final String balance;
  final String currency;

  IbmWallet({
    required this.id,
    required this.referenceLinkId,
    required this.balance,
    required this.currency,
  });

  factory IbmWallet.fromJson(Map<String, dynamic> json) {
    return IbmWallet(
      id: json['id'] ?? 0,
      referenceLinkId: json['reference_link_id']?.toString() ?? '',
      balance: json['balance']?.toString() ?? '0.0',
      currency: json['currency']?.toString() ?? 'USD',
    );
  }
}

class UserMT5Account {
  final int id;
  final String metaAccountNumber;
  final String metaAccountName;
  final String masterGroupId;
  final String balance;
  final double? availableForTransfer;

  UserMT5Account({
    required this.id,
    required this.metaAccountNumber,
    required this.metaAccountName,
    required this.masterGroupId,
    required this.balance,
    this.availableForTransfer,
  });

  factory UserMT5Account.fromJson(Map<String, dynamic> json) {
    final raw = json['available_for_transfer'];
    return UserMT5Account(
      id: json['id'] ?? 0,
      metaAccountNumber: json['meta_account_number']?.toString() ?? '',
      metaAccountName: json['meta_account_name']?.toString() ?? '',
      masterGroupId: json['master_group_id']?.toString() ?? '',
      balance: json['balance']?.toString() ?? '0.0',
      availableForTransfer: raw is num
          ? raw.toDouble()
          : (raw is String ? double.tryParse(raw) : null),
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
      walletId: json['wallet_id']?.toString() ?? '',
      walletStatus: json['wallet_status']?.toString() ?? '',
      walletBalance: json['wallet_balance']?.toString() ?? '0.0',
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
      promotionTool: json['promotion_tool']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      referenceLinkId: json['reference_link_id']?.toString() ?? '',
    );
  }
}

// Transaction list models
class Data {
  String? id;
  int? userId;
  String? mt5AccountId;
  String? referenceNumber;
  String? amount;
  String? transactionId;
  String? status;
  String? paymentMethod;
  String? proof;
  String? proofUrl;
  String? paymentDetails;
  String? createdAt;
  String? transactionType;
  String? type;

  Data({
    this.id,
    this.userId,
    this.mt5AccountId,
    this.referenceNumber,
    this.amount,
    this.transactionId,
    this.status,
    this.paymentMethod,
    this.proof,
    this.proofUrl,
    this.paymentDetails,
    this.createdAt,
    this.transactionType,
    this.type,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    userId =
        json['user_id'] is int
            ? json['user_id']
            : int.tryParse(json['user_id']?.toString() ?? '');
    mt5AccountId = json['mt5_account_id']?.toString();
    referenceNumber = json['reference_number']?.toString();
    amount = json['amount']?.toString();
    transactionId = json['transaction_id']?.toString();
    status = json['status']?.toString();
    paymentMethod = json['paymentMethod']?.toString();
    proof = json['proof']?.toString();
    proofUrl = json['proof_url']?.toString();
    paymentDetails = json['payment_details']?.toString();
    createdAt = json['created_at_iso']?.toString() ?? json['created_at']?.toString();
    transactionType = json['transaction_type']?.toString();
    type = json['type']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['mt5_account_id'] = mt5AccountId;
    data['reference_number'] = referenceNumber;
    data['amount'] = amount;
    data['transaction_id'] = transactionId;
    data['status'] = status;
    data['paymentMethod'] = paymentMethod;
    data['proof'] = proof;
    data['proof_url'] = proofUrl;
    data['payment_details'] = paymentDetails;
    data['created_at'] = createdAt;
    data['transaction_type'] = transactionType;
    data['type'] = type;
    return data;
  }
}

class WalletController extends GetxController {
  var walletId = 'PIPW008'.obs;
  var balance = ''.obs;
  var transferFromAccount = ''.obs;
  var transferToAccount = ''.obs;
  var amount = ''.obs;
  var isLoading = false.obs;
  var showTransferFromDropdown = false.obs;
  final RxBool isOtpSent = false.obs;
  final RxBool isOtpLoading = false.obs;
  final RxBool isTransferLoading = false.obs;
  final RxString otpMessage = ''.obs;
  final Rx<UserMT5Account?> selectedFromAccount = Rxn<UserMT5Account>();
  final Rx<String?> selectedFromAccountType =
      Rxn<String>(); // 'mt5', 'wallet', 'ib'
  final Rx<String?> selectedToAccountType =
      Rxn<String>(); // 'mt5', 'wallet', 'ib'
  final Rx<dynamic> selectedToAccount =
      Rxn<dynamic>(); // Can be UserMT5Account, Wallet, or String for IB

  // Observables for parsed wallet data
  var mt5Accounts = <UserMT5Account>[].obs;
  var wallet = Rxn<Wallet>();
  var ibAccount = Rxn<IbAccount>();
  var ibmWallet = Rxn<IbmWallet>();

  // History & pagination state
  static const int _historyPerPage = 10;
  int _historyRequestId = 0;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  var currentPage = 1.obs;
  var lastPage = 1.obs;
  var isHistoryLoading = false.obs;

  final completedTransactions = <WalletHistoryEntry>[].obs;
  final pendingTransactions = <WalletHistoryEntry>[].obs;
  final rejectedTransactions = <WalletHistoryEntry>[].obs;
  final selectedHistoryTab = WalletHistoryTab.completed.obs;

  RxList<WalletHistoryEntry> get visibleHistoryTransactions {
    switch (selectedHistoryTab.value) {
      case WalletHistoryTab.completed:
        return completedTransactions;
      case WalletHistoryTab.pending:
        return pendingTransactions;
      case WalletHistoryTab.rejected:
        return rejectedTransactions;
    }
  }

  var filterDateFrom = ''.obs;
  var filterDateTo = ''.obs;

  final transferFromController = TextEditingController();
  final transferToController = TextEditingController();
  final amountController = TextEditingController(text: '0.00');

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
  }

  @override
  void onReady() {
    super.onReady();
    fetchWalletData();
    fetchWalletHistory(page: 1);
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
    if (transferFromAccount.value.isEmpty) {
      CustomToastService.showError(
        message: 'Please select Transfer From',
      );
      return;
    }

    final rawText = amountController.text.trim();
    if (rawText.isEmpty) {
      CustomToastService.showError(
        message: 'Please enter amount',
      );
      return;
    }

    final cleanedText = rawText.replaceAll(RegExp(r'[^0-9.]'), '');

    final parsedAmount = PrecisionHelper.parseDouble(cleanedText);
    if (parsedAmount <= 0.0) {
      CustomToastService.showError(
        message: 'Amount must be greater than 0.00',
      );
      return;
    }

    try {
      isLoading.value = true;
      Get.to(() => DepositScreen(accountNumber: ''));
    } catch (e) {
      if (Get.isRegistered<AppNotificationController>()) {
        Get.find<AppNotificationController>().showError(
          message: 'Failed to initiate deposit',
          title: 'Error',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> checkBalance(String accountNumber, double amount) async {
    try {
      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.post(
        endpoint: ApiConstants.checkBalance,
        token: token,
        data: {'account_number': accountNumber, 'amount': amount},
      );

      if (response.success && response.data != null) {
        final responseData = response.data as Map<String, dynamic>?;
        final nestedData = responseData?['data'] as Map<String, dynamic>?;
        final isValid = nestedData?['valid'] ?? false;

        if (!isValid) {
          CustomToastService.showError(
            message: 'Insufficient balance for this transfer',
          );
        }
        return isValid;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Failed to check balance',
        );
        return false;
      }
    } catch (e) {
      CustomToastService.showError(
        message: 'Error checking balance: $e',
      );
      return false;
    }
  }

  Future<bool> sendOTP(String accountNumber) async {
    try {
      isOtpLoading.value = true;
      otpMessage.value = '';

      final token = await SecureStorageService.getAuthToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get(
        endpoint: ApiConstants.withdrawalSendOTPRequest,
        queryParameters: {'_t': timestamp.toString()},
        token: token,
      );

      if (response.success && response.data != null) {
        isOtpSent.value = true;
        otpMessage.value = response.data['message'] ?? 'OTP sent successfully';
        CustomToastService.showSuccess(
          message: 'OTP sent successfully',
        );
        return true;
      } else {
        otpMessage.value = response.message ?? 'Failed to send OTP';
        CustomToastService.showError(
          message: response.message ?? 'Failed to send OTP',
        );
        return false;
      }
    } catch (e) {
      otpMessage.value = 'Error: $e';
      CustomToastService.showError(
        message: 'Error sending OTP: $e',
      );
      return false;
    } finally {
      isOtpLoading.value = false;
    }
  }

  /// [otp] is null when the admin turned `internal_transfer_otp_required`
  /// off, so no `otp` key is sent.
  Future<bool> submitInternalTransfer(
    String? otp,
    String comment,
    String fromAccountId,
    String toAccountId,
    String amount,
  ) async {
    if (otp != null && otp.isEmpty) {
      CustomToastService.showError(
        message: 'Please enter OTP',
      );
      return false;
    }

    if (fromAccountId.isEmpty || toAccountId.isEmpty) {
      CustomToastService.showError(
        message: 'Please select both From and To accounts',
      );
      return false;
    }

    if (amount.isEmpty) {
      CustomToastService.showError(
        message: 'Please enter amount',
      );
      return false;
    }

    try {
      isTransferLoading.value = true;

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.post(
        endpoint: ApiConstants.internalTransferRequest,
        token: token,
        data: {
          'from_account': fromAccountId,
          'to_account': toAccountId,
          'amount': amount,
          'comment': comment,
          if (otp != null) 'otp': otp,
        },
      );

      if (response.success && response.data != null) {
        CustomToastService.showSuccess(
          message: _transferSuccessMessage(response.message),
        );

        await fetchWalletData();
        _resetTransferForm();
        return true;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Transfer failed',
        );
        return false;
      }
    } catch (e) {
      CustomToastService.showError(
        message: 'Error processing transfer: $e',
      );
      return false;
    } finally {
      isTransferLoading.value = false;
    }
  }

  /// With admin approval on, the transfer is only queued, so prefer the
  /// server's wording over "completed".
  String _transferSuccessMessage(String? apiMessage) {
    final approvalRequired = Get.isRegistered<CrmSettingsService>() &&
        (Get.find<CrmSettingsService>()
                .current
                ?.financialSettings
                .internalTransferApprovalRequired ??
            false);
    if (!approvalRequired) return 'Transfer completed successfully';
    final message = apiMessage?.trim() ?? '';
    return message.isNotEmpty
        ? message
        : TranslationUtils.tr('wallet_controller_transfer_sent_for_approval');
  }

  void _resetTransferForm() {
    selectedFromAccount.value = null;
    selectedFromAccountType.value = null;
    selectedToAccount.value = null;
    selectedToAccountType.value = null;
    transferFromAccount.value = '';
    transferToAccount.value = '';
    amountController.clear();
    isOtpSent.value = false;
    otpMessage.value = '';
  }

  bool _validateRequiredFields() {
    if (transferFromAccount.value.isEmpty) {
      CustomToastService.showError(
        message: 'Please select Transfer From',
      );
      return false;
    }

    if (amount.value.isEmpty) {
      CustomToastService.showError(
        message: 'Please Enter amount',
      );
      return false;
    }

    return true;
  }

  Future<void> sendOtp() async {
    try {
      isLoading.value = true;
      if (!_validateRequiredFields()) {
        return;
      }

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: ApiConstants.withdrawalSendOTPRequest,
        token: token,
      );

      if (response.success) {
        print('✅ OTP sent successfully');
        isOtpSent.value = true;
        CustomToastService.showSuccess(message: 'OTP sent');
      } else {
        print('❌ Failed to send OTP: ${response.message}');
        CustomToastService.showError(
          message: response.message ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      print('❌ Error sending OTP: $e');
      CustomToastService.showError(
        message: 'Error sending OTP: $e',
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
    await _waitForBuildToFinish();
    try {
      isLoading.value = true;

      final token = await SecureStorageService.getAuthToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 1. Fetch legacy wallet data (to get mt5Accounts and ibAccount for transfer screen)
      final legacyResponse = await ApiService.get(
        endpoint: ApiConstants.getWalletData,
        queryParameters: {'_t': timestamp.toString()},
        token: token,
      );

      if (legacyResponse.success && legacyResponse.data != null) {
        final parsed = WalletResponse.fromJson(legacyResponse.data);
        mt5Accounts.assignAll(parsed.userMT5Accounts);
        ibAccount.value = parsed.ibAccount;
        ibmWallet.value = parsed.ibmWallet;
        // Fallback wallet & balance
        wallet.value = parsed.wallet;
        balance.value = parsed.wallet.walletBalance;
      }

      // 2. Fetch fresh wallet details from the new api/user/wallet endpoint
      final freshResponse = await ApiService.get(
        endpoint: ApiConstants.getWalletDetailsNew,
        queryParameters: {'_t': timestamp.toString()},
        token: token,
      );

      if (freshResponse.success && freshResponse.data != null) {
        final freshData = freshResponse.data;
        if (freshData['data'] != null) {
          final walletMap = freshData['data'] as Map<String, dynamic>;
          final walletIdStr = walletMap['wallet_id']?.toString() ?? '';
          final balanceStr = walletMap['balance']?.toString() ?? '0.0';

          wallet.value = Wallet(
            id: wallet.value?.id ?? 0,
            walletId: walletIdStr,
            walletStatus: wallet.value?.walletStatus ?? 'active',
            walletBalance: balanceStr,
          );
          balance.value = balanceStr;
          print("Fetched wallet Details: ID = $walletIdStr, Balance = $balanceStr");
        }
      } else {
        print("Failed to fetch fresh wallet details: ${freshResponse.message}");
      }
    } catch (e) {
      print("Error fetching wallet data: $e");
      CustomToastService.showError(
        message: "Error while fetching wallet data: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWalletHistory({int page = 1}) async {
    await _waitForBuildToFinish();

    // Only the newest request may write state; a slow page-1 response must not
    // overwrite results fetched after a filter change.
    final requestId = ++_historyRequestId;
    if (page == 1) {
      isHistoryLoading.value = true;
      isLoadingMore.value = false;
      hasMore.value = true;
      _clearHistoryLists();
    } else {
      isLoadingMore.value = true;
    }

    var loaded = false;
    try {
      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: ApiConstants.getFinanceActivity,
        // Uri.queryParameters only accepts String values.
        queryParameters: {
          'page': page.toString(),
          'perPage': _historyPerPage.toString(),
          'transactionType': '',
          'includeTraderTransfers': '1',
          'type': '',
          'status': '',
          'dateRange': _historyDateRangeParam(),
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        token: token,
      );
      if (requestId != _historyRequestId) return;

      final body = response.data;
      if (!response.success || body is! Map) {
        if (page == 1) hasMore.value = false;
        return;
      }

      final rows = body['data'] is List ? body['data'] as List : const [];
      final pagination =
          body['pagination'] is Map ? body['pagination'] as Map : const {};
      currentPage.value = _toInt(pagination['current_page'], fallback: page);
      lastPage.value =
          _toInt(pagination['last_page'], fallback: currentPage.value);

      for (final row in rows.whereType<Map>()) {
        final entry = WalletHistoryEntry.fromFinanceActivity(
          Map<String, dynamic>.from(row),
        );
        switch (entry.tab) {
          case WalletHistoryTab.completed:
            completedTransactions.add(entry);
            break;
          case WalletHistoryTab.pending:
            pendingTransactions.add(entry);
            break;
          case WalletHistoryTab.rejected:
            rejectedTransactions.add(entry);
            break;
        }
      }

      hasMore.value = rows.isNotEmpty && currentPage.value < lastPage.value;
      loaded = true;
    } catch (e) {
      if (requestId != _historyRequestId) return;
      debugPrint('Error fetching wallet history: $e');
      if (page == 1) hasMore.value = false;
    } finally {
      if (requestId == _historyRequestId) {
        isHistoryLoading.value = false;
        isLoadingMore.value = false;
      }
    }

    if (loaded) _fillVisibleTab();
  }

  /// The finance-activity API filters on `dateRange=YYYY-MM-DD|YYYY-MM-DD`
  /// (same as web); it ignores separate from/to params. Empty = no filter.
  String _historyDateRangeParam() {
    final from = filterDateFrom.value;
    final to = filterDateTo.value;
    if (from.isEmpty && to.isEmpty) return '';
    // Match the date picker bounds (2020-01-01 .. today) for an open side.
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return '${from.isEmpty ? '2020-01-01' : from}|${to.isEmpty ? today : to}';
  }

  int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  void _clearHistoryLists() {
    completedTransactions.clear();
    pendingTransactions.clear();
    rejectedTransactions.clear();
  }

  /// Rows are split into tabs client-side, so a page can add nothing to the
  /// visible tab. Keep paging until it has a screenful or the server runs out,
  /// otherwise the list is too short to scroll and never triggers load-more.
  void _fillVisibleTab() {
    if (visibleHistoryTransactions.length >= _historyPerPage) return;
    loadMoreTransactions();
  }

  void selectHistoryTab(WalletHistoryTab tab) {
    if (selectedHistoryTab.value == tab) return;
    selectedHistoryTab.value = tab;
    _fillVisibleTab();
  }

  void loadMoreTransactions() {
    if (isHistoryLoading.value || isLoadingMore.value || !hasMore.value) {
      return;
    }
    fetchWalletHistory(page: currentPage.value + 1);
  }

  void applyFilters() {
    fetchWalletHistory(page: 1);
  }

  void clearFilters() {
    filterDateFrom.value = '';
    filterDateTo.value = '';
    fetchWalletHistory(page: 1);
  }

  /// Rx writes during the build phase throw "setState() called during build";
  /// callers such as initState/onReady can land there.
  Future<void> _waitForBuildToFinish() async {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      return;
    }
    await SchedulerBinding.instance.endOfFrame;
  }

  void clearAllWalletData() {
    print('WalletController: Clearing all wallet data...');

    mt5Accounts.clear();
    wallet.value = null;
    ibAccount.value = null;
    ibmWallet.value = null;
    balance.value = '';

    selectedFromAccount.value = null;
    transferFromAccount.value = '';
    transferToAccount.value = '';
    amount.value = '';
    amountController.clear();

    isOtpSent.value = false;
    isOtpLoading.value = false;
    isTransferLoading.value = false;
    otpMessage.value = '';

    showTransferFromDropdown.value = false;

    mt5Accounts.refresh();
    wallet.refresh();
    ibAccount.refresh();
    balance.refresh();

    print('WalletController: All wallet data cleared successfully');
  }
}

enum WalletHistoryTab { completed, pending, rejected }

class WalletHistoryEntry {
  final String id;
  final String reference;
  final double amount;
  final String status;
  final String type;
  final String paymentMethod;
  final String account;
  final String reason;
  final DateTime? createdAt;
  final String? direction;

  const WalletHistoryEntry({
    required this.id,
    required this.reference,
    required this.amount,
    required this.status,
    required this.type,
    required this.paymentMethod,
    required this.account,
    required this.reason,
    required this.createdAt,
    this.direction,
  });

  factory WalletHistoryEntry.fromFinanceActivity(Map<String, dynamic> json) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key]?.toString().trim() ?? '';
        if (value.isNotEmpty && value != 'null') return value;
      }
      return '';
    }

    final rawDate = pick(['created_at_iso', 'created_at', 'date']);
    // API sends a formatted display string like "$1,000.00"; keep only the numeric part.
    final rawAmount = pick(['amount']).replaceAll(RegExp(r'[^0-9.\-]'), '');
    final direction = pick(['direction']);

    return WalletHistoryEntry(
      id: pick(['id']),
      reference: pick(['reference_number', 'transaction_id', 'reference']),
      amount: double.tryParse(rawAmount) ?? 0.0,
      status: pick(['status']),
      type: pick(['transaction_type', 'type']),
      paymentMethod: pick(['payment_method', 'paymentMethod', 'method']),
      account: pick(['mt5_account_id', 'account_number', 'account']),
      reason: pick(['reason', 'rejection_reason', 'remark', 'comment']),
      createdAt: DateTime.tryParse(rawDate)?.toLocal(),
      direction: direction.isEmpty ? null : direction.toLowerCase(),
    );
  }

  bool get isCredit {
    if (direction == 'in' || direction == 'credit') return true;
    if (direction == 'out' || direction == 'debit') return false;
    if (amount < 0) return false;
    final normalizedType = type.toLowerCase();
    const debitMarkers = ['withdraw', 'transfer_out', 'debit', 'out'];
    return !debitMarkers.any(normalizedType.contains);
  }

  WalletHistoryTab get tab {
    final normalizedStatus = status.toLowerCase();
    const completed = ['approved', 'completed', 'complete', 'success', 'successful', 'done', 'paid'];
    const rejected = ['rejected', 'failed', 'cancelled', 'canceled', 'declined', 'expired'];
    if (completed.contains(normalizedStatus)) return WalletHistoryTab.completed;
    if (rejected.contains(normalizedStatus)) return WalletHistoryTab.rejected;
    return WalletHistoryTab.pending;
  }
}
