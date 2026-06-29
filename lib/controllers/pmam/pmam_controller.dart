import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:crm_app/services/pmam_service.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/models/pmam_model.dart';

class PmamController extends GetxController {
  // ── Loading / Error ──
  final RxBool isLoading = false.obs;
  final RxBool isCreatePlanLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isTradesLoading = false.obs;

  // ── Manager state ──
  final RxString managerStatus = ''.obs; // pending | approved | rejected | ''
  final RxString managerCode = ''.obs;

  final RxMap<String, dynamic> dashboardStats = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> managerPlans =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> investorRequests =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> managerInvestors =
      <Map<String, dynamic>>[].obs; // from GET manager/investors API
  final RxBool isInvestorsLoading = false.obs;

  // ── Manager Dashboard derived state ──
  /// Currently selected dashboard time-range preset (Today / 7d / 30d / 90d / 1y / all)
  final RxString dashboardRange = '30d'.obs;

  /// Hero stat tiles for the manager dashboard. Each block contains
  /// `current`, optional `delta_pct` / `delta`, and `series.data` for sparkline.
  final RxMap<String, dynamic> heroStats = <String, dynamic>{}.obs;

  /// Main performance chart payload — keys: `equity`, `aum`, `pnl`. Each entry
  /// contains a `series` map with `data` list.
  final RxMap<String, dynamic> mainChartData = <String, dynamic>{}.obs;

  /// Investor health breakdown (active / pending / inactive counts + retention stats).
  final RxMap<String, dynamic> investorHealth = <String, dynamic>{}.obs;

  /// Payout summary (earned in period + pending payout amount).
  final RxMap<String, dynamic> payoutsData = <String, dynamic>{}.obs;

  /// Recent trades displayed on the dashboard (placeholder until a dedicated
  /// "recent trades" endpoint exists — currently empty).
  final RxList<Map<String, dynamic>> recentDashboardTrades =
      <Map<String, dynamic>>[].obs;

  // ── Investor state ──
  final RxList<PmamManager> managersList = <PmamManager>[].obs; // from datatable API
  final RxBool isManagersLoading = false.obs;
  final RxInt managersTotal = 0.obs;
  final RxList<Map<String, dynamic>> availablePlans =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> myInvestments =
      <Map<String, dynamic>>[].obs; // legacy: currently mirrors fundEntries
  final RxList<Map<String, dynamic>> enrollments =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> openAllocations =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> eligibleAccounts =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> pnlHistory = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> fundEntries = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> trades = <Map<String, dynamic>>[].obs;
  final RxInt tradesTotal = 0.obs;
  final RxInt tradesPage = 1.obs;
  final RxInt tradesPerPage = 20.obs;
  final RxInt tradesTotalPages = 1.obs;
  final RxDouble tradesNetPnl = 0.0.obs;
  final RxDouble tradesCommission = 0.0.obs;
  final RxDouble tradesSettledPnl = 0.0.obs;

