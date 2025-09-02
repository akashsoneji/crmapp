import 'package:get/get.dart';
import 'package:pipze/models/account_models.dart';
import 'package:pipze/models/mt5_account.dart';
import 'package:pipze/controllers/dashboard_controller.dart';
import '../services/account_service.dart';

class AccountController extends GetxController {
  final AccountService _accountService = Get.find<AccountService>();
  late final DashboardController _dashboardController;

  // Observable states
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _accounts = <AccountModel>[].obs;
  final _activeAccount = Rxn<AccountModel>();
  final _successMessage = ''.obs;

  // MT5 Account integration
  final _mt5Accounts = <MT5Account>[].obs;
  final _activeMT5Account = Rxn<MT5Account>();

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  List<AccountModel> get accounts => _accounts;
  AccountModel? get activeAccount => _activeAccount.value;
  String get successMessage => _successMessage.value;

  // MT5 Account getters
  List<MT5Account> get mt5Accounts => _mt5Accounts;
  MT5Account? get activeMT5Account => _activeMT5Account.value;
  List<MT5Account> get realMT5Accounts =>
      _mt5Accounts.where((account) => account.isRealAccount).toList();
  List<MT5Account> get demoMT5Accounts =>
      _mt5Accounts.where((account) => account.isDemoAccount).toList();
  MT5Account? get primaryMT5Account {
    try {
      return _mt5Accounts.firstWhere((account) => account.isPrimaryAccount);
    } catch (e) {
      return _mt5Accounts.isNotEmpty ? _mt5Accounts.first : null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _dashboardController = Get.put(DashboardController());
    loadAccounts();
    _syncWithMT5Accounts();
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

  // MT5 Account Integration Methods

  // Sync with MT5 accounts from dashboard controller
  void _syncWithMT5Accounts() {
    // Listen to MT5 accounts changes from dashboard controller
    ever(_dashboardController.mt5Accounts, (List<MT5Account> mt5Accounts) {
      _mt5Accounts.assignAll(mt5Accounts);
      _updateActiveMT5Account();
    });

    // Initial sync
    _mt5Accounts.assignAll(_dashboardController.mt5Accounts);
    _updateActiveMT5Account();
  }

  // Update active MT5 account based on primary account
  void _updateActiveMT5Account() {
    final primaryAccount = primaryMT5Account;
    if (primaryAccount != null) {
      _activeMT5Account.value = primaryAccount;
    } else if (_mt5Accounts.isNotEmpty) {
      _activeMT5Account.value = _mt5Accounts.first;
    } else {
      _activeMT5Account.value = null;
    }
  }

  // Set active MT5 account (this will call dashboard controller's changePrimaryAccount)
  Future<void> setActiveMT5Account(String accountNumber) async {
    try {
      _setLoading(true);
      _clearError();

      // Call dashboard controller's method to change primary account
      await _dashboardController.changePrimaryAccount(accountNumber);

      // Update local active account
      final account = _mt5Accounts.firstWhereOrNull(
        (acc) => acc.metaAccountNumber == accountNumber,
      );
      if (account != null) {
        _activeMT5Account.value = account;
      }

      _setSuccess('Account switched successfully');
    } catch (e) {
      _setError('Failed to switch account: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Convert MT5 account to AccountModel for compatibility
  AccountModel? convertMT5ToAccountModel(MT5Account mt5Account) {
    try {
      return AccountModel(
        id: mt5Account.metaAccountNumber,
        type: mt5Account.isRealAccount ? 'REAL' : 'DEMO',
        balance: double.tryParse(mt5Account.balance) ?? 0.0,
        currency: 'USD', // Default currency
        isActive: mt5Account.isPrimaryAccount,
        createdAt: DateTime.now(), // You might want to get this from API
        metadata: {
          'mt5_account': true,
          'account_type': mt5Account.accountType,
          'master_group_id': mt5Account.masterGroupId,
          'leverage_id': mt5Account.leverageId,
          'equity': mt5Account.equity,
          'margin': mt5Account.margin,
          'free_margin': mt5Account.freeMargin,
          'profit': mt5Account.profit,
        },
      );
    } catch (e) {
      print('Error converting MT5 account to AccountModel: $e');
      return null;
    }
  }

  // Get all accounts (both local and MT5) as AccountModel list
  List<AccountModel> getAllAccountsAsModels() {
    final List<AccountModel> allAccounts = List.from(_accounts);

    // Add MT5 accounts as AccountModel
    for (final mt5Account in _mt5Accounts) {
      final accountModel = convertMT5ToAccountModel(mt5Account);
      if (accountModel != null) {
        allAccounts.add(accountModel);
      }
    }

    return allAccounts;
  }

  // Refresh both local accounts and MT5 accounts
  Future<void> refreshAllAccounts() async {
    await loadAccounts();
    await _dashboardController.refreshMT5Accounts();
  }
}
