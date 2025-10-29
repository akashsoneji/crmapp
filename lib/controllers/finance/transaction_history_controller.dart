import 'package:get/get.dart';
import '../../constants/api_const.dart';
import '../../models/mt5_account.dart';
import '../../services/api_service.dart';
import '../../services/secure_storage_service.dart';
import '../../widgets/custom_toast.dart';

// Transaction Model
class Transaction {
  String? message;
  bool? success;
  List<Data>? data;
  Pagination? pagination;

  Transaction({this.message, this.success, this.data, this.pagination});

  Transaction.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    success = json['success'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    pagination =
        json['pagination'] != null
            ? new Pagination.fromJson(json['pagination'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

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
    createdAt = json['created_at']?.toString();
    transactionType = json['transaction_type']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['mt5_account_id'] = this.mt5AccountId;
    data['reference_number'] = this.referenceNumber;
    data['amount'] = this.amount;
    data['transaction_id'] = this.transactionId;
    data['status'] = this.status;
    data['paymentMethod'] = this.paymentMethod;
    data['proof'] = this.proof;
    data['proof_url'] = this.proofUrl;
    data['payment_details'] = this.paymentDetails;
    data['created_at'] = this.createdAt;
    data['transaction_type'] = this.transactionType;
    return data;
  }
}

class Pagination {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  String? nextPageUrl;
  String? prevPageUrl;

  Pagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  Pagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    lastPage = json['last_page'];
    perPage = json['per_page'];
    total = json['total'];
    nextPageUrl = json['next_page_url'];
    prevPageUrl = json['prev_page_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['current_page'] = this.currentPage;
    data['last_page'] = this.lastPage;
    data['per_page'] = this.perPage;
    data['total'] = this.total;
    data['next_page_url'] = this.nextPageUrl;
    data['prev_page_url'] = this.prevPageUrl;
    return data;
  }
}

class TransactionHistoryController extends GetxController {
  // Observable states
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _successMessage = ''.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get successMessage => _successMessage.value;

  // Transactions list
  var accounts = <MT5Account>[].obs;
  // Filters
  final selectedAccount = Rxn<String>();
  final selectedDate = Rxn<DateTime>();
  final selectedTransactionType = Rxn<String>();
  final selectedTransactionIndex = (-1).obs;

  // For pagination
  var currentPage = 1;
  var lastPage = 1;

  // Transactions list from /api/user/transactions
  var userTransactions = <Data>[].obs;

  bool get isLoadingMore => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    // fetchTransactionHistory(); // call API on screen load
    // fetchUserTransactions(page: 1);
  }

  /// Fetch transaction history
  Future<void> fetchTransactionHistory() async {
    try {
      _setLoading(true);
      _clearError();

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: ApiConstants.getMT5Accounts, // replace with actual endpoint
        token: token,
      );

      if (response.success) {
        final data = response.data;
        print('MT5 Accounts Response: $data');

        if (data['status'] == true && data['data'] != null) {
          final accountsData = data['data'] as List;
          print(': Found ${accountsData.length} accounts in response');

          if (accountsData.isNotEmpty) {
            // User has MT5 accounts
            final parsedAccounts =
                accountsData
                    .map((account) => MT5Account.fromJson(account))
                    .toList();
            accounts.assignAll(parsedAccounts);
            print(
              ': Updated mt5Accounts observable with ${accounts.length} accounts',
            );
          } else {
            // User has no MT5 accounts - redirect to account opening
            print('User has no MT5 accounts - redirecting to account opening');
          }
        } else {
          // API returned error or no data
          print('MT5 accounts API error: ${data['message']}');
          CustomToastService.showError(
            message: data['message'] ?? "Something went wrong",
          );
        }
      } else {
        // API call failed
        print('Failed to fetch MT5 accounts: ${response.message}');
        CustomToastService.showError(
          message: response.message ?? "Something went wrong",
        );
      }
    } catch (e) {
      _errorMessage.value = "Error while fetching transactions: $e";
      CustomToastService.showError(message: _errorMessage.value);
    } finally {
      _setLoading(false);
    }
  }

  /// Apply filters
  void updateAccount(String account) {
    selectedAccount.value = account;
    // you can re-filter transactions here or trigger API again
  }

  Future<void> fetchUserTransactions({int page = 1}) async {
    try {
      _setLoading(true);
      if (page == 1) userTransactions.clear();

      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.get(
        endpoint: ApiConstants.getTransactions,
        token: token,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // parse response using Transaction model
        final transactionResponse = Transaction.fromJson(data);

        // update pagination info
        currentPage = transactionResponse.pagination?.currentPage ?? 1;
        lastPage = transactionResponse.pagination?.lastPage ?? 1;

        // update transactions list
        if (transactionResponse.data != null) {
          if (page == 1) {
            userTransactions.assignAll(transactionResponse.data!);
          } else {
            userTransactions.addAll(transactionResponse.data!);
          }
        }
        print("respone of userTransactions ${userTransactions.length}");
        // _successMessage.value = transactionResponse.message ?? "Transactions fetched successfully";
      } else {
        _errorMessage.value =
            response.message ?? "Failed to fetch user transactions";
        CustomToastService.showError(message: _errorMessage.value);
      }
    } catch (e, t) {
      print('ERROR $t');
      _errorMessage.value = "Error while fetching user transactions: $e";
      CustomToastService.showError(message: _errorMessage.value);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadNextPage() async {
    if (currentPage < lastPage && !isLoadingMore) {
      await fetchUserTransactions(page: currentPage + 1);
    }
  }

  void updateDate(DateTime date) {
    selectedDate.value = date;
  }

  void updateTransactionType(String type) {
    selectedTransactionType.value = type;
  }

  void selectTransaction(int index) {
    selectedTransactionIndex.value = index;
  }

  void goBack() {
    selectedTransactionIndex.value = -1;
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
