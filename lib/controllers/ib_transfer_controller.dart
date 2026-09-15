import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/models/ib_transfer_models.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:get/get.dart';

class IbTransferController extends GetxController {
  // Observables
  var isLoadingInit = false.obs;
  var isLoadingHistory = false.obs;
  var isSubmitting = false.obs;
  var isSearching = false.obs;
  var isCancelling = false.obs;

  var initData = Rxn<IbTransferInitResponse>();
  var searchResults = <IbTransferClient>[].obs;
  var historyData = <IbTransferHistoryItem>[].obs;
  var currentHistoryPage = 1.obs;
  var hasMoreHistory = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetching is handled explicitly in the view's initState to ensure
    // it refreshes every time the screen is opened, not just on controller creation.
  }

  Future<void> fetchInitData() async {
    try {
      isLoadingInit.value = true;
      final response = await ApiService.get(
        endpoint: ApiConstants.ibTransferCreate,
      );
      if (response.success && response.data != null) {
        initData.value = IbTransferInitResponse.fromJson(response.data!);
      }
    } catch (e) {
      print('Error fetching IB transfer init: \$e');
    } finally {
      isLoadingInit.value = false;
    }
  }

  Future<void> searchClients(String query) async {
    try {
      isSearching.value = true;
      final response = await ApiService.get(
        endpoint: ApiConstants.ibTransferClientsSearch,
        queryParameters: {'search': query},
      );
      if (response.success && response.data != null) {
        final parsed = IbTransferClientSearchResponse.fromJson(response.data!);
        searchResults.value = parsed.results ?? [];
      }
    } catch (e) {
      print('Error searching clients: \$e');
    } finally {
      isSearching.value = false;
    }
  }

  Future<bool> submitTransfer({
    required int toClientId,
    required double amount,
    String? comment,
  }) async {
    try {
      isSubmitting.value = true;
      final payload = {
        'to_client_user_id': toClientId,
        'amount': amount,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };
      final response = await ApiService.post(
        endpoint: ApiConstants.ibTransferStore,
        data: payload,
      );
      if (response.success) {
        CustomToastService.showSuccess(
          message:
              response.message ??
              Get.find<LanguageService>().tr('ib_transfer_submitted'),
        );
        // Refresh balance and history
        fetchInitData();
        fetchHistory(refresh: true);
        return true;
      } else {
        CustomToastService.showError(
          message:
              response.message ??
              Get.find<LanguageService>().tr('ib_transfer_submit_failed'),
        );
        return false;
      }
    } catch (e) {
      print('Error submitting transfer: \$e');
      CustomToastService.showError(
        message: Get.find<LanguageService>().tr('ib_transfer_submit_error'),
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> fetchHistory({bool refresh = false}) async {
    if (refresh) {
      currentHistoryPage.value = 1;
      hasMoreHistory.value = true;
      historyData.clear();
    }

    if (!hasMoreHistory.value || (isLoadingHistory.value && !refresh)) return;

    try {
      isLoadingHistory.value = true;
      final response = await ApiService.get(
        endpoint: ApiConstants.ibTransferHistory,
        queryParameters: {'page': currentHistoryPage.value},
      );
      if (response.success && response.data != null) {
        final parsed = IbTransferHistoryResponse.fromJson(response.data!);
        final newItems = parsed.data?.data ?? [];

        if (refresh) {
          historyData.value = newItems;
        } else {
          historyData.addAll(newItems);
        }

        if (parsed.data?.nextPageUrl != null) {
          currentHistoryPage.value++;
        } else {
          hasMoreHistory.value = false;
        }
      }
    } catch (e) {
      print('Error fetching IB transfer history: \$e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<bool> cancelTransfer(int transferId) async {
    try {
      isCancelling.value = true;
      final response = await ApiService.post(
        endpoint: '\${ApiConstants.ibTransferCancel}\$transferId/cancel',
      );
      if (response.success) {
        CustomToastService.showSuccess(
          message:
              response.message ??
              Get.find<LanguageService>().tr('ib_transfer_cancelled'),
        );
        fetchHistory(refresh: true);
        fetchInitData();
        return true;
      } else {
        CustomToastService.showError(
          message:
              response.message ??
              Get.find<LanguageService>().tr('ib_transfer_cancel_failed'),
        );
        return false;
      }
    } catch (e) {
      print('Error cancelling transfer: \$e');
      CustomToastService.showError(
        message: Get.find<LanguageService>().tr('ib_transfer_cancel_error'),
      );
      return false;
    } finally {
      isCancelling.value = false;
    }
  }
}
