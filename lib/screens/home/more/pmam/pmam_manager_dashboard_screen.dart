import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/pmam/pmam_controller.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';

class PmamManagerDashboardScreen extends StatefulWidget {
  const PmamManagerDashboardScreen({super.key});

  @override
  State<PmamManagerDashboardScreen> createState() =>
      _PmamManagerDashboardScreenState();
}

class _PmamManagerDashboardScreenState
    extends State<PmamManagerDashboardScreen> {
  late final PmamController _ctrl;

  @override
  void initState() {
    if (Get.isRegistered<PmamController>()) {
      _ctrl = Get.find<PmamController>();
    } else {
      _ctrl = Get.put(PmamController());
    }
    _ctrl.loadManagerDashboard();
    super.initState();
  }

  String _fmt(dynamic val) {
    if (val == null) return '\$0';
    final d = double.tryParse(val.toString()) ?? 0.0;
    if (d.abs() >= 1000) {
      return '\$${(d / 1000).toStringAsFixed(1)}K';
    }
    return '\$${d.toStringAsFixed(2)}';
  }

  String _fmtNum(dynamic val) {
    return val?.toString() ?? '0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
        ),

        title: Text('Manager Dashboard', style: AppTextStyles.heading),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 22.sp,
            ),
            onPressed: _ctrl.loadManagerDashboard,
          ),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) {
          return Center(
            child: CommonLoadingWidget(size: 40, color: AppColors.primary),
          );
        }
        final stats = _ctrl.dashboardStats;
        final plans = _ctrl.managerPlans;
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _ctrl.loadManagerDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Manager Profile Card
                _buildProfileCard(),
                SizedBox(height: 16.h),

                // Unified Stats Grid
                Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: [
                    _DashboardStatCard(
                      icon: Icons.show_chart_rounded,
                      label: 'Total Plans',
                      value: _fmtNum(stats['total_plans']),
                    ),
                    _DashboardStatCard(
                      icon: Icons.people_rounded,
                      label: 'Active Investors',
                      value: _fmtNum(stats['active_investors']),
                    ),
                    _DashboardStatCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pending Requests',
                      value: _fmtNum(stats['pending_requests']),
                    ),
                    _DashboardStatCard(
                      icon: Icons.lock_rounded,
                      label: 'Locked AUM',
                      value: _fmt(stats['total_locked_aum']),
                    ),
                    _DashboardStatCard(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Lots Traded',
                      value:
                          (stats['total_lots_traded'] ?? 0)
                              .toString()
                              .split('.')
                              .first,
                    ),
                    _DashboardStatCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'Total P&L',
                      value: _fmt(stats['total_pnl']),
                      isMoney: true,
                      positive:
                          (double.tryParse(
                                stats['total_pnl']?.toString() ?? '0',
                              ) ??
                              0) >=
                          0,
                    ),
                    _DashboardStatCard(
                      icon: Icons.payments_rounded,
                      label: 'Commission Earned',
                      value: _fmt(stats['total_commission']),
                      isMoney: true,
                      positive: true,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // My Plans header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Plans',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        _OutlineButton(
                          label: 'Portal',
                          onTap:
                              () => Get.toNamed(AppPages.PMAM_MANAGER_PORTAL),
                        ),
                        SizedBox(width: 8.w),
                        _FillButton(
                          label: '+ New Plan',
                          onTap: () => Get.toNamed(AppPages.PMAM_CREATE_PLAN),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Plans list
                if (plans.isEmpty)
                  _EmptyState(
                    icon: Icons.description_outlined,
                    message: 'No plans yet. Create your first plan!',
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: plans.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder:
                        (_, i) => _PlanCard(
                          plan: plans[i],
                          onView:
                              () => Get.toNamed(AppPages.PMAM_MANAGER_PLAN_DETAIL, arguments: plans[i]['id']),
                          onInactivate:
                              () => _ctrl.inactivatePlan(plans[i]['id'] ?? 0),
                        ),
                  ),
                SizedBox(height: 80.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileCard() {
    final code = _ctrl.managerCode.value;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manager Profile',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Your Manager ID (PAM Code)',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tradeBackgroundCenterColor,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Text(
                    code.isEmpty ? 'Not assigned yet' : code,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  if (code.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: code));
                    Get.snackbar(
                      'Copied',
                      'Manager code copied to clipboard',
                      backgroundColor: AppColors.primary,
                      colorText: AppColors.whiteColor,
                      snackPosition: SnackPosition.TOP,
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Copy',
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Obx(
            () => Text(
              '${_ctrl.managerPlans.where((p) => p['status'] == 'approved').length} Approved Plan(s)',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMoney;
  final bool? positive;

  const _DashboardStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isMoney = false,
    this.positive,
  });

  @override
  Widget build(BuildContext context) {
    // 2 columns, minus horizontal padding (32) and spacing (12)
    final w = (MediaQuery.of(context).size.width - 32.w - 12.w) / 2;

    Color mainColor = AppColors.primary;
    if (isMoney) {
      if (positive == true)
        mainColor = AppColors.green;
      else if (positive == false)
        mainColor = AppColors.red;
    }

    return Container(
      width: w,
      height: 76.h,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border:
            isMoney
                ? Border.all(color: mainColor.withOpacity(0.35), width: 1.5)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: mainColor, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isMoney ? mainColor : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textGrey,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onView;
  final VoidCallback onInactivate;

  const _PlanCard({
    required this.plan,
    required this.onView,
    required this.onInactivate,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.green;
      case 'pending_admin':
        return const Color(0xFFF59E0B);
      case 'inactive':
        return AppColors.textGrey;
      default:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (plan['status'] ?? '').toString();
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan['plan_name'] ?? 'Unnamed Plan',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  status == 'approved'
                      ? 'Approved'
                      : status == 'pending_admin'
                      ? 'Pending'
                      : status == 'inactive'
                      ? 'Inactive'
                      : status,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: _statusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _InfoChip(
                label: 'Investors',
                value: '${plan['active_investors'] ?? 0}',
              ),
              SizedBox(width: 8.w),
              _InfoChip(
                label: 'Commission',
                value: '${plan['commission_percentage'] ?? 0}%',
              ),
              SizedBox(width: 8.w),
              _InfoChip(
                label: 'Min. Invest',
                value: '\$${plan['minimum_investment'] ?? 0}',
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onView,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                  child: Text(
                    'View',
                    style: TextStyle(
                      color: AppColors.primary,
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
                    onPressed: onInactivate,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.red.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                    child: Text(
                      'Inactivate',
                      style: TextStyle(
                        color: AppColors.red,
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.tradeBackgroundCenterColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          Icon(icon, size: 48.sp, color: AppColors.grey),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
