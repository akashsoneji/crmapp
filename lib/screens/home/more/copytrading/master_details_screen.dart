import 'package:crm_app/constants/color.dart';
import 'package:crm_app/widgets/app_svg_back_button.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_details_controller.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_hub_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'subscribe_to_plan_screen.dart';

class MasterDetailsScreen extends StatelessWidget {
  final String masterCode;
  final String? masterNickname;
  const MasterDetailsScreen({
    super.key,
    required this.masterCode,
    this.masterNickname,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      CopyTradingMasterDetailsController(masterCode: masterCode),
    );

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          masterNickname?.isNotEmpty == true ? masterNickname! : 'Master',
          style: AppTextStyles.heading.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: AppSvgBackButton(
          onPressed: () => AppSvgBackButton.popRoute(context),
        ),
        actions: [
          IconButton(
            onPressed: () => controller.loadProfile(showLoading: true),
            icon: Icon(Icons.refresh, size: 20.r, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return _ErrorState(
            message: controller.errorMessage.value,
            onRetry: () => controller.loadProfile(showLoading: true),
          );
        }

        final profile = controller.profile.value;
        if (profile == null) {
          return const Center(child: Text('No data'));
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadProfile(showLoading: false),
          child: DefaultTabController(
            length: 2,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 22.h),
              children: [
                _MasterHeroCard(profile: profile, masterCode: masterCode),
                SizedBox(height: 12.h),
                _ViewByPlanCard(profile: profile, controller: controller),
                SizedBox(height: 12.h),
                _PerformanceCard(
                  profile: profile,
                  controller: controller,
                  masterCode: masterCode,
                ),
                SizedBox(height: 12.h),
                // _PlansCard(profile: profile, masterCode: masterCode),
                // SizedBox(height: 12.h),
                _OrdersCard(profile: profile),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _MasterHeroCard extends StatelessWidget {
  final CopyTradingMasterProfile profile;
  final String masterCode;
  const _MasterHeroCard({required this.profile, required this.masterCode});

  @override
  Widget build(BuildContext context) {
    final primaryPlan = profile.plans.isNotEmpty ? profile.plans.first : null;
    final minInvestment = primaryPlan?.minimumCapital ?? 0;
    final commission =
        primaryPlan?.commissionLabel.isNotEmpty == true
            ? primaryPlan!.commissionLabel
            : (primaryPlan?.commissionType ?? '');

    final sinceDays = _daysSince(profile.memberSince);
    final withUs = sinceDays == null ? '' : '${sinceDays}d';

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  (profile.nickname.isNotEmpty
                          ? profile.nickname
                          : profile.name)
                      .trim()
                      .toUpperCase()
                      .padRight(1)
                      .substring(0, 1),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nickname.isNotEmpty
                          ? profile.nickname
                          : profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Container(
                          width: 7.r,
                          height: 7.r,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Expert',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Risk score',
                  value:
                      profile.riskScore == null
                          ? '-'
                          : 'Risk ${profile.riskScore}',
                ),
              ),
              Expanded(
                child: _HeroStat(
                  label: 'Equity',
                  value: '\$${profile.masterEquity.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _HeroStat(
                  label: 'Commission',
                  value: commission.isNotEmpty ? commission : '-',
                ),
              ),
              Expanded(
                child: _HeroStat(
                  label: 'With Us',
                  value: withUs.isNotEmpty ? withUs : '-',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            // height: 44.h,
            child: ElevatedButton(
              onPressed:
                  primaryPlan == null ||
                          primaryPlan.isFull ||
                          primaryPlan.isEnrolled
                      ? null
                      : () async {
                        if (!Get.isRegistered<CopyTradingHubController>()) {
                          Get.put(CopyTradingHubController());
                        }
                        await Get.to(
                          () => SubscribeToPlanScreen(
                            masterCode: masterCode,
                            plan: primaryPlan,
                          ),
                        );
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.whiteColor,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Subscribe',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          if (minInvestment > 0)
            Text(
              'Minimum investment \$${minInvestment.toString()}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: AppColors.tradeBackgroundCenterColor.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.grey.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strategy Description',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  profile.strategyDescription.trim().isEmpty
                      ? 'No strategy description provided.'
                      : profile.strategyDescription,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int? _daysSince(String isoOrDate) {
  final dt = DateTime.tryParse(isoOrDate);
  if (dt == null) return null;
  final now = DateTime.now();
  final diff = now.difference(DateTime(dt.year, dt.month, dt.day)).inDays;
  return diff < 0 ? 0 : diff;
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewByPlanCard extends StatelessWidget {
  final CopyTradingMasterProfile profile;
  final CopyTradingMasterDetailsController controller;
  const _ViewByPlanCard({required this.profile, required this.controller});

  @override
  Widget build(BuildContext context) {
    final plans = profile.plans;
    if (plans.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'View by plan',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  _PlanChip(
                    label: 'All plans',
                    selected: controller.selectedPlanId.value.isEmpty,
                    onTap: () => controller.selectPlan(''),
                  ),
                  ...plans.map(
                    (plan) => Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: _PlanChip(
                        label: plan.planName,
                        selected:
                            controller.selectedPlanId.value ==
                            plan.planId.toString(),
                        onTap:
                            () => controller.selectPlan(plan.planId.toString()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PlanChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.withOpacity(0.22),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.whiteColor : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final CopyTradingMasterProfile profile;
  final CopyTradingMasterDetailsController controller;
  final String masterCode;
  const _PerformanceCard({
    required this.profile,
    required this.controller,
    required this.masterCode,
  });

  @override
  Widget build(BuildContext context) {
    final gainColor =
        profile.totalGainPercent >= 0 ? AppColors.green : AppColors.red;
    final pnlColor = profile.totalPnl >= 0 ? AppColors.green : AppColors.red;
    final ddColor =
        profile.maxDrawdown > 0 ? AppColors.red : AppColors.textPrimary;
    return Obx(() {
      if (controller.isPlanOrTimeframeLoading.value) {
        return Container(
          height: 80.h,
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Center(
            child: CommonLoadingWidget(size: 32.0, color: AppColors.primary),
          ),
        );
      }
      return Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Obx(
                  () => _TimeChip(
                    label: '7D',
                    selected: controller.selectedTimeframe.value == '7d',
                    onTap: () => controller.selectTimeframe('7d'),
                  ),
                ),
                SizedBox(width: 6.w),
                Obx(
                  () => _TimeChip(
                    label: '2W',
                    selected: controller.selectedTimeframe.value == '2w',
                    onTap: () => controller.selectTimeframe('2w'),
                  ),
                ),
                SizedBox(width: 6.w),
                Obx(
                  () => _TimeChip(
                    label: '1M',
                    selected: controller.selectedTimeframe.value == '1m',
                    onTap: () => controller.selectTimeframe('1m'),
                  ),
                ),
                SizedBox(width: 6.w),
                Obx(
                  () => _TimeChip(
                    label: '3M',
                    selected: controller.selectedTimeframe.value == '3m',
                    onTap: () => controller.selectTimeframe('3m'),
                  ),
                ),
                SizedBox(width: 6.w),
                Obx(
                  () => _TimeChip(
                    label: '6M',
                    selected: controller.selectedTimeframe.value == '6m',
                    onTap: () => controller.selectTimeframe('6m'),
                  ),
                ),
                SizedBox(width: 6.w),
                Obx(
                  () => _TimeChip(
                    label: 'ALL',
                    selected: controller.selectedTimeframe.value == 'all',
                    onTap: () => controller.selectTimeframe('all'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _PerfStat(
                    label: 'Total Gain',
                    value:
                        '${profile.totalGainPercent >= 0 ? '+' : ''}${profile.totalGainPercent.toStringAsFixed(2)}%',
                    valueColor: gainColor,
                  ),
                ),
                Expanded(
                  child: _PerfStat(
                    label: 'Copiers',
                    value: profile.totalCopiers.toString(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _PerfStat(
                    label: 'Total P&L',
                    value:
                        '${profile.totalPnl >= 0 ? '+' : ''}\$${profile.totalPnl.toStringAsFixed(2)}',
                    valueColor: pnlColor,
                  ),
                ),
                Expanded(
                  child: _PerfStat(
                    label: 'Max drawdown',
                    value: '${profile.maxDrawdown.toStringAsFixed(2)}%',
                    valueColor: ddColor,
                    showUnderline: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _PerfStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool showUnderline;
  const _PerfStat({
    required this.label,
    required this.value,
    this.valueColor,
    this.showUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w700,
              decoration:
                  showUnderline
                      ? TextDecoration.underline
                      : TextDecoration.none,
              decorationColor: AppColors.textGrey,
              decorationStyle: TextDecorationStyle.dotted,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _TimeChip({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.textPrimary
                  : AppColors.tradeBackgroundCenterColor.withOpacity(0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.whiteColor : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  final String label;
  final String value;
  const _PlanStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _OrdersCard extends StatelessWidget {
  final CopyTradingMasterProfile profile;
  const _OrdersCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final closed = profile.tradeHistory;
    final open = profile.openPositions;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            tabs: [
              Tab(text: 'Closed orders (${closed.length})'),
              Tab(text: 'Open orders (${open.length})'),
            ],
          ),
          SizedBox(
            height: 360.h,
            child: TabBarView(
              children: [
                _OrdersTable(items: closed, statusLabel: 'Closed'),
                _OrdersTable(items: open, statusLabel: 'Open'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  final List<CopyTradingTradeItem> items;
  final String statusLabel;
  const _OrdersTable({required this.items, required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No orders',
          style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        return _OrderCard(item: items[index], statusLabel: statusLabel);
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final CopyTradingTradeItem item;
  final String statusLabel;
  const _OrderCard({required this.item, required this.statusLabel});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  bool isXAU(String symbol) =>
      symbol.toUpperCase().contains('XAU') ||
      symbol.toUpperCase().contains('GOLD');

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isBuy = item.side.toUpperCase() == 'BUY';
    final isProfit = item.profit >= 0;
    final sideColor = isBuy ? AppColors.green : AppColors.red;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            // ── Always-visible header row ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.symbol,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            '\u2013',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textGrey,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            item.volume.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: sideColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              item.side.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: sideColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isProfit ? '+' : ''}\$${item.profit.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: isProfit ? AppColors.green : AppColors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 8.w),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: _expanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textGrey,
                    size: 20.r,
                  ),
                ),
              ],
            ),

            // ── Expanded details ──────────────────────────────────────
            if (_expanded) ...[
              SizedBox(height: 12.h),
              Divider(color: Colors.grey.withOpacity(0.12), height: 1),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _TField(label: 'Order ID', value: '#${item.id}'),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: _TField(
                      label: 'Volume',
                      value: item.volume.toStringAsFixed(2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _TField(
                      label: 'Open Price',
                      value: item.openPrice.toDouble().toStringAsFixed(
                        isXAU(item.symbol) ? 2 : 5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: _TField(
                      label: 'Opened',
                      value: _formatTime(item.openTime),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _TField(
                      label:
                          widget.statusLabel.toLowerCase() == 'closed'
                              ? 'Close Price'
                              : 'Side',
                      value:
                          widget.statusLabel.toLowerCase() == 'closed'
                              ? item.closePrice.toDouble().toStringAsFixed(
                                isXAU(item.symbol) ? 2 : 5,
                              )
                              : item.side.toUpperCase(),
                      valueColor:
                          widget.statusLabel.toLowerCase() == 'closed'
                              ? null
                              : sideColor,
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: _TField(
                      label:
                          widget.statusLabel.toLowerCase() == 'closed'
                              ? 'Closed'
                              : 'Status',
                      value:
                          widget.statusLabel.toLowerCase() == 'closed'
                              ? _formatTime(item.closeTime)
                              : widget.statusLabel,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    if (iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _TField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _TField({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40.r, color: AppColors.red),
            SizedBox(height: 10.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
