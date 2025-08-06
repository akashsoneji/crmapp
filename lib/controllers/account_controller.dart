import 'package:get/get.dart';
import 'package:pipze/models/account_models.dart';
import '../services/account_service.dart';

class AccountController extends GetxController {
  final AccountService _accountService = Get.find<AccountService>();

  // Observable states
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _accounts = <AccountModel>[].obs;
  final _activeAccount = Rxn<AccountModel>();
  final _successMessage = ''.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  List<AccountModel> get accounts => _accounts;
  AccountModel? get activeAccount => _activeAccount.value;
  String get successMessage => _successMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    try {
      _setLoading(true);
      _clearError();

      final accounts = await _accountService.getAccounts();
      final activeAccount = await _accountService.getActiveAccount();

      _accounts.value = accounts;
      _activeAccount.value = activeAccount;
    } catch (e) {
      _setError('Failed to load accounts: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setActiveAccount(String accountId) async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.setActiveAccount(accountId);

      // Reload accounts to get updated data
      await loadAccounts();

      _setSuccess('Account switched successfully');
    } catch (e) {
      _setError('Failed to set active account: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAccount(AccountModel account) async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.addAccount(account);
      await loadAccounts();

      _setSuccess('Account added successfully');
    } catch (e) {
      _setError('Failed to add account: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAccount(AccountModel account) async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.updateAccount(account);
      await loadAccounts();

      _setSuccess('Account updated successfully');
    } catch (e) {
      _setError('Failed to update account: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.deleteAccount(accountId);
      await loadAccounts();

      _setSuccess('Account deleted successfully');
    } catch (e) {
      _setError('Failed to delete account: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.updateAccountBalance(accountId, newBalance);
      await loadAccounts();

      _setSuccess('Account balance updated successfully');
    } catch (e) {
      _setError('Failed to update account balance: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshAccounts() async {
    await loadAccounts();
  }

  Future<void> resetToDefaultAccounts() async {
    try {
      _setLoading(true);
      _clearError();

      await _accountService.resetToDefaultAccounts();
      await loadAccounts();

      _setSuccess('Accounts reset to default');
    } catch (e) {
      _setError('Failed to reset accounts: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String error) {
    _errorMessage.value = error;
    if (error.isNotEmpty) {
      Get.snackbar('Error', error, snackPosition: SnackPosition.TOP);
    }
  }

  void _setSuccess(String message) {
    _successMessage.value = message;
    if (message.isNotEmpty) {
      Get.snackbar('Success', message, snackPosition: SnackPosition.TOP);
    }
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void clearMessages() {
    _errorMessage.value = '';
    _successMessage.value = '';
  }
}
