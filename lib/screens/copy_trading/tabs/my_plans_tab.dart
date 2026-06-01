import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_dashboard_controller.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_hub_controller.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/screens/home/more/copytrading/copy_trading_create_plan_screen.dart';
import 'package:crm_app/screens/home/more/copytrading/master_plan_detail_screen.dart';

class MyPlansTab extends StatelessWidget {
  const MyPlansTab({super.key});

  void _openCreatePlanScreen(CopyTradingMasterDashboardController controller) {
    Get.to(
      () => CopyTradingCreatePlanScreen(controller: controller),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hubController = Get.find<CopyTradingHubController>();
    final controller = Get.put(CopyTradingMasterDashboardController(masterCode: hubController.masterCode.value));

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'My Copy Plans',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 16.sp),
        ),
        actions: [
          IconButton(
            onPressed: () => controller.loadEligibleAccountsForCreatePlan(),
            icon: Icon(Icons.refresh, size: 20.r, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshAll(showLoading: false),
        child: Obx(() {
          final loading = controller.isLoading.value;
          final plans = controller.plans;

          if (loading && plans.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (plans.isEmpty) {
            return _buildEmptyState(controller);
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 80.h),
            itemCount: plans.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _PlanTileItem(plan: plan, controller: controller);
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreatePlanScreen(controller),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primary.computeLuminance() > 0.5
            ? AppColors.textPrimaryLight
            : AppColors.onColoredBackground,
        icon: const Icon(Icons.add),
        label: const Text('Create Plan'),
      ),
    );
  }

  Widget _buildEmptyState(CopyTradingMasterDashboardController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48.r,
              color: AppColors.textGrey.withOpacity(0.5),
            ),
            SizedBox(height: 14.h),
            Text(
              'No Copy Plans Yet',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Create a copying plan to start sharing your trades with investors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textGrey,
                height: 1.3,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _openCreatePlanScreen(controller),
              icon: const Icon(Icons.add),
              label: const Text('Create First Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primary.computeLuminance() > 0.5
                    ? AppColors.textPrimaryLight
                    : AppColors.onColoredBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTileItem extends StatelessWidget {
  final CopyTradingMasterPlanItem plan;
  final CopyTradingMasterDashboardController controller;

  const _PlanTileItem({required this.plan, required this.controller});

  Color _getStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':
      case 'approved':
        return AppColors.green;
      case 'pending':
        return AppColors.warning;
      case 'inactive':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = plan.status;
    final statusLower = status.toLowerCase();
    final canInactivate = statusLower == 'approved' && plan.activeCopiersCount == 0;
    final planSubtitle = (plan.commissionLabel.isNotEmpty ? plan.commissionLabel : plan.commissionType);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.textGrey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Get.to(() => MasterPlanDetailScreen(planId: plan.id));
        },
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.planName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (planSubtitle.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            planSubtitle,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Metrics row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _metric(label: 'Copiers', value: plan.activeCopiersCount.toString()),
                  _metric(label: 'AUM', value: '\$${plan.totalCapital.toStringAsFixed(2)}'),
                  _metric(label: 'Min. Capital', value: '\$${plan.minimumCapital.toStringAsFixed(2)}'),
                ],
              ),

              // Inactivate action
              if (canInactivate) ...[
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _confirmInactivate(context),
                    icon: Icon(Icons.power_settings_new, size: 14.r, color: AppColors.error),
                    label: Text(
                      'Inactivate',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.error),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      backgroundColor: AppColors.error.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppColors.textGrey),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _confirmInactivate(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inactivate Plan'),
        content: Text('Are you sure you want to inactivate the plan "${plan.planName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final res = await controller.inactivatePlan(planId: plan.id);
              if (res.success) {
                CustomToastService.showSuccess(
                  title: 'Success',
                  message: res.message ?? 'Plan inactivated successfully',
                );
              } else {
                CustomToastService.showError(
                  title: 'Failed',
                  message: res.message ?? 'Failed to inactivate plan',
                );
              }
            },
            child: Text(
              'Inactivate',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