  // ── Selected plan for investor requests ──
  final RxInt selectedPlanId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadManagerStatus();
    loadManagerDashboard();
  }

  // ══════════════════════════════════════════
  // MANAGER APIs
  // ══════════════════════════════════════════

  Future<void> loadManagerStatus() async {
    try {
      isLoading.value = true;
      final response = await PmamService.getManagerStatus();
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final inner = data['data'];
        if (inner is Map<String, dynamic>) {
          managerStatus.value = (inner['status'] ?? '').toString();
          managerCode.value = (inner['manager_code'] ?? '').toString();
        } else {
          managerStatus.value = '';
          managerCode.value = '';
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> applyAsManager() async {
    try {
      isLoading.value = true;
      final response = await PmamService.applyAsManager();
      if (response.success) {
        managerStatus.value = 'pending';
        CustomToastService.showSuccess(
          message: 'Manager application submitted successfully!',
        );
        return true;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Failed to submit application',
        );
        return false;
      }
    } catch (e) {
      CustomToastService.showError(message: 'Error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load the manager dashboard data for the given [range] preset.
  ///
  /// Combines `manager/dashboard-stats` and `manager/plans` into the rich
  /// derived maps consumed by [PmamManagerDashboardScreen]
  /// (`heroStats`, `mainChartData`, `investorHealth`, `payoutsData`,
  /// `recentDashboardTrades`).
  Future<void> loadManagerDashboard({String? range}) async {
    try {
      isLoading.value = true;
      if (range != null && range.isNotEmpty) {
        dashboardRange.value = range;
      }

      final results = await Future.wait([
        PmamService.getManagerDashboardStats(),
        PmamService.getManagerPlans(),
        PmamService.getManagerInvestors(),
      ]);

      final statsResp = results[0];
      Map<String, dynamic> statsMap = {};
      if (statsResp.success && statsResp.data != null) {
        final d = statsResp.data as Map<String, dynamic>;
        statsMap = (d['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(d['data'] as Map<String, dynamic>)
            : {};
        dashboardStats.value = statsMap;
      }

      final plansResp = results[1];
      if (plansResp.success && plansResp.data != null) {
        final d = plansResp.data as Map<String, dynamic>;
        final list = d['data'];
        if (list is List) {
          managerPlans.assignAll(
            list.whereType<Map<String, dynamic>>().toList(),
          );
        } else {
          managerPlans.clear();
        }
      } else {
        managerPlans.clear();
      }

      final investorsResp = results[2];
      if (investorsResp.success && investorsResp.data != null) {
        final d = investorsResp.data as Map<String, dynamic>;
        final list = d['data'];
        if (list is List) {
          managerInvestors.assignAll(
            list.whereType<Map<String, dynamic>>().toList(),
          );
        } else {
          managerInvestors.clear();
        }
      } else {
        managerInvestors.clear();
      }

      _hydrateDashboardViews(statsMap: statsMap);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Convert the flat `dashboard-stats` payload + plans + investors into the
  /// richer structure consumed by the dashboard screen. When the backend
  /// doesn't ship a given field yet, we emit a safe zeroed shape so the UI
  /// never crashes on `null`/missing keys.
  void _hydrateDashboardViews({
    required Map<String, dynamic> statsMap,
  }) {
    num toNum(dynamic v) =>
        v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

    final totalAum = toNum(statsMap['total_locked_aum']);
    final activeInvestors = toNum(statsMap['active_investors']);
    final pendingRequests = toNum(statsMap['pending_requests']);
    final totalPnl = toNum(statsMap['total_pnl']);
    final totalCommission = toNum(statsMap['total_commission']);
    final commissionThisMonth = toNum(statsMap['commission_this_month']);

    // ROI over window: total_pnl / total_locked_aum * 100, guard div-by-zero.
    final roiPct = totalAum > 0 ? (totalPnl / totalAum) * 100.0 : 0.0;

    // ── Hero stats ──
    heroStats.assignAll({
      'aum': {
        'current': totalAum,
        'delta_pct': 0,
        'series': {'data': <num>[totalAum]},
      },
      'investors': {
        'current': activeInvestors,
        'delta': pendingRequests,
        'series': {'data': <num>[activeInvestors]},
      },
      'earnings': {
        'current': totalCommission,
        'delta_pct': 0,
        'series': {'data': <num>[totalCommission]},
      },
      'roi': {
        'current_pct': roiPct,
        'delta_pct': 0,
        'series': {'data': <num>[roiPct]},
      },
    });

    // ── Main performance chart (single-point series; backend will extend) ──
    mainChartData.assignAll({
      'equity': {
        'series': {'data': <num>[totalAum + totalPnl]},
      },
      'aum': {
        'series': {'data': <num>[totalAum]},
      },
      'pnl': {
        'series': {'data': <num>[totalPnl]},
      },
    });

    // ── Investor health ──
    int active = 0, pending = 0, inactive = 0;
    for (final inv in managerInvestors) {
      final status =
          (inv['status'] ?? inv['investor_status'] ?? '').toString().toLowerCase();
      if (status == 'active' || status == 'approved') {
        active++;
      } else if (status == 'pending') {
        pending++;
      } else if (status == 'inactive' ||
          status == 'inactivated' ||
          status == 'rejected' ||
          status == 'cancelled') {
        inactive++;
      }
    }
    final healthTotal = active + pending + inactive;
    investorHealth.assignAll({
      'active': active,
      'pending': pending == 0 ? pendingRequests : pending,
      'inactive': inactive,
      'new_this_period': 0,
      'churned': 0,
      'avg_age_days': 0,
      'retention_rate': healthTotal > 0
          ? ((active / healthTotal) * 100).toStringAsFixed(1)
          : '0',
    });

    // ── Payouts ──
    // "Pending" = total commission earned but not yet settled (this month
    // commission is treated as still pending until settled_at is set).
    final recentCommissions = statsMap['recent_commissions'];
    num settledThisMonth = 0;
    if (recentCommissions is List) {
      for (final c in recentCommissions) {
        if (c is Map) {
          settledThisMonth += toNum(c['net_profit_credited']);
        }
      }
    }
    final pendingPayout = (commissionThisMonth - settledThisMonth).clamp(0, double.infinity);
    payoutsData.assignAll({
      'earned_period': commissionThisMonth,
      'pending': pendingPayout,
    });

    // ── Recent trades (placeholder until backend ships a dedicated endpoint) ──
    recentDashboardTrades.clear();
  }

  Future<bool> createPlan(Map<String, dynamic> body) async {
    try {
      isCreatePlanLoading.value = true;
      final response = await PmamService.createPlan(body);
      if (response.success) {
        CustomToastService.showSuccess(
          message: response.message ?? 'Plan created successfully!',
        );
        await loadManagerDashboard();
        return true;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Failed to create plan',
        );
        return false;
      }
    } catch (e) {
      CustomToastService.showError(message: 'Error: $e');
      return false;
    } finally {
      isCreatePlanLoading.value = false;
    }
  }

  Future<bool> inactivatePlan(int planId) async {
    try {
      isLoading.value = true;
      final response = await PmamService.inactivatePlan(planId);
      if (response.success) {
        CustomToastService.showSuccess(
          message: 'Plan inactivated successfully',
        );
        await loadManagerDashboard();
        return true;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Cannot inactivate plan',
        );
        return false;
      }
    } catch (e) {
      CustomToastService.showError(message: 'Error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadInvestorRequests(int planId) async {
    try {
      selectedPlanId.value = planId;
      isLoading.value = true;
      final response = await PmamService.getInvestorRequests(planId);
      if (response.success && response.data != null) {
        final d = response.data as Map<String, dynamic>;
        final list = d['data'];
        if (list is List) {
          investorRequests.assignAll(
            list.whereType<Map<String, dynamic>>().toList(),
          );
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all investors for this manager (GET user/pmam/manager/investors)
  Future<void> loadManagerInvestors() async {
    try {
      isInvestorsLoading.value = true;
      final response = await PmamService.getManagerInvestors();
      if (response.success && response.data != null) {
        final d = response.data as Map<String, dynamic>;
        final list = d['data'];
        if (list is List) {
          managerInvestors.assignAll(
            list.whereType<Map<String, dynamic>>().toList(),
          );
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isInvestorsLoading.value = false;
    }
  }

  Future<bool> approveInvestorRequest(int requestId) async {
    try {
      final response = await PmamService.approveInvestorRequest(requestId);
      if (response.success) {
        CustomToastService.showSuccess(message: 'Investor request approved');
        if (selectedPlanId.value > 0) {
          await loadInvestorRequests(selectedPlanId.value);
        }
        return true;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Failed to approve',
        );
        return false;
      }
    } catch (e) {
      CustomToastService.showError(message: 'Error: $e');
      return false;
    }
  }

  Future<bool> rejectInvestorRequest(int requestId) async {
    try {
      final response = await PmamService.rejectInvestorRequest(requestId);
      if (response.success) {
        CustomToastService.showSuccess(message: 'Investor request rejected');
        if (selectedPlanId.value > 0) {
          await loadInvestorRequests(selectedPlanId.value);
        }
        return true;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Failed to reject',
        );
        return false;
      }
    } catch (e) {
      CustomToastService.showError(message: 'Error: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════
  // INVESTOR APIs
  // ══════════════════════════════════════════

  /// Load managers list via datatable POST API (supports server-side search)
  Future<void> loadManagersDataTable({String search = ''}) async {
    try {
      isManagersLoading.value = true;
      final response = await PmamService.getManagersDataTable(search: search);
      if (response.success && response.data != null) {
        final d = response.data as Map<String, dynamic>;
        final list = d['data'];
        managersTotal.value = (d['recordsTotal'] ?? 0) as int;
        if (list is List) {
          managersList.assignAll(
            list.map((i) => PmamManager.fromJson(i as Map<String, dynamic>)).toList(),
          );
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isManagersLoading.value = false;
    }
  }

  /// Lightweight: only loads eligible accounts (for Create Plan / Invest sheet)
  Future<void> loadEligibleAccounts([int? planId]) async {
    try {
      final response = await PmamService.getEligibleAccounts(planId);
      if (response.success && response.data != null) {
        final d = response.data as Map<String, dynamic>;
        final list = d['data'];
        if (list is List) {
          eligibleAccounts.assignAll(
            list.whereType<Map<String, dynamic>>().toList(),
          );
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> loadInvestorPortal({int? planId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final futures = <Future>[
        PmamService.getAvailablePlans(),
        PmamService.getInvestorEnrollments(),
        PmamService.getMyOpenAllocations(),
        PmamService.getMyFundEntries(),
        if (planId != null) PmamService.getEligibleAccounts(planId),
      ];
      final results = await Future.wait(futures);

      final plansResp = results[0];
      if (plansResp.success && plansResp.data != null) {
        final d = plansResp.data as Map<String, dynamic>;
        final list = d['data'];
        if (list is List) {
          availablePlans.assignAll(
            list.whereType<Map<String, dynamic>>().toList(),
          );
        }
      } else if (!plansResp.success) {
        errorMessage.value = plansResp.message ?? 'Failed to load plans';
      }

      final enrollResp = results[1];
      if (enrollResp.success && enrollResp.data != null) {
        final d = enrollResp.data as Map<String, dynamic>;
        final list = d['data'];
        if (list is List) {
          enrollments.assignAll(
            list.whereType<Map<String, dynamic>>().toList(),
          );
        }
      } else if (!enrollResp.success) {
        errorMessage.value =
            enrollResp.message ?? 'Failed to load enrollments';
      }

      final allocResp = results[2];
      if (allocResp.success && allocResp.data != null) {
        final d = allocResp.data as Map<String, dynamic>;
        final list = d['data'];
        if (list is List) {
          openAllocations.assignAll(
            list.whereType<Map<String, dynamic>>().toList(),
          );
        }
      } else if (!allocResp.success) {
        errorMessage.value =
            allocResp.message ?? 'Failed to load open allocations';
      }

      final entriesResp = results[3];
      if (entriesResp.success && entriesResp.data != null) {
        final d = entriesResp.data as Map<String, dynamic>;
        final data = d['data'];
        List<Map<String, dynamic>> rows = [];
        if (data is List) {
          rows = data.whereType<Map<String, dynamic>>().toList();
        } else if (data is Map<String, dynamic>) {
          final nestedCandidates = [
            data['fund_entries'],
            data['fundEntries'],
            data['entries'],
            data['data'],
          ];
          for (final c in nestedCandidates) {
            if (c is List) {
              rows = c.whereType<Map<String, dynamic>>().toList();
              break;
            }
            if (c is Map<String, dynamic>) {
              final inner = c['data'];
              if (inner is List) {
                rows = inner.whereType<Map<String, dynamic>>().toList();
                break;
              }
            }
          }
        }
        fundEntries.assignAll(rows);
        myInvestments.assignAll(rows); // keep legacy binding safe
      } else if (!entriesResp.success) {
        errorMessage.value =
            entriesResp.message ?? 'Failed to load fund entries';
      }

      if (planId != null && results.length > 4) {
        final accountsResp = results[4];
        if (accountsResp.success && accountsResp.data != null) {
          final d = accountsResp.data as Map<String, dynamic>;
          final list = d['data'];
          if (list is List) {
            eligibleAccounts.assignAll(
              list.whereType<Map<String, dynamic>>().toList(),
            );
          }
        } else if (!accountsResp.success) {
          errorMessage.value =
              accountsResp.message ?? 'Failed to load eligible accounts';
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> depositToEnrollment({
    required int pmamInvestorId,
    required double amount,
  }) async {
    try {
      isLoading.value = true;
      final resp = await PmamService.investorDeposit({
        'pmam_investor_id': pmamInvestorId,
        'amount': amount,
      });
      if (resp.success) {
        CustomToastService.showSuccess(message: resp.message ?? 'Deposit added');
        await loadInvestorPortal();
        return true;
      }
      CustomToastService.showError(
        message: resp.message ?? 'Failed to add funds',
      );
      return false;
    } catch (e) {
      CustomToastService.showError(message: 'Error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTradesForEnrollment({
    required String managerCode,
    required int planId,
    required String dateFrom,
    required String dateTo,
    required int investorId,
    int page = 1,
    int perPage = 20,
    bool append = false,
  }) async {
    try {
      isTradesLoading.value = true;
      tradesPage.value = page;
      tradesPerPage.value = perPage;
      if (kDebugMode) {
        debugPrint(
          '[PMAM] getManagerTrades(managerCode=$managerCode, planId=$planId, investorId=$investorId, date_from=$dateFrom, date_to=$dateTo, page=$page, per_page=$perPage)',
        );
      }
      final resp = await PmamService.getManagerTrades(
        managerCode: managerCode,
        planId: planId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        investorId: investorId,
        page: page,
        perPage: perPage,
      );
      if (resp.success && resp.data != null) {
        final d = resp.data as Map<String, dynamic>;
        final data = d['data'];
        if (data is Map<String, dynamic>) {
          final rows = data['trades'];
          if (rows is List) {
            final parsed = rows.whereType<Map<String, dynamic>>().toList();
            if (append && trades.isNotEmpty) {
              trades.addAll(parsed);
            } else {
              trades.assignAll(parsed);
            }
            tradesTotal.value = int.tryParse((data['total'] ?? 0).toString()) ?? 0;
            tradesPage.value = int.tryParse((data['page'] ?? page).toString()) ?? page;
            tradesPerPage.value =
                int.tryParse((data['per_page'] ?? perPage).toString()) ?? perPage;
            tradesTotalPages.value =
                int.tryParse((data['total_pages'] ?? 1).toString()) ?? 1;
            if (kDebugMode) {
              debugPrint(
                '[PMAM] trades pagination total=${tradesTotal.value} page=${tradesPage.value} per_page=${tradesPerPage.value} total_pages=${tradesTotalPages.value} rows=${parsed.length}',
              );
            }

            double net = 0, comm = 0;
            for (final t in trades) {
              net += double.tryParse((t['profit'] ?? 0).toString()) ?? 0;
              comm +=
                  double.tryParse((t['commission_charged'] ?? 0).toString()) ?? 0;
            }
            tradesNetPnl.value = net;
            tradesCommission.value = comm;
            tradesSettledPnl.value = net - comm;
          } else {
            trades.clear();
            tradesTotal.value = 0;
            tradesTotalPages.value = 1;
            tradesNetPnl.value = 0;
            tradesCommission.value = 0;
            tradesSettledPnl.value = 0;
            if (kDebugMode) {
              debugPrint('[PMAM] trades response missing `data.trades` list');
            }
          }
        } else if (data is List) {
          // Backward-compat if API ever returns a list directly
          final parsed = data.whereType<Map<String, dynamic>>().toList();
          if (append && trades.isNotEmpty) {
            trades.addAll(parsed);
          } else {
            trades.assignAll(parsed);
          }
          tradesTotal.value = parsed.length;
          tradesTotalPages.value = 1;
          if (kDebugMode) {
            debugPrint('[PMAM] trades response is List rows=${parsed.length} (no pagination fields)');
          }
          double net = 0, comm = 0;
          for (final t in trades) {
            net += double.tryParse((t['profit'] ?? 0).toString()) ?? 0;
            comm +=
                double.tryParse((t['commission_charged'] ?? 0).toString()) ?? 0;
          }
          tradesNetPnl.value = net;
          tradesCommission.value = comm;
          tradesSettledPnl.value = net - comm;
        } else {
          trades.clear();
          tradesTotal.value = 0;
          tradesTotalPages.value = 1;
          tradesNetPnl.value = 0;
          tradesCommission.value = 0;
          tradesSettledPnl.value = 0;
          if (kDebugMode) {
            debugPrint('[PMAM] trades response unexpected data type: ${data.runtimeType}');
          }
        }
      } else {
        trades.clear();
        tradesTotal.value = 0;
        tradesTotalPages.value = 1;
        tradesNetPnl.value = 0;
        tradesCommission.value = 0;
        tradesSettledPnl.value = 0;
        if (kDebugMode) {
          debugPrint('[PMAM] getManagerTrades failed success=${resp.success} message=${resp.message}');
        }
      }
    } catch (e) {
      trades.clear();
      tradesTotal.value = 0;
      tradesTotalPages.value = 1;
      tradesNetPnl.value = 0;
      tradesCommission.value = 0;
      tradesSettledPnl.value = 0;
      CustomToastService.showError(message: 'Error: $e');
      if (kDebugMode) debugPrint('[PMAM] getManagerTrades exception: $e');
    } finally {
      isTradesLoading.value = false;
    }
  }

  Future<bool> requestJoin({
    required int planId,
    required int accountId,
    required double amount,
  }) async {
    try {
      isLoading.value = true;
      final response = await PmamService.requestJoin({
        'pmam_plan_id': planId,
        'investor_account_id': accountId,
        'invested_amount': amount,
      });
      if (response.success) {
        CustomToastService.showSuccess(
          message: 'Join request submitted! Waiting for manager approval.',
        );
        await loadInvestorPortal(planId: planId);
        return true;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Failed to submit join request',
        );
        return false;
      }
    } catch (e) {
      CustomToastService.showError(message: 'Error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Alias for requestJoin used in UI
  Future<bool> joinPlan(int accountId, int planId, double amount) =>
      requestJoin(planId: planId, accountId: accountId, amount: amount);

  Future<bool> unsubscribe(int investorId) async {
    try {
      isLoading.value = true;
      final response = await PmamService.unsubscribe(investorId);
      if (response.success) {
        CustomToastService.showSuccess(message: 'Unsubscribe request accepted');
        await loadInvestorPortal();
        return true;
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Failed to unsubscribe',
        );
        return false;
      }
    } catch (e) {
      CustomToastService.showError(message: 'Error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
