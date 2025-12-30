import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/models/ib_models.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/widgets/custom_toast.dart';

class IBController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isHistoryLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Selected Sub-IB ID for hierarchy navigation
  int? selectedSubIBId;

  // IB Status
  final Rx<IBStatusResponse?> ibStatusResponse = Rxn<IBStatusResponse>();

  // IB Dashboard
  final Rx<IBDashboardResponse?> ibDashboardResponse =
      Rxn<IBDashboardResponse>();

  // IB Dashboard Data (extracted for easier access)
  final Rx<UserIBDetails?> ibDashboardData = Rxn<UserIBDetails>();

  // IB Clients
  final RxList<IBClient> ibClients = <IBClient>[].obs;

  // IB Sub-IBs
  final RxList<IBClient> ibSubIBs = <IBClient>[].obs;

  // IB Trade History
  final RxList<IBTradeHistory> ibTradeHistory = <IBTradeHistory>[].obs;

  // IB Stats
  final Rx<IBStatsData?> ibStats = Rxn<IBStatsData>();

  // IB Structure
  final Rx<IBStructureData?> ibStructureData = Rxn<IBStructureData>();

  // IB Approval Requests
  final RxList<IBApprovalRequest> ibApprovalRequests =
      <IBApprovalRequest>[].obs;

  /// Get IB Status
  Future<IBStatusResponse?> getIBStatus({bool showLoading = true}) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
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
      if (showLoading) {
        isLoading.value = false;
      }
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
        final applicationResponse = IBApplicationResponse.fromJson(
          response.data!,
        );
        if (applicationResponse.status == true) {
          CustomToastService.showSuccess(
            message:
                applicationResponse.message ??
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
  Future<IBDashboardResponse?> getIBDashboard({bool showLoading = true}) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get(
        endpoint: ApiConstants.ibDashboard,
        queryParameters: {'_t': timestamp.toString()},
      );

      if (response.success && response.data != null) {
        ibDashboardResponse.value = IBDashboardResponse.fromJson(
          response.data!,
        );
        ibDashboardData.value = ibDashboardResponse.value?.data?.userIBDetails;
        update(['ib_dashboard']); // Trigger GetBuilder update with specific ID
        return ibDashboardResponse.value;
      } else {
        errorMessage.value = response.message ?? 'Failed to get IB dashboard';
        ibDashboardResponse.value = null;
        ibDashboardData.value = null;
        update(['ib_dashboard']); // Trigger GetBuilder update with specific ID
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB dashboard: $e';
      ibDashboardResponse.value = null;
      ibDashboardData.value = null;
      return null;
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
      update(['ib_dashboard']); // Trigger GetBuilder update with specific ID
    }
  }

  /// Get IB Clients
  Future<List<IBClient>?> getIBClients({
    int? subIbId,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
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
        update(['ib_clients']); // Trigger GetBuilder update with specific ID
        return ibClients;
      } else {
        errorMessage.value = response.message ?? 'Failed to get IB clients';
        ibClients.clear();
        update(['ib_clients']); // Trigger GetBuilder update with specific ID
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB clients: $e';
      ibClients.clear();
      return null;
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  /// Get IB Sub-IBs
  Future<List<IBClient>?> getIBSubIBs({
    int? subIbId,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
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
        update(['ib_clients', 'ib_structure']); // Trigger GetBuilder updates
        return ibSubIBs;
      } else {
        errorMessage.value = response.message ?? 'Failed to get IB Sub-IBs';
        ibSubIBs.clear();
        update(['ib_clients', 'ib_structure']); // Trigger GetBuilder updates
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB Sub-IBs: $e';
      ibSubIBs.clear();
      return null;
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  /// Get IB Trade History
  Future<List<IBTradeHistory>?> getIBTradeHistory({
    int? subIbId,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        isHistoryLoading.value = true;
      }
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
        final tradeHistoryResponse = IBTradeHistoryResponse.fromJson(
          response.data!,
        );
        ibTradeHistory.assignAll(tradeHistoryResponse.data ?? []);
        update(['ib_clients']); // Trigger GetBuilder update with specific ID
        return ibTradeHistory;
      } else {
        errorMessage.value =
            response.message ?? 'Failed to get IB trade history';
        ibTradeHistory.clear();
        update(['ib_clients']); // Trigger GetBuilder update with specific ID
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB trade history: $e';
      ibTradeHistory.clear();
      return null;
    } finally {
      if (showLoading) {
        isHistoryLoading.value = false;
      }
    }
  }

  /// Get IB Stats
  Future<IBStatsData?> getIBStats({
    int? subIbId,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final queryParams = {'_t': timestamp.toString()};

      String endpoint;
      if (subIbId != null) {
        // Use sub-ib specific endpoint with path parameter
        endpoint = '${ApiConstants.ibSubIbStructure}$subIbId';
      } else {
        endpoint = ApiConstants.ibStats;
      }

      final response = await ApiService.get(
        endpoint: endpoint,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final statsResponse = IBStatsResponse.fromJson(response.data!);
        ibStats.value = statsResponse.data;
        update(['ib_dashboard', 'ib_structure']); // Trigger GetBuilder updates
        return ibStats.value;
      } else {
        errorMessage.value = response.message ?? 'Failed to get IB stats';
        ibStats.value = null;
        update(['ib_dashboard', 'ib_structure']); // Trigger GetBuilder updates
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB stats: $e';
      ibStats.value = null;
      return null;
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  /// Load all My Clients data (clients, sub-ibs, trade-history, stats)
  Future<void> loadMyClientsData({int? subIbId}) async {
    try {
      isLoading.value = true;
      isHistoryLoading.value = true; // Also indicate history is starting
      errorMessage.value = '';

      // Step 0: Clear CURRENT data to ensure UI resets for the new IB
      ibClients.clear();
      ibSubIBs.clear();
      ibTradeHistory.clear();
      ibStats.value = null;

      update(); // Update GetBuilder to show loading state and cleared data

      // Step 1: Load essential data first (Stats, Clients, Sub-IBs)
      await Future.wait([
        getIBClients(subIbId: subIbId, showLoading: false),
        getIBSubIBs(subIbId: subIbId, showLoading: false),
        getIBStats(subIbId: subIbId, showLoading: false),
      ]);

      // Step 2: Stop global loading so the UI (stats cards, info) renders immediately
      isLoading.value = false;
      update();

      // Step 3: Now load trade history in background without blocking the essential UI
      await getIBTradeHistory(subIbId: subIbId, showLoading: false);
    } catch (e) {
      errorMessage.value = 'Error loading My Clients data: $e';
    } finally {
      isLoading.value = false;
      isHistoryLoading.value = false;
      update(); // Final update when all background tasks are done
    }
  }

  /// Load all Dashboard data (dashboard, stats)
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      update();

      await Future.wait([
        getIBDashboard(showLoading: false),
        getIBStats(showLoading: false),
      ]);
    } catch (e) {
      errorMessage.value = 'Error loading Dashboard data: $e';
    } finally {
      isLoading.value = false;
      update();
    }
  }

  /// Get IB Structure
  Future<IBStructureData?> getIBStructure({bool showLoading = true}) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get(
        endpoint: ApiConstants.ibStructure,
        queryParameters: {'_t': timestamp.toString()},
      );

      if (response.success && response.data != null) {
        final structureResponse = IBStructureResponse.fromJson(response.data!);
        ibStructureData.value = structureResponse.data;
        update(['ib_structure', 'ib_more']); // Trigger GetBuilder updates
        return ibStructureData.value;
      } else {
        errorMessage.value = response.message ?? 'Failed to get IB structure';
        ibStructureData.value = null;
        update(['ib_structure', 'ib_more']); // Trigger GetBuilder updates
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB structure: $e';
      ibStructureData.value = null;
      return null;
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  /// Get IB Approval Requests
  Future<List<IBApprovalRequest>?> getIBApprovalRequests({
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get(
        endpoint: ApiConstants.ibSubIbApprovalRequests,
        queryParameters: {'_t': timestamp.toString()},
      );

      if (response.success && response.data != null) {
        final approvalRequestsResponse = IBApprovalRequestsResponse.fromJson(
          response.data!,
        );
        ibApprovalRequests.assignAll(approvalRequestsResponse.data ?? []);
        update(['ib_requests']); // Trigger GetBuilder update with specific ID
        return ibApprovalRequests;
      } else {
        errorMessage.value =
            response.message ?? 'Failed to get IB approval requests';
        ibApprovalRequests.clear();
        update(['ib_requests']); // Trigger GetBuilder update with specific ID
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error getting IB approval requests: $e';
      ibApprovalRequests.clear();
      return null;
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  /// Load IB Data for selected Sub-IB
  Future<void> loadIBData({int? subIbId}) async {
    try {
      selectedSubIBId = subIbId;
      isLoading.value = true;
      errorMessage.value = '';

      // Clear old data
      ibClients.clear();
      ibSubIBs.clear();
      ibTradeHistory.clear();
      ibStats.value = null;

      // Update UI immediately to show loading state
      update(['ib_clients', 'ib_structure']);

      // Load all data
      await Future.wait([
        getIBClients(subIbId: subIbId, showLoading: false),
        getIBSubIBs(subIbId: subIbId, showLoading: false),
        getIBStats(subIbId: subIbId, showLoading: false),
      ]);

      isLoading.value = false;
      update(['ib_clients', 'ib_structure']);

      // Load trade history in background
      await getIBTradeHistory(subIbId: subIbId, showLoading: false);
    } catch (e) {
      errorMessage.value = 'Error loading IB data: $e';
      isLoading.value = false;
    } finally {
      isLoading.value = false;
      update(['ib_clients', 'ib_structure']);
    }
  }

  /// Clear all IB data
  void clearAllData() {
    selectedSubIBId = null;
    ibStatusResponse.value = null;
    ibDashboardResponse.value = null;
    ibDashboardData.value = null;
    ibClients.clear();
    ibSubIBs.clear();
    ibTradeHistory.clear();
    ibStats.value = null;
    ibStructureData.value = null;
    ibApprovalRequests.clear();
    errorMessage.value = '';
  }
}
