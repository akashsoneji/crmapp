import 'package:crm_app/screens/home/trading_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_dashboard_controller.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_hub_controller.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/screens/home/more/copytrading/copy_trading_create_plan_screen.dart';
import 'package:crm_app/screens/home/more/copytrading/master_plan_detail_screen.dart';

class MyPlansTab extends StatefulWidget {
  const MyPlansTab({super.key});

  @override
  State<MyPlansTab> createState() => _MyPlansTabState();
}

class _MyPlansTabState extends State<MyPlansTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Newest first'; // 'Newest first', 'Name A-Z', 'Highest AUM'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreatePlanScreen(CopyTradingMasterDashboardController controller) {
    Get.to(
      () => CopyTradingCreatePlanScreen(controller: controller),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
  }

  List<CopyTradingMasterPlanItem> _getFilteredAndSortedPlans(
    List<CopyTradingMasterPlanItem> plans,
  ) {
    // Create a copy to prevent mutating the reactive list during build
    List<CopyTradingMasterPlanItem> result = List.from(plans);

    // 1. Filter
    if (_searchQuery.isNotEmpty) {
      result =
          result.where((plan) {
            final nameMatch = plan.planName.toLowerCase().contains(
              _searchQuery,
            );
            final idMatch = plan.id.toString().contains(_searchQuery);
            final accountMatch = plan.tradingAccountNumber.contains(
              _searchQuery,
            );
            return nameMatch || idMatch || accountMatch;
          }).toList();
    }

    // 2. Sort
    if (_sortBy == 'Newest first') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'Name A-Z') {
      result.sort(
        (a, b) => a.planName.toLowerCase().compareTo(b.planName.toLowerCase()),
      );
    } else if (_sortBy == 'Highest AUM') {
      result.sort((a, b) => b.totalCapital.compareTo(a.totalCapital));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final hubController = Get.find<CopyTradingHubController>();
    final controller = Get.put(
      CopyTradingMasterDashboardController(
        masterCode: hubController.masterCode.value,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/svg/ib_dashboard/home.svg',
            colorFilter: ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Get.offAll(() => const TradingMainScreen()),
        ),
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'My Copy Plans',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 16.sp),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: GestureDetector(
                onTap: () => _openCreatePlanScreen(controller),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14.sp, color: AppColors.whiteColor),
                      SizedBox(width: 4.w),
                      Text(
                        'Create Plan',
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Search & Sort bar at the top - Outside RefreshIndicator to avoid RenderViewportBase._paintContents viewport error
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42.h,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.12),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search plan name, ID...',
                          hintStyle: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textGrey,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18.r,
                            color: AppColors.textGrey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    height: 42.h,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.12),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18.r,
                          color: AppColors.textGrey,
                        ),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _sortBy = newValue;
                            });
                          }
                        },
                        items:
                            <String>[
                              'Newest first',
                              'Name A-Z',
                              'Highest AUM',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable list is inside RefreshIndicator directly
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.refreshAll(showLoading: false),
                child: Obx(() {
                  final loading = controller.isLoading.value;
                  final allPlans = controller.plans;

                  if (loading && allPlans.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (allPlans.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 50.h),
                        _buildEmptyState(controller),
                      ],
                    );
                  }

                  final filteredSortedPlans = _getFilteredAndSortedPlans(
                    allPlans,
                  );

                  if (filteredSortedPlans.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 60.h),
                          alignment: Alignment.center,
                          child: Text(
                            'No plans found matching filters',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                    itemCount: filteredSortedPlans.length,
                    separatorBuilder: (_, index) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final plan = filteredSortedPlans[index];
                      return _PlanCardItem(plan: plan, controller: controller);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
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
              color: AppColors.textGrey.withValues(alpha: 0.5),
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
                // padding: EdgeInsets.zero,
                backgroundColor: AppColors.primary,
                foregroundColor:
                    AppColors.primary.computeLuminance() > 0.5
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

class _PlanCardItem extends StatelessWidget {
  final CopyTradingMasterPlanItem plan;
  final CopyTradingMasterDashboardController controller;

  const _PlanCardItem({required this.plan, required this.controller});

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

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = plan.status;
    final isApproved = status.toLowerCase() == 'approved';
    final pauseLabel = plan.copyingPaused ? 'Resume copying' : 'Pause copying';

    final screenWidth = MediaQuery.of(context).size.width;
    final cellWidth = (screenWidth - 32.w - 24.r - 8.w) / 2;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Purple Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            color: AppColors.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.planName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.whiteColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    '#${plan.id}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sub-header for Status and Copying State
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 4.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  plan.copyingPaused ? 'Copying paused' : 'Copying on',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color:
                        plan.copyingPaused ? AppColors.error : AppColors.green,
                  ),
                ),
              ],
            ),
          ),

          // Metrics 2-column Compact Grid
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _metricBox(
                  cellWidth,
                  'PLAN EQUITY (AUM)',
                  '\$${plan.totalCapital.toStringAsFixed(2)}',
                ),
                _metricBox(
                  cellWidth,
                  'COPIERS',
                  '${plan.activeCopiersCount}${plan.maxCopiers != null ? ' / ${plan.maxCopiers}' : ''}',
                ),
                _metricBox(cellWidth, 'PLAN FULL', plan.isFull ? 'Yes' : 'No'),
                _metricBox(
                  cellWidth,
                  'COMMISSION',
                  plan.commissionLabel.isNotEmpty ? plan.commissionLabel : '—',
                ),
                _metricBox(
                  cellWidth,
                  'COMMISSION TYPE',
                  plan.commissionType.toUpperCase(),
                ),
                _metricBox(
                  cellWidth,
                  'SUBSCRIPTION FEE',
                  '\$${plan.subscriptionFee.toStringAsFixed(2)}',
                ),
                _metricBox(
                  cellWidth,
                  'MIN. CAPITAL',
                  '\$${plan.minimumCapital.toStringAsFixed(2)}',
                ),
                _metricBox(cellWidth, 'COPY RATIO', plan.copyRatio.toString()),
                _metricBox(
                  cellWidth,
                  'TRADING ACCOUNT',
                  plan.tradingAccountNumber,
                ),
                _metricBox(cellWidth, 'SERVER / PROVIDER', plan.tradingServer),
                _metricBox(cellWidth, 'CREATED', _formatDate(plan.createdAt)),
              ],
            ),
          ),

          // Strategy Description section
          if (plan.strategyDescription.trim().isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STRATEGY',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    plan.strategyDescription,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.1)),

          // Actions Row
          Padding(
            padding: EdgeInsets.all(8.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Get.to(() => MasterPlanDetailScreen(planId: plan.id));
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                  child: Text(
                    'View details',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                TextButton(
                  onPressed: () => _openEditPlanDialog(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                  child: Text(
                    'Edit plan',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (isApproved) ...[
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => _togglePauseCopying(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          plan.copyingPaused
                              ? AppColors.green
                              : AppColors.warning,
                      foregroundColor: AppColors.whiteColor,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    child: Text(
                      pauseLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(double width, String label, String value) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.tradeBackgroundCenterColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textGrey,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _togglePauseCopying(BuildContext context) async {
    final actionText = plan.copyingPaused ? 'Resume copying' : 'Pause copying';
    final confirmationMessage =
        plan.copyingPaused
            ? 'Are you sure you want to resume copying for "${plan.planName}"?'
            : 'Are you sure you want to pause copying for "${plan.planName}"? Copying will be suspended until you resume.';

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(actionText),
            content: Text(confirmationMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final res =
                      plan.copyingPaused
                          ? await controller.resumePlan(planId: plan.id)
                          : await controller.pausePlan(planId: plan.id);
                  if (res.success) {
                    CustomToastService.showSuccess(
                      title: 'Success',
                      message: res.message ?? 'State updated successfully',
                    );
                  } else {
                    CustomToastService.showError(
                      title: 'Failed',
                      message:
                          res.message ?? 'Failed to update plan copying state',
                    );
                  }
                },
                child: Text(
                  plan.copyingPaused ? 'Resume' : 'Pause',
                  style: TextStyle(
                    color:
                        plan.copyingPaused
                            ? AppColors.green
                            : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _openEditPlanDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: plan.planName);
    final strategyCtrl = TextEditingController(text: plan.strategyDescription);
    final riskCtrl = TextEditingController(text: plan.riskInformation);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            title: Text(
              'Edit plan',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            content: SizedBox(
              width: 320.w,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          'This plan has active copiers. You can update the plan name and descriptions only. To change fees or limits, copiers must leave first.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.primary,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Plan name *',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: nameCtrl,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter plan name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        'Strategy description',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: strategyCtrl,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter strategy description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.all(12.r),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        'Risk information',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: riskCtrl,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter risk information',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.all(12.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(ctx).pop();
                    final body = {
                      'plan_name': nameCtrl.text.trim(),
                      'strategy_description': strategyCtrl.text.trim(),
                      'risk_information': riskCtrl.text.trim(),
                    };
                    final res = await controller.updatePlan(
                      planId: plan.id,
                      body: body,
                    );
                    if (res.success) {
                      CustomToastService.showSuccess(
                        title: 'Success',
                        message: res.message ?? 'Plan updated successfully',
                      );
                    } else {
                      CustomToastService.showError(
                        title: 'Failed',
                        message: res.message ?? 'Failed to update plan',
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.whiteColor,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}
