import 'package:crm_app/constants/color.dart';
import 'package:crm_app/widgets/app_svg_back_button.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'copy_trading_create_plan_screen.dart';
import 'master_plan_detail_screen.dart';

class MasterDashboardScreen extends StatelessWidget {
  final String masterCode;
  const MasterDashboardScreen({super.key, required this.masterCode});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CopyTradingMasterDashboardController(masterCode: masterCode));

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Master Dashboard',
          style: AppTextStyles.heading.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: AppSvgBackButton(
          onPressed: () => AppSvgBackButton.popRoute(context),
          iconWidth: 30.w,
          iconHeight: 30.h,
        ),
        actions: [
          IconButton(
            onPressed: () => controller.refreshAll(showLoading: true),
            icon: Icon(Icons.refresh, size: 20.r, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.stats.value == null && controller.plans.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshAll(showLoading: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
            children: [
              _MasterProfileCard(masterCode: masterCode),
              SizedBox(height: 8.h),
              _StatsGrid(stats: controller.stats.value),
              SizedBox(height: 8.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 ElevatedButton.icon(
                   onPressed: () => _openCreatePlanScreen(controller),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary,
                     foregroundColor: AppColors.whiteColor,
                     // Override global theme's minimumSize (which is infinity width).
                     minimumSize: Size(double.maxFinite, 40.h),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12.r),
                     ),
                   ),
                   icon: Icon(Icons.add, size: 18.r),
                   label: const Text(
                     'Create Plan',
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                 ),
                ],
              ),
              SizedBox(height: 12.h),
              if (controller.plans.isEmpty)
                _EmptyPlans(onCreate: () => _openCreatePlanScreen(controller))
              else
                ...controller.plans.map((p) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _PlanTile(plan: p, controller: controller),
                    )),
              SizedBox(height: 24.h),
            ],
          ),
        );
      }),
    );
  }

  void _openCreatePlanScreen(CopyTradingMasterDashboardController controller) {
    Get.to(
      () => CopyTradingCreatePlanScreen(controller: controller),
    );
  }
}

class _MasterProfileCard extends StatelessWidget {
  final String masterCode;
  const _MasterProfileCard({required this.masterCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal:14.w,vertical: 8.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Master Profile', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SizedBox(height: 10.h),
          Text('Your Master Code', style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.tradeBackgroundCenterColor.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.12)),
                  ),
                  child: Text(masterCode, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w400, color: AppColors.textPrimary)),
                ),
              ),
              SizedBox(width: 10.w),
              ElevatedButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: masterCode));
                  Get.snackbar('Copied', 'Master code copied', snackPosition: SnackPosition.BOTTOM);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.whiteColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  elevation: 0,
                  // Override global theme's minimumSize (which is infinity width).
                  minimumSize: Size(60.w, 32.h),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Copy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final CopyTradingMasterDashboardStats? stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(title: 'TOTAL PLANS', value: s?.plansCount.toString() ?? '—')),
            SizedBox(width: 12.w),
            Expanded(child: _StatCard(title: 'ACTIVE COPIERS', value: s?.activeCopiersCount.toString() ?? '—')),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _StatCard(title: 'AUM', value: s == null ? '—' : '\$${s.totalAum.toStringAsFixed(2)}')),
            SizedBox(width: 12.w),
            Expanded(
              child: _StatCard(
                title: 'COMMISSION EARNED',
                value: s == null ? '—' : '\$${s.commissionEarned.toStringAsFixed(2)}',
                highlight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool highlight;
  const _StatCard({required this.title, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: highlight ? AppColors.green.withOpacity(0.08) : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: highlight ? AppColors.green : AppColors.border.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.insights, size: 18.r, color: AppColors.primary),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 10.sp, color: AppColors.textGrey, fontWeight: FontWeight.w400),maxLines: 1, overflow: TextOverflow.ellipsis,),
                SizedBox(height: 4.h),
                Text(value, style: TextStyle(fontSize: 14.sp, color: highlight ? AppColors.green : AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyPlans({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Text('No plans yet', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SizedBox(height: 6.h),
          Text(
            'Create your first plan to start accepting copiers.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 14.h),
          ElevatedButton(
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.whiteColor),
            child: const Text('Create Plan'),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final CopyTradingMasterPlanItem plan;
  final CopyTradingMasterDashboardController controller;

  const _PlanTile({required this.plan, required this.controller});

  @override
  Widget build(BuildContext context) {
    final status = plan.status;
    final statusLower = status.toLowerCase();

    final statusColor = statusLower == 'approved'
        ? AppColors.green
        : statusLower.contains('pending')
            ? AppColors.warning
            : statusLower.contains('inactive')
                ? AppColors.textGrey
                : AppColors.error;

    final canInactivate = statusLower == 'approved' && plan.activeCopiersCount == 0;
    final planSubtitle = (plan.commissionLabel.isNotEmpty ? plan.commissionLabel : plan.commissionType);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: AppColors.border.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
          initiallyExpanded: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.planName,
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                         if (planSubtitle.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  planSubtitle,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400, color: AppColors.textGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10.r)),
                    child: Text(status, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: statusColor)),
                  ),
                ],
              ),
             
            ],
          ),
          trailing: Icon(Icons.expand_more, color: AppColors.textGrey, size: 20.r),
          children: [
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                              _metric(label: 'Copiers', value: plan.activeCopiersCount.toString()),
                      SizedBox(height: 8.h),
                      _metric(label: 'AUM', value: '\$${plan.totalCapital.toStringAsFixed(2)}'),
                      SizedBox(height: 8.h),
                      _metric(label: 'Min. capital', value: '\$${plan.minimumCapital.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                SizedBox(
                  width: 112.w,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 34.h,
                        child: OutlinedButton(
                        onPressed: () {
                          Get.to(() => MasterPlanDetailScreen(planId: plan.id));
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          // Override global theme minimumSize (may be infinity width)
                          minimumSize: Size(0, 34.h),
                          side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text('Details', style: TextStyle(color: AppColors.primary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        width: double.infinity,
                        height: 34.h,
                        child: ElevatedButton(
                        onPressed: canInactivate
                            ? () async {
                                final ok = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: Text('Inactivate Plan'),
                                    content: Text('This will inactivate the plan. You can only inactivate when status is approved and active copiers = 0.'),
                                    actions: [
                                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Get.back(result: true), child: const Text('Inactivate')),
                                    ],
                                  ),
                                );
                                if (ok != true) return;

                                final res = await controller.inactivatePlan(planId: plan.id);
                                if (res.success) {
                                  CustomToastService.showSuccess(message: res.message ?? 'Plan inactivated', title: 'Success');
                                } else {
                                  CustomToastService.showError(message: res.message ?? controller.errorMessage.value, title: 'Error');
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          // Override global theme minimumSize (may be infinity width)
                          minimumSize: Size(0, 34.h),
                          backgroundColor: canInactivate ? AppColors.error : AppColors.textGrey.withOpacity(0.15),
                          foregroundColor: canInactivate ? AppColors.whiteColor : AppColors.textGrey,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Inactivate',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}

Widget _metric({required String label, required String value}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
      SizedBox(height: 4.h),
      Text(value, style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
    ],
  );
}
