import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_dashboard_controller.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_plan_detail_controller.dart';
import 'package:crm_app/screens/home/more/copytrading/copy_trading_edit_plan_screen.dart';
import 'package:crm_app/services/theme_service.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/widgets/app_svg_back_button.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'widgets/master_plan_detail/plan_activity_tab.dart';
import 'widgets/master_plan_detail/plan_commission_tab.dart';
import 'widgets/master_plan_detail/plan_detail_tokens.dart';
import 'widgets/master_plan_detail/plan_hero_card.dart';
import 'widgets/master_plan_detail/plan_overview_tab.dart';
import 'widgets/master_plan_detail/plan_tab_bar.dart';
import 'widgets/master_plan_detail/plan_trades_tab.dart';

/// Top-level Master Plan Detail screen.
///
/// Tab-driven layout (web-style):
///   • Overview    — performance, equity, commission summary, settlement,
///                   rules, strategy, account
///   • Activity    — recent activity feed + plan timeline
///   • Trades      — open positions + closed trade history
///   • Commission  — totals + per-trade commission history
///
/// The actual content for each tab is rendered by dedicated widgets in
/// `widgets/master_plan_detail/` so each tab stays small and focused.
class MasterPlanDetailScreen extends StatelessWidget {
  final int planId;
  const MasterPlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      CopyTradingMasterPlanDetailController(planId: planId),
      permanent: false,
    );

    return Obx(() {
      final theme = Get.find<ThemeService>();
      final isDark = theme.isDarkModeObs.value;
      final tokens = PlanTokens(isDark: isDark);

      return Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          backgroundColor: tokens.surface,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          surfaceTintColor: tokens.surface,
          leading: AppSvgBackButton(onPressed: () => Get.back()),
          title: Text(
            'Plan Details',
            style: AppTextStyles.heading.copyWith(color: tokens.textPrimary),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.detail.value == null) {
            return Center(
              child: CircularProgressIndicator(color: tokens.brand),
            );
          }

          final plan = controller.detail.value;
          if (plan == null) {
            return _EmptyState(
              onRetry: controller.loadPlanDetail,
              tokens: tokens,
            );
          }

          return _PlanDetailBody(
            plan: plan,
            controller: controller,
            tokens: tokens,
          );
        }),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body (uses the shared per-tab widgets)
// ─────────────────────────────────────────────────────────────────────────────

class _PlanDetailBody extends StatefulWidget {
  final CopyTradingMasterPlanDetail plan;
  final CopyTradingMasterPlanDetailController controller;
  final PlanTokens tokens;

  const _PlanDetailBody({
    required this.plan,
    required this.controller,
    required this.tokens,
  });

  @override
  State<_PlanDetailBody> createState() => _PlanDetailBodyState();
}

class _PlanDetailBodyState extends State<_PlanDetailBody> {
  int _currentIndex = 0;

  static const _tabs = ['Overview', 'Activity', 'Trades', 'Commission'];

  // Single scroller for the whole screen. Reset on tab change so the
  // newly-selected tab starts from the hero card instead of inheriting
  // the deep-scroll position of the previous tab.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    // Jump back to the top of the scroll surface. Use a post-frame
    // callback so the new tab content is laid out before we reset
    // the offset.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (_scrollController.offset > 0) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.controller.loadPlanDetail,
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlanTabBar(
            tabs: _tabs,
            currentIndex: _currentIndex,
            onTap: _switchTab,
            tokens: widget.tokens,
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              controller: _scrollController,
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              children: [
                PlanHeroCard(
                  plan: widget.plan,
                  controller: widget.controller,
                  tokens: widget.tokens,
                  onEdit: () => _openEditScreen(context),
                  onConfirmInactivate: () => _confirmInactivate(context),
                ),
                const SizedBox(height: 14),
                _buildActiveTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_currentIndex) {
      case 1:
        return PlanActivityTab(plan: widget.plan, tokens: widget.tokens);
      case 2:
        return PlanTradesTab(plan: widget.plan, tokens: widget.tokens);
      case 3:
        return PlanCommissionTab(plan: widget.plan, tokens: widget.tokens);
      case 0:
      default:
        return PlanOverviewTab(plan: widget.plan, tokens: widget.tokens);
    }
  }

  void _openEditScreen(BuildContext context) {
    // Build a CopyTradingMasterPlanItem shim so the existing edit screen
    // can be reused with the same form fields.
    final p = widget.plan;
    final item = CopyTradingMasterPlanItem(
      id: p.id,
      planName: p.planName,
      tradingAccountNumber: p.tradingAccountNumber,
      tradingServer: p.tradingServer,
      lpProviderName: p.lpProviderName,
      serverType: p.serverType,
      commissionType: p.commissionType,
      commissionLabel: p.commissionLabel,
      commissionPercentage: p.commissionPercentage,
      subscriptionFee: p.subscriptionFee,
      subscriptionPeriodDays: p.subscriptionPeriodDays,
      settlementCycle: '',
      lastSettledAt: '',
      minimumCapital: p.minimumCapital,
      copyRatio: p.copyRatio,
      maxCopiers: p.maxCopiers == 0 ? null : p.maxCopiers,
      activeCopiersCount: p.activeCopiers,
      totalCapital: p.totalCapital,
      roiPct: 0,
      isFull: p.isFull,
      status: p.status,
      copyingPaused: p.copyingPaused,
      copyingPausedAt: p.copyingPausedAt,
      strategyDescription: p.strategyDescription,
      riskInformation: p.riskInformation,
      noFeeDays: p.noFeeDays,
      createdAt: p.createdAt,
    );
    final dashController =
        Get.isRegistered<CopyTradingMasterDashboardController>()
        ? Get.find<CopyTradingMasterDashboardController>()
        : Get.put(
            CopyTradingMasterDashboardController(masterCode: ''),
            permanent: true,
          );
    Get.to(
      () => CopyTradingEditPlanScreen(plan: item, controller: dashController),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    )?.then((_) {
      if (Get.isRegistered<CopyTradingMasterPlanDetailController>()) {
        Get.find<CopyTradingMasterPlanDetailController>().loadPlanDetail();
      }
    });
  }

  void _confirmInactivate(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          Get.find<LanguageService>().tr('copy_inactivate_plan_title'),
        ),
        content: Text(
          Get.find<LanguageService>().tr('copy_inactivate_plan_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final res = await widget.controller.inactivatePlan();
              if (res.success) {
                CustomToastService.showSuccess(
                  message: 'Plan inactivated',
                  title: 'Done',
                );
              } else {
                CustomToastService.showError(
                  message: res.message ?? 'Failed to inactivate plan',
                  title: 'Error',
                );
              }
            },
            child: const Text('Inactivate'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRetry;
  final PlanTokens tokens;
  const _EmptyState({required this.onRetry, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: tokens.mutedText),
          const SizedBox(height: 12),
          Text(
            'Plan not found',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => onRetry(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
