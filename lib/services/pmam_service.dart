import 'package:crm_app/services/api_service.dart';

class PmamService {
  // ──── Manager APIs ────

  static Future<ApiResponse> getManagerStatus() =>
      ApiService.get(endpoint: 'user/pmam/manager/status');

  static Future<ApiResponse> applyAsManager() => ApiService.post(
    endpoint: 'user/pmam/manager/apply',
    data: {'terms_accepted': true},
  );

  static Future<ApiResponse> getManagerPlans() =>
      ApiService.get(endpoint: 'user/pmam/manager/plans');

  static Future<ApiResponse> createPlan(Map<String, dynamic> body) =>
      ApiService.post(endpoint: 'user/pmam/manager/plans', data: body);

  static Future<ApiResponse> inactivatePlan(int planId) =>
      ApiService.post(endpoint: 'user/pmam/manager/plans/$planId/inactivate');

  static Future<ApiResponse> getManagerDashboardStats() =>
      ApiService.get(endpoint: 'user/pmam/manager/dashboard-stats');

  static Future<ApiResponse> getInvestorRequests(int planId) => ApiService.get(
    endpoint: 'user/pmam/manager/plans/$planId/investor-requests',
  );

  static Future<ApiResponse> getManagerInvestors() =>
      ApiService.get(endpoint: 'user/pmam/manager/investors');

  static Future<ApiResponse> approveInvestorRequest(int requestId) =>
      ApiService.post(
        endpoint: 'user/pmam/manager/investor-requests/$requestId/approve',
      );

  static Future<ApiResponse> rejectInvestorRequest(int requestId) =>
      ApiService.post(
        endpoint: 'user/pmam/manager/investor-requests/$requestId/reject',
      );

  static Future<ApiResponse> getPlanDetail(int planId) =>
      ApiService.get(endpoint: 'user/pmam/manager/plans/$planId/detail');

  static Future<ApiResponse> getPlanAllocations(
    int planId, {
    int page = 1,
    int perPage = 15,
    String? dateFrom,
    String? dateTo,
    String? userId,
    String? status,
  }) {
    String p = 'page=$page&per_page=$perPage';
    if (dateFrom != null && dateFrom.isNotEmpty) {
      p += '&date_from=${Uri.encodeComponent(dateFrom)}';
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      p += '&date_to=${Uri.encodeComponent(dateTo)}';
    }
    if (userId != null && userId.isNotEmpty) {
      p += '&user_id=${Uri.encodeComponent(userId)}';
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      p += '&status=${Uri.encodeComponent(status)}';
    }
    return ApiService.get(
        endpoint: 'user/pmam/manager/plans/$planId/allocations?$p');
  }

  static Future<ApiResponse> getPlanInvestors(
    int planId, {
    int page = 1,
    int perPage = 10,
    String? sortBy,
    String? order,
    String? search,
  }) {
    String p = 'page=$page&per_page=$perPage';
    if (sortBy != null && sortBy.isNotEmpty) p += '&sort_by=$sortBy';
    if (order != null && order.isNotEmpty) p += '&order=$order';
    if (search != null && search.isNotEmpty) {
      p += '&search=${Uri.encodeComponent(search)}';
    }
    return ApiService.get(
        endpoint: 'user/pmam/manager/plans/$planId/investors?$p');
  }

  static Future<ApiResponse> getManagerInvestorDetail(int investorId) =>
      ApiService.get(endpoint: 'user/pmam/manager/investors/$investorId/detail');

  // ──── Investor APIs ────

  static Future<ApiResponse> getAvailablePlans() =>
      ApiService.get(endpoint: 'user/pmam/investor/plans');

  static Future<ApiResponse> getEligibleAccounts([int? planId]) => ApiService.get(
    endpoint:
        'user/pmam/investor/eligible-accounts${planId != null ? "?plan_id=$planId" : ""}',
  );

  static Future<ApiResponse> getManagersDataTable({
    String search = '',
    int start = 0,
    int length = 50,
    int draw = 1,
  }) => ApiService.post(
    endpoint: 'user/pmam/managers/datatable',
    data: {
      'draw': draw,
      'start': start,
      'length': length,
      'search[value]': search,
      'search[regex]': false,
      'order[0][column]': 6,
      'order[0][dir]': 'desc',
      'columns[0][data]': 'manager_name',
      'columns[0][searchable]': true,
      'columns[1][data]': 'manager_code',
      'columns[1][searchable]': true,
      'columns[2][data]': 'plans_count',
      'columns[3][data]': 'total_aum',
      'columns[4][data]': 'total_investors',
      'columns[5][data]': 'avg_commission',
      'columns[6][data]': 'profit_percentage',
      'columns[7][data]': 'member_since',
    },
  );

  static Future<ApiResponse> requestJoin(Map<String, dynamic> body) =>
      ApiService.post(endpoint: 'user/pmam/investor/request-join', data: body);

  static Future<ApiResponse> investorDeposit(Map<String, dynamic> body) =>
      ApiService.post(endpoint: 'user/pmam/investor/deposit', data: body);

  static Future<ApiResponse> unsubscribe(int investorId) =>
      ApiService.post(endpoint: 'user/pmam/investor/unsubscribe/$investorId');

  static Future<ApiResponse> getPnlHistory() =>
      ApiService.get(endpoint: 'user/pmam/investor/pnl-history');

  static Future<ApiResponse> getMyFundEntries() =>
      ApiService.get(endpoint: 'user/pmam/investor/my-fund-entries');

  static Future<ApiResponse> getInvestorEnrollments() =>
      ApiService.get(endpoint: 'user/pmam/investor/enrollments');

  static Future<ApiResponse> getMyOpenAllocations() =>
      ApiService.get(endpoint: 'user/pmam/investor/my-open-allocations');

  static Future<ApiResponse> getManagerTrades({
    required String managerCode,
    required int planId,
    required String dateFrom,
    required String dateTo,
    int page = 1,
    int perPage = 20,
    int? investorId,
  }) {
    var p = 'plan_id=$planId'
        '&date_from=${Uri.encodeComponent(dateFrom)}'
        '&date_to=${Uri.encodeComponent(dateTo)}'
        '&page=$page'
        '&per_page=$perPage';
    if (investorId != null) {
      p += '&investor_id=$investorId';
    }
    return ApiService.get(endpoint: 'user/pmam/managers/$managerCode/trades?$p');
  }
}
