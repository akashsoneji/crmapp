import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/models/ib_models.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/widgets/custom_toast.dart';

class IBController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // IB Status
  final Rx<IBStatusResponse?> ibStatusResponse = Rxn<IBStatusResponse>();

  // IB Dashboard
  final Rx<IBDashboardResponse?> ibDashboardResponse = Rxn<IBDashboardResponse>();

  // IB Clients
  final RxList<IBClient> ibClients = <IBClient>[].obs;

  // IB Sub-IBs
  final RxList<IBClient> ibSubIBs = <IBClient>[].obs;

  // IB Trade History
  final RxList<IBTradeHistory> ibTradeHistory = <IBTradeHistory>[].obs;

  // IB Stats
  final Rx<IBStatsData?> ibStats = Rxn<IBStatsData>();

  /// Get IB Status
  Future<IBStatusResponse?> getIBStatus() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get(
        endpoint: ApiConstants.ibStatus,
        queryParameters: {'_t': timestamp.toString()},
      );

      if (response.success && response.data != null) {
        ibStatusResponse.value = IBStatusResponse.fromJson(response.data!);
        return ibStatusResponse.value;
      } else {
        errorMessage.value = response.message ?? 'Failed to get IB status';
        ibStatusResponse.value = null;
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB status: $e';
      ibStatusResponse.value = null;
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit IB Application
  Future<bool> submitIBApplication({required bool termsAccepted}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await ApiService.post(
        endpoint: ApiConstants.ibApplication,
        data: {'terms_accepted': termsAccepted},
      );

      if (response.success && response.data != null) {
        final applicationResponse =
            IBApplicationResponse.fromJson(response.data!);
        if (applicationResponse.status == true) {
          CustomToastService.showSuccess(
            message: applicationResponse.message ??
                'IB application submitted successfully',
          );
          return true;
        } else {
          errorMessage.value =
              applicationResponse.message ?? 'Failed to submit application';
          CustomToastService.showError(message: errorMessage.value);
          return false;
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to submit application';
        CustomToastService.showError(message: errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error submitting IB application: $e';
      CustomToastService.showError(message: errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get IB Dashboard
  Future<IBDashboardResponse?> getIBDashboard() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get(
        endpoint: ApiConstants.ibDashboard,
        queryParameters: {'_t': timestamp.toString()},
      );

      if (response.success && response.data != null) {
        ibDashboardResponse.value =
            IBDashboardResponse.fromJson(response.data!);
        return ibDashboardResponse.value;
      } else {
        errorMessage.value = response.message ?? 'Failed to get IB dashboard';
        ibDashboardResponse.value = null;
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB dashboard: $e';
      ibDashboardResponse.value = null;
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get IB Clients
  Future<List<IBClient>?> getIBClients({int? subIbId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final queryParams = {'_t': timestamp.toString()};
      if (subIbId != null) {
        queryParams['sub_ib_id'] = subIbId.toString();
      }

      final response = await ApiService.get(
        endpoint: ApiConstants.ibClients,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final clientsResponse = IBClientsResponse.fromJson(response.data!);
        ibClients.assignAll(clientsResponse.data ?? []);
        return ibClients;
      } else {
        errorMessage.value = response.message ?? 'Failed to get IB clients';
        ibClients.clear();
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB clients: $e';
      ibClients.clear();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get IB Sub-IBs
  Future<List<IBClient>?> getIBSubIBs({int? subIbId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final queryParams = {'_t': timestamp.toString()};
      if (subIbId != null) {
        queryParams['sub_ib_id'] = subIbId.toString();
      }

      final response = await ApiService.get(
        endpoint: ApiConstants.ibSubIbs,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final subIBsResponse = IBSubIBsResponse.fromJson(response.data!);
        ibSubIBs.assignAll(subIBsResponse.data ?? []);
        return ibSubIBs;
      } else {
        errorMessage.value = response.message ?? 'Failed to get IB Sub-IBs';
        ibSubIBs.clear();
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB Sub-IBs: $e';
      ibSubIBs.clear();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get IB Trade History
  Future<List<IBTradeHistory>?> getIBTradeHistory({int? subIbId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final queryParams = {'_t': timestamp.toString()};
      if (subIbId != null) {
        queryParams['sub_ib_id'] = subIbId.toString();
      }

      final response = await ApiService.get(
        endpoint: ApiConstants.ibTradeHistory,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final tradeHistoryResponse =
            IBTradeHistoryResponse.fromJson(response.data!);
        ibTradeHistory.assignAll(tradeHistoryResponse.data ?? []);
        return ibTradeHistory;
      } else {
        errorMessage.value =
            response.message ?? 'Failed to get IB trade history';
        ibTradeHistory.clear();
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB trade history: $e';
      ibTradeHistory.clear();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get IB Stats
  Future<IBStatsData?> getIBStats({int? subIbId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final queryParams = {'_t': timestamp.toString()};
      if (subIbId != null) {
        queryParams['sub_ib_id'] = subIbId.toString();
      }

      final response = await ApiService.get(
        endpoint: ApiConstants.ibStats,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final statsResponse = IBStatsResponse.fromJson(response.data!);
        ibStats.value = statsResponse.data;
        return ibStats.value;
      } else {
        errorMessage.value = response.message ?? 'Failed to get IB stats';
        ibStats.value = null;
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB stats: $e';
      ibStats.value = null;
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all My Clients data (clients, sub-ibs, trade-history, stats)
  Future<void> loadMyClientsData({int? subIbId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      update(); // Update GetBuilder to show loading state

      // Call all APIs in parallel
      await Future.wait([
        getIBClients(subIbId: subIbId),
        getIBSubIBs(subIbId: subIbId),
        getIBTradeHistory(subIbId: subIbId),
        getIBStats(subIbId: subIbId),
      ]);
    } catch (e) {
      errorMessage.value = 'Error loading My Clients data: $e';
    } finally {
      isLoading.value = false;
      update(); // Update GetBuilder after loading completes
    }
  }

  /// Clear all IB data
  void clearAllData() {
    ibStatusResponse.value = null;
    ibDashboardResponse.value = null;
    ibClients.clear();
    ibSubIBs.clear();
    ibTradeHistory.clear();
    ibStats.value = null;
    errorMessage.value = '';
  }
}

