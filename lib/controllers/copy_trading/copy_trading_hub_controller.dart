import 'package:crm_app/constants/api_const.dart';
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
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final res = await ApiService.get(
      endpoint: ApiConstants.copyTradingCopierSubscriptions,
      queryParameters: {'_t': timestamp.toString()},
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
      final isActive = e['is_active'];
      return status == 'active' || isActive == true;
    });
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

