import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_subscribe_controller.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:get/get.dart';

enum CopyTradingMasterApplicationStatus { none, pending, approved, rejected, unknown }

class CopyTradingHubController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<CopyTradingMasterApplicationStatus> masterStatus =
      CopyTradingMasterApplicationStatus.none.obs;
  final RxString masterCode = ''.obs;

  /// True when the user has at least one active subscription as copier.
  final RxBool hasActiveCopySubscription = false.obs;

  /// Copier eligible accounts (Become Master — pick MT5 account). GET without `plan_id`.
  final RxList<EligibleCopyAccount> masterApplyEligibleAccounts = <EligibleCopyAccount>[].obs;
  final RxBool masterApplyEligibleLoading = false.obs;
  final RxString masterApplyEligibleError = ''.obs;

  /// Become Master form (reactive so UI can enable Apply when complete).
  final Rxn<int> masterApplySelectedAccountId = Rxn<int>();
  final RxString masterApplyNicknameDraft = ''.obs;
  final RxBool masterApplyTermsAccepted = false.obs;

  bool get canSubmitMasterApply {
    if (masterApplyEligibleLoading.value) return false;
    if (masterApplyEligibleAccounts.isEmpty) return false;
    if (masterApplySelectedAccountId.value == null) return false;
    if (masterApplyNicknameDraft.value.trim().isEmpty) return false;
    if (!masterApplyTermsAccepted.value) return false;
    return true;
  }

  void resetMasterApplyForm() {
    masterApplySelectedAccountId.value = null;
    masterApplyNicknameDraft.value = '';
    masterApplyTermsAccepted.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    refreshAll(showLoading: true);
  }

  Future<void> refreshAll({bool showLoading = false}) async {
    if (showLoading) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      await Future.wait([_loadMasterStatus(), _loadCopierSubscriptions()]);
    } catch (e) {
      errorMessage.value = 'Failed to load copy trading status: $e';
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _loadMasterStatus() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final res = await ApiService.get(
      endpoint: ApiConstants.copyTradingMasterStatus,
      queryParameters: {'_t': timestamp.toString()},
    );

    if (!res.success || res.data == null) {
      // Treat "not applied yet" as none, but keep message for debugging.
      masterStatus.value = CopyTradingMasterApplicationStatus.none;
      masterCode.value = '';
      return;
    }

    final data = res.data?['data'];
    if (data is! Map) {
      masterStatus.value = CopyTradingMasterApplicationStatus.unknown;
      masterCode.value = '';
      return;
    }

    final statusStr = (data['status'] ?? '').toString().toLowerCase();
    masterCode.value = (data['master_code'] ?? '').toString();

    switch (statusStr) {
      case 'pending':
        masterStatus.value = CopyTradingMasterApplicationStatus.pending;
        break;
      case 'approved':
      case 'active':
        masterStatus.value = CopyTradingMasterApplicationStatus.approved;
        break;
      case 'rejected':
      case 'declined':
        masterStatus.value = CopyTradingMasterApplicationStatus.rejected;
        break;
      case '':
        masterStatus.value = CopyTradingMasterApplicationStatus.none;
        break;
      default:
        masterStatus.value = CopyTradingMasterApplicationStatus.unknown;
        break;
    }
  }

  Future<void> _loadCopierSubscriptions() async {
    final res = await ApiService.get(
      endpoint: ApiConstants.copyTradingCopierSubscriptionsList(),
    );

    if (!res.success || res.data == null) {
      hasActiveCopySubscription.value = false;
      return;
    }

    final list = res.data?['data'];
    if (list is! List) {
      hasActiveCopySubscription.value = false;
      return;
    }

    hasActiveCopySubscription.value = list.any((e) {
      if (e is! Map) return false;
      final status = (e['status'] ?? '').toString().toLowerCase();
      return status == 'active';
    });
  }

  /// Loads trading accounts from `GET .../copier/eligible-accounts` (`plan_id` optional).
  Future<void> loadEligibleAccountsForMasterApply({bool showLoading = true}) async {
    if (showLoading) masterApplyEligibleLoading.value = true;
    masterApplyEligibleError.value = '';
    try {
      final res = await ApiService.get(
        endpoint: ApiConstants.copyTradingCopierEligibleAccounts,
        queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      if (!res.success || res.data == null) {
        masterApplyEligibleAccounts.clear();
        masterApplyEligibleError.value = res.message ?? 'Failed to load eligible accounts';
        return;
      }
      final raw = res.data?['data'];
      if (raw is! List) {
        masterApplyEligibleAccounts.clear();
        masterApplyEligibleError.value = 'Invalid response';
        return;
      }
      final list =
          raw.whereType<Map>().map((e) => EligibleCopyAccount.fromJson(e.cast<String, dynamic>())).toList();
      masterApplyEligibleAccounts.assignAll(list);
    } catch (e) {
      masterApplyEligibleAccounts.clear();
      masterApplyEligibleError.value = 'Load error: $e';
    } finally {
      if (showLoading) masterApplyEligibleLoading.value = false;
    }
  }

  Future<ApiResponse> applyForMaster({
    required int mt5AccountId,
    required String nickname,
    required bool termsAccepted,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final res = await ApiService.post(
        endpoint: ApiConstants.copyTradingMasterApply,
        data: {
          'mt5_account_id': mt5AccountId,
          'nickname': nickname,
          'terms_accepted': termsAccepted ? 1 : 0,
        },
      );
      if (!res.success) {
        errorMessage.value = res.message ?? 'Failed to submit application';
      } else {
        await refreshAll(showLoading: false);
      }
      return res;
    } catch (e) {
      errorMessage.value = 'Apply error: $e';
      return ApiResponse.error(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }
}

