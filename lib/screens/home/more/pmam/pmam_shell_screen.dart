import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/pmam/pmam_controller.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:crm_app/screens/home/more/pmam/pmam_widgets.dart';
import 'package:crm_app/screens/home/more/pmam/pmam_manager_investor_detail_screen.dart';

class PmamShellScreen extends StatefulWidget {
  const PmamShellScreen({super.key});

  @override
  State<PmamShellScreen> createState() => _PmamShellScreenState();
}

class _PmamShellScreenState extends State<PmamShellScreen> {
  int _currentIndex = 0;
  late final PmamController _ctrl;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PmamController>()) {
      _ctrl = Get.find<PmamController>();
    } else {
      _ctrl = Get.put(PmamController());
    }
    // Don't call loadManagerDashboard() here — controller.onInit() already calls it.
    // Only load investors here since that's not in onInit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.loadManagerInvestors();
    });
  }

  @override
  void dispose() {
    // Shell is disposed — no cleanup needed since controller is shared
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PmamColors.scaffoldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          _InvestorsTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people_rounded,
                  label: 'Investors',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? PmamColors.primaryPurpleLight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? PmamColors.primaryPurple
                  : PmamColors.textSecondary,
              size: 24.sp,
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? PmamColors.primaryPurple
                    : PmamColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Dashboard Tab ───────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  String _fmt(dynamic val) {
    if (val == null) return '\$0';
    final d = double.tryParse(val.toString()) ?? 0.0;
    if (d.abs() >= 1000) {
      return '\$${(d / 1000).toStringAsFixed(1)}K';
    }
    return '\$${d.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PmamController>(
      init: Get.isRegistered<PmamController>()
          ? Get.find<PmamController>()
          : Get.put(PmamController()),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: PmamColors.scaffoldBg,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: PmamColors.scaffoldBg,
            elevation: 0,
            title: Text('Dashboard', style: AppTextStyles.headingblack),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    color: PmamColors.primaryPurple, size: 22.sp),
                onPressed: () => ctrl.loadManagerDashboard(),
              ),
            ],
          ),
          body: Obx(() {
            if (ctrl.isLoading.value) {
              return Center(
                child: CommonLoadingWidget(
                    size: 40, color: PmamColors.primaryPurple),
              );
            }
            final stats = ctrl.dashboardStats;
            final plans = ctrl.managerPlans;

            return RefreshIndicator(
              color: PmamColors.primaryPurple,
              onRefresh: () => ctrl.loadManagerDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileCard(ctrl: ctrl),
                    SizedBox(height: 16.h),
                    _StatsGrid(stats: stats, fmt: _fmt),
                    SizedBox(height: 12.h),
                    _CommissionCard(stats: stats, fmt: _fmt),
                    SizedBox(height: 20.h),
                    PmamSectionHeader(
                      title: 'My Plans',
                      actionLabel: '+ New Plan',
                      onAction: () =>
                          Get.toNamed(AppPages.PMAM_CREATE_PLAN),
                    ),
                    SizedBox(height: 12.h),
                    if (plans.isEmpty)
                      const PmamEmptyState(
                        icon: Icons.description_outlined,
                        message: 'No plans yet. Create your first plan!',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: plans.length > 3 ? 3 : plans.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10.h),
                        itemBuilder: (_, i) => _PlanCard(plan: plans[i]),
                      ),
                    if (plans.length > 3) ...[
                      SizedBox(height: 12.h),
                      Center(
                        child: GestureDetector(
                          onTap: () => Get.toNamed(AppPages.PMAM_MANAGER_PORTAL),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: PmamColors.primaryPurpleLight,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'View All Plans (${plans.length})',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: PmamColors.primaryPurple,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// ─── Profile Card ────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final PmamController ctrl;
  const _ProfileCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final code = ctrl.managerCode.value;
    final stats = ctrl.dashboardStats;
    final managerName =
        (stats['manager_name'] ?? stats['name'] ?? 'Manager').toString();

    return PmamCard(
      padding: EdgeInsets.all(14.w),
      child: Row(
        children: [
          PmamAvatar(name: managerName, size: 52, fontSize: 18),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  managerName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: PmamColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        code.isEmpty ? '-' : code,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: PmamColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    const PmamStatusBadge(status: 'approved'),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (code.isNotEmpty) {
                // Clipboard logic would go here
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: PmamColors.primaryPurple,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Copy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Stats Grid ──────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final Map<dynamic, dynamic> stats;
  final String Function(dynamic) fmt;

  const _StatsGrid({required this.stats, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 90.h,
                child: PmamStatCard(
                  icon: Icons.remove_red_eye_outlined,
                  value: '${stats['total_plans'] ?? 0}',
                  label: 'Total Plans',
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: SizedBox(
                height: 90.h,
                child: PmamStatCard(
                  icon: Icons.people_rounded,
                  value: '${stats['active_investors'] ?? 0}',
                  label: 'Active Investors',
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: SizedBox(
                height: 90.h,
                child: PmamStatCard(
                  icon: Icons.timelapse_rounded,
                  value: '${stats['pending_requests'] ?? 0}',
                  label: 'Pending',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 90.h,
                child: PmamStatCard(
                  icon: Icons.lock_clock_rounded,
                  value: fmt(stats['total_locked_aum']),
                  label: 'Locked AUM',
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: SizedBox(
                height: 90.h,
                child: PmamStatCard(
                  icon: Icons.swap_horiz_rounded,
                  value: '${stats['total_lots_traded'] ?? 0}',
                  label: 'Lots Traded',
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: SizedBox(
                height: 90.h,
                child: PmamStatCard(
                  icon: Icons.bar_chart_rounded,
                  value: fmt(stats['total_pnl']),
                  label: 'Total P&L',
                  valueColor: (double.tryParse(
                              stats['total_pnl']?.toString() ?? '0') ??
                          0) >=
                      0
                      ? PmamColors.approvedGreenText
                      : PmamColors.rejectedRedText,
                  highlight: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ─── Commission Card ─────────────────────────────────────────────────────────

class _CommissionCard extends StatelessWidget {
  final Map<dynamic, dynamic> stats;
  final String Function(dynamic) fmt;

  const _CommissionCard({required this.stats, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return PmamCard(
      padding: EdgeInsets.all(14.w),
      borderColor: PmamColors.primaryPurple.withOpacity(0.35),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: PmamColors.primaryPurpleLight,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.payments_rounded,
              color: PmamColors.primaryPurple,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Commission Earned',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: PmamColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  fmt(stats['total_commission']),
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: PmamColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_graph_rounded,
            color: PmamColors.primaryPurple,
            size: 28.sp,
          ),
        ],
      ),
    );
  }
}

/// ─── Plan Card ───────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final status = (plan['status'] ?? '').toString();
    final planName = (plan['plan_name'] ?? 'Unnamed Plan').toString();
    final investors = plan['active_investors'] ?? 0;
    final commission = plan['commission_percentage'] ?? 0;
    final minInvest = plan['minimum_investment'] ?? 0;

    return PmamCard(
      onTap: () => Get.toNamed(
        AppPages.PMAM_MANAGER_PLAN_DETAIL,
        arguments: plan['id'],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  planName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: PmamColors.textPrimary,
                  ),
                ),
              ),
              PmamStatusBadge(status: status),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _MiniChip(label: '$investors Investors'),
              SizedBox(width: 8.w),
              _MiniChip(label: '$commission% Commission'),
              SizedBox(width: 8.w),
              _MiniChip(label: '\$$minInvest Min.'),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.toNamed(
                    AppPages.PMAM_MANAGER_PLAN_DETAIL,
                    arguments: plan['id'],
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: PmamColors.primaryPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    foregroundColor: PmamColors.primaryPurple,
                  ),
                  child: Text(
                    'View',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (status == 'approved') ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: PmamColors.rejectedRedText.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      foregroundColor: PmamColors.rejectedRedText,
                    ),
                    child: Text(
                      'Inactivate',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// ─── Mini Chip ───────────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: PmamColors.inactiveGrey,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: PmamColors.textPrimary,
        ),
      ),
    );
  }
}

/// ─── Investors Tab ───────────────────────────────────────────────────────────

class _InvestorsTab extends StatelessWidget {
  const _InvestorsTab();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PmamController>(
      init: Get.isRegistered<PmamController>()
          ? Get.find<PmamController>()
          : Get.put(PmamController()),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: PmamColors.scaffoldBg,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: PmamColors.scaffoldBg,
            elevation: 0,
            title: Text('My Investors', style: AppTextStyles.headingblack),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    color: PmamColors.primaryPurple, size: 22.sp),
                onPressed: () => ctrl.loadManagerInvestors(),
              ),
            ],
          ),
          body: Obx(() {
            if (ctrl.isLoading.value) {
              return Center(
                child: CommonLoadingWidget(
                    size: 40, color: PmamColors.primaryPurple),
              );
            }
            final requests = ctrl.investorRequests;
            final investors = ctrl.managerInvestors;

            return RefreshIndicator(
              color: PmamColors.primaryPurple,
              onRefresh: () => Future.wait([
                ctrl.loadManagerInvestors(),
                ctrl.loadManagerDashboard(),
              ]),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(requests: requests, investors: investors),
                    SizedBox(height: 16.h),
                    if (requests.isNotEmpty) ...[
                      PmamSectionHeader(title: 'Pending Requests'),
                      SizedBox(height: 10.h),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (_, i) =>
                            _InvestorRequestCard(request: requests[i]),
                      ),
                      SizedBox(height: 20.h),
                    ],
                    PmamSectionHeader(
                      title: 'All Investors',
                      actionLabel: 'View All',
                      onAction: () {},
                    ),
                    SizedBox(height: 10.h),
                    if (investors.isEmpty)
                      const PmamEmptyState(
                        icon: Icons.people_outline,
                        message: 'No investors yet',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: investors.length > 5 ? 5 : investors.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (_, i) =>
                            _InvestorCard(investor: investors[i]),
                      ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// ─── Summary Row ─────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<dynamic> requests;
  final List<dynamic> investors;

  const _SummaryRow({required this.requests, required this.investors});

  @override
  Widget build(BuildContext context) {
    final pending = requests.where((r) => r['status'] == 'pending').length;
    final active =
        investors.where((i) => i['status'] == 'active').length;
    final inactive =
        investors.where((i) => i['status'] == 'inactive').length;
    final rejected =
        investors.where((i) => i['status'] == 'rejected').length;

    return PmamCard(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(child: _SummaryItem(label: 'Total', value: '${investors.length}', valueColor: PmamColors.textPrimary)),
          _divider(),
          Expanded(child: _SummaryItem(label: 'Active', value: '$active', valueColor: PmamColors.approvedGreenText)),
          _divider(),
          Expanded(child: _SummaryItem(label: 'Inactive', value: '$inactive', valueColor: PmamColors.textSecondary)),
          _divider(),
          Expanded(child: _SummaryItem(label: 'Rejected', value: '$rejected', valueColor: PmamColors.rejectedRedText)),
          _divider(),
          Expanded(child: _SummaryItem(label: 'Pending', value: '$pending', valueColor: PmamColors.pendingAmberText)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30.h, color: PmamColors.borderLight);

  Widget _SummaryItem({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: PmamColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// ─── Investor Request Card ────────────────────────────────────────────────────

class _InvestorRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;

  const _InvestorRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final investorName = request['investor_name'] ?? request['name'] ?? 'Investor';
    final planName = request['plan_name'] ?? request['planName'] ?? '';
    final amount = request['amount'] ?? request['investment_amount'] ?? 0;

    return PmamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PmamAvatar(name: investorName.toString(), size: 40, fontSize: 14),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investorName.toString(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: PmamColors.textPrimary,
                      ),
                    ),
                    if (planName.isNotEmpty)
                      Text(
                        'Plan: $planName',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: PmamColors.textSecondary,
                        ),
                      ),
                    Text(
                      '\$$amount invested',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: PmamColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const PmamStatusBadge(status: 'pending', compact: true),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: PmamColors.rejectedRedText.withOpacity(0.6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    foregroundColor: PmamColors.rejectedRedText,
                  ),
                  child: Text('Reject', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PmamColors.approvedGreenText,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                  child: Text('Approve', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─── Investor Card ───────────────────────────────────────────────────────────

class _InvestorCard extends StatelessWidget {
  final Map<String, dynamic> investor;

  const _InvestorCard({required this.investor});

  @override
  Widget build(BuildContext context) {
    final name = investor['investor_name'] ?? investor['name'] ?? 'Investor';
    final status = (investor['status'] ?? 'active').toString();
    final aum = investor['invested_amount'] ?? investor['aum'] ?? 0;
    final planName = investor['plan_name'] ?? '';

    return PmamCard(
      onTap: () {
        final invId = int.tryParse(investor['id']?.toString() ?? '') ?? 0;
        Get.to(
          () => PmamManagerInvestorDetailScreen(
            investorId: invId,
            investorName: name.toString(),
          ),
        );
      },
      child: Row(
        children: [
          PmamAvatar(name: name.toString(), size: 40, fontSize: 14),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: PmamColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    if (planName.toString().isNotEmpty) ...[
                      Text(
                        'Plan: $planName',
                        style: TextStyle(fontSize: 11.sp, color: PmamColors.textSecondary),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      'AUM: \$$aum',
                      style: TextStyle(fontSize: 11.sp, color: PmamColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PmamStatusBadge(status: status, compact: true),
              SizedBox(height: 4.h),
              Icon(Icons.chevron_right_rounded, color: PmamColors.textHint, size: 18.sp),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PmamController>(
      init: Get.isRegistered<PmamController>()
          ? Get.find<PmamController>()
          : Get.put(PmamController()),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: PmamColors.scaffoldBg,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: PmamColors.scaffoldBg,
            elevation: 0,
            title: Text('Profile', style: AppTextStyles.headingblack),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: Obx(() {
            final stats = ctrl.dashboardStats;
            final managerName =
                (stats['manager_name'] ?? stats['name'] ?? 'Manager').toString();
            final code = ctrl.managerCode.value;
            final plans = ctrl.managerPlans;
            final approvedPlans =
                plans.where((p) => p['status'] == 'approved').length;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                children: [
                  PmamCard(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        PmamAvatar(name: managerName, size: 72, fontSize: 24),
                        SizedBox(height: 12.h),
                        Text(
                          managerName,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: PmamColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              code.isEmpty ? '-' : code,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: PmamColors.textSecondary,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            const PmamStatusBadge(status: 'approved'),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        const Divider(),
                        SizedBox(height: 12.h),
                        _ProfileInfoRow(
                          icon: Icons.description_outlined,
                          label: 'Total Plans',
                          value: '${plans.length}',
                        ),
                        SizedBox(height: 10.h),
                        _ProfileInfoRow(
                          icon: Icons.check_circle_outline,
                          label: 'Approved Plans',
                          value: '$approvedPlans',
                        ),
                        SizedBox(height: 10.h),
                        _ProfileInfoRow(
                          icon: Icons.people_outline,
                          label: 'Active Investors',
                          value: '${stats['active_investors'] ?? 0}',
                        ),
                        SizedBox(height: 10.h),
                        _ProfileInfoRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Total AUM',
                          value: '\$${stats['total_locked_aum'] ?? 0}',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  PmamCard(
                    onTap: () => Get.toNamed(AppPages.PMAM_CREATE_PLAN),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: PmamColors.primaryPurpleLight,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.add_circle_outline,
                            color: PmamColors.primaryPurple,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Create New Plan',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: PmamColors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: PmamColors.textHint, size: 22.sp),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  PmamCard(
                    onTap: () => Get.toNamed(AppPages.PMAM_MANAGER_PORTAL),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: PmamColors.primaryPurpleLight,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            color: PmamColors.primaryPurple,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Manager Portal',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: PmamColors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: PmamColors.textHint, size: 22.sp),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: PmamColors.primaryPurple),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: PmamColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: PmamColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
