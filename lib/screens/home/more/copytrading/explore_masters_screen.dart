import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_masters_controller.dart';
import 'package:crm_app/screens/home/more/copytrading/master_details_screen.dart';

/// Explore Masters — public list of available master traders.
///
/// Re-designed to match the web portal:
///  • 4 summary cards (Available / Community AUM / Avg Gain / Enrolled)
///  • Tab bar (All / Enrolled / Discover) with counts
///  • Filter chips (Risk / Time / Sort)
///  • One master card per row (mobile-friendly horizontal layout)
class ExploreMastersScreen extends StatelessWidget {
  const ExploreMastersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CopyTradingMastersController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        elevation: 0.5,
        scrolledUnderElevation: 0,
        title: Text(
          'Explore Masters',
          style: AppTextStyles.heading.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppColors.textPrimary,
              size: 22.sp,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              controller.refreshMasters();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.allMasters.isEmpty) {
          return const _LoadingList();
        }
        if (controller.errorMessage.value.isNotEmpty &&
            controller.allMasters.isEmpty) {
          return _ErrorState(
            message: controller.errorMessage.value,
            onRetry: controller.refreshMasters,
          );
        }

        // ─── Filtered view ─────────────────────────────────────────
        final filter = controller.selectedFilter.value;
        final filtered = controller.allMasters.where((m) {
          if (filter == MasterFilterTab.enrolled) return m.isEnrolled;
          if (filter == MasterFilterTab.discover) return !m.isEnrolled;
          return true;
        }).toList();
        // Apply search
        final q = controller.searchQuery.value.trim().toLowerCase();
        final visible = q.isEmpty
            ? filtered
            : filtered
                  .where(
                  (m) =>
                        m.nickname.toLowerCase().contains(q) ||
                        m.name.toLowerCase().contains(q) ||
                        m.masterCode.toLowerCase().contains(q),
                  )
                  .toList();

        return RefreshIndicator(
          onRefresh: controller.refreshMasters,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 24.h),
            children: [
              _SummaryCards(controller: controller),
              SizedBox(height: 14.h),
              _FilterTabs(controller: controller),
              SizedBox(height: 10.h),
              _FilterChips(controller: controller),
              SizedBox(height: 14.h),
              if (visible.isEmpty)
                _NoSearchMatchesState(query: controller.searchQuery.value)
              else
                ...visible.map(
                  (m) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _MasterCardHorizontal(
                      item: m,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Get.to(
                          () => MasterDetailsScreen(
                            masterCode: m.masterCode,
                          ),
                        );
                      },
                      onCopy: () {
                        HapticFeedback.selectionClick();
                        // Navigate to master details first so the user can
                        // pick a plan before opening the subscribe modal.
                        Get.to(
                          () => MasterDetailsScreen(masterCode: m.masterCode),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────── summary cards (4-up) ───────────────────────────

class _SummaryCards extends StatelessWidget {
  final CopyTradingMastersController controller;
  const _SummaryCards({required this.controller});

  @override
  Widget build(BuildContext context) {
    final all = controller.allMasters;
    final communityAum = all.fold<double>(
      0,
      (sum, m) => sum + (m.totalAum as num).toDouble(),
    );
    final gains = all
        .map((m) => (m.totalGainPercent as num).toDouble())
        .where((g) => g != 0)
        .toList();
    final avgGain = gains.isEmpty
        ? 0.0
        : gains.reduce((a, b) => a + b) / gains.length;
    final enrolled = all.where((m) => m.isEnrolled).length;

    return LayoutBuilder(
      builder: (_, c) {
        final gap = 8.w;
        final cardW = (c.maxWidth - gap) / 2;
        final cardH = 78.h;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardW,
              height: cardH,
              child: _SummaryCard(
                label: 'Available Masters',
                value: '${all.length}',
                icon: Icons.grid_view_rounded,
                tag: 'Browse all',
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: cardW,
              height: cardH,
              child: _SummaryCard(
                label: 'Community AUM',
                value: _formatMoney(communityAum),
                icon: Icons.account_balance_wallet_outlined,
                tag: 'Total locked',
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: cardW,
              height: cardH,
              child: _SummaryCard(
                label: 'Avg Gain (All Time)',
                value: _formatPct(avgGain) + '%',
                valueColor: avgGain >= 0 ? AppColors.success : AppColors.error,
                icon: Icons.trending_up,
                tag: 'Performance',
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: cardW,
              height: cardH,
              child: _SummaryCard(
                label: 'Enrolled by you',
                value: '$enrolled',
                valueColor: enrolled > 0 ? AppColors.success : AppColors.textPrimary,
                icon: Icons.people_alt_outlined,
                tag: 'Subscribed',
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData icon;
  final String tag;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tag,
    required this.color,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 22.w,
                height: 22.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 13.sp, color: AppColors.whiteColor),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 9.sp,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── tab bar ───────────────────────────

class _FilterTabs extends StatelessWidget {
  final CopyTradingMastersController controller;
  const _FilterTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.selectedFilter.value;
      final all = controller.allMasters;
      final allCount = all.length;
      final enrolledCount = all.where((m) => m.isEnrolled).length;
      final discoverCount = all.where((m) => !m.isEnrolled).length;
      return SizedBox(
        height: 34.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            _tab(active, MasterFilterTab.all, 'All', allCount),
            SizedBox(width: 8.w),
            _tab(active, MasterFilterTab.enrolled, 'Enrolled', enrolledCount),
            SizedBox(width: 8.w),
            _tab(active, MasterFilterTab.discover, 'Discover', discoverCount),
          ],
        ),
      );
    });
  }

  Widget _tab(
    MasterFilterTab active,
    MasterFilterTab value,
    String label,
    int count,
  ) {
    final selected = active == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.selectedFilter.value = value;
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.whiteColor : AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.whiteColor.withValues(alpha: 0.30)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.whiteColor : AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── filter chips ───────────────────────────

class _FilterChips extends StatelessWidget {
  final CopyTradingMastersController controller;
  const _FilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        height: 32.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            _filterChip(
              label: controller.riskFilter.value,
              icon: Icons.shield_outlined,
              onTap: () => _showRiskSheet(context, controller),
            ),
            SizedBox(width: 8.w),
            _filterChip(
              label: controller.timeFilter.value,
              icon: Icons.schedule,
              onTap: () => _showTimeSheet(context, controller),
            ),
            SizedBox(width: 8.w),
            _filterChip(
              label: 'Sort: ${controller.sortBy.value}',
              icon: Icons.sort,
              onTap: () => _showSortSheet(context, controller),
            ),
            SizedBox(width: 8.w),
            _filterChip(
              label: 'Search',
              icon: Icons.search,
              onTap: () => _showSearchSheet(context, controller),
            ),
          ],
        ),
      );
    });
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.sp, color: AppColors.textGrey),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 2.w),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14.sp,
              color: AppColors.textGrey,
            ),
          ],
        ),
      ),
    );
  }

  void _showRiskSheet(BuildContext ctx, CopyTradingMastersController c) {
    _showChoiceSheet(
      ctx,
      title: 'Filter by Risk',
      options: const ['All Risks', 'Risk 1-2 (Low)', 'Risk 3 (Medium)', 'Risk 4-5 (High)'],
      onSelect: (v) => c.riskFilter.value = v,
    );
  }

  void _showTimeSheet(BuildContext ctx, CopyTradingMastersController c) {
    _showChoiceSheet(
      ctx,
      title: 'Timeframe',
      options: const ['All Time', 'Last 7D', 'Last 30D', 'Last 90D', 'Last 1Y'],
      onSelect: (v) => c.timeFilter.value = v,
    );
  }

  void _showSortSheet(BuildContext ctx, CopyTradingMastersController c) {
    _showChoiceSheet(
      ctx,
      title: 'Sort by',
      options: const ['Gain %', 'AUM', 'Copiers', 'Newest'],
      onSelect: (v) => c.sortBy.value = v,
    );
  }

  void _showSearchSheet(BuildContext ctx, CopyTradingMastersController c) {
    final tc = TextEditingController(text: c.searchQuery.value);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 16.h,
            bottom: 16.h + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search Masters',
                style: AppTextStyles.heading.copyWith(fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: tc,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Name, code or nickname',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    c.searchQuery.value = tc.text;
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChoiceSheet(
    BuildContext ctx, {
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading.copyWith(fontSize: 16.sp),
                ),
                SizedBox(height: 8.h),
                for (final o in options)
                  ListTile(
                    title: Text(o),
                    onTap: () {
                      onSelect(o);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── master card (horizontal / one per row) ───────────────────────────

class _MasterCardHorizontal extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  const _MasterCardHorizontal({
    required this.item,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final gain = (item.totalGainPercent as num).toDouble();
    final drawdown = (item.maxDrawdown as num).toDouble();
    final pnl = (item.totalPnl as num).toDouble();
    final minInvest = (item.minInvestment as num).toDouble();
    final activeDays = item.activeDays as int;
    final totalCopiers = item.totalCopiers as int;
    final riskScore = item.riskScore as int;
    final hasPlan = item.planCount > 0;
    final serverType = (item.serverType as String?) ?? 'mt5';
    final gainText = '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(2)}%';
    final drawdownText = '${drawdown.toStringAsFixed(0)}%';
    final pnlText = _formatPnl(pnl);
    final minInvestText = minInvest == 0
        ? '\$0'
        : '\$${minInvest.toStringAsFixed(0)}';
    final pnlColor = pnl >= 0 ? AppColors.success : AppColors.error;
    final gainColor = gain >= 0 ? AppColors.success : AppColors.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(item.masterNickname.toString()),
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.masterNickname.toString(),
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Text(
                              'Active ${activeDays}D',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textGrey,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textGrey,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              serverType == 'self_hosted'
                                  ? 'SELFHOSTED'
                                  : serverType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: serverType == 'self_hosted'
                                    ? AppColors.primary
                                    : AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _riskColor(riskScore).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'RISK $riskScore',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: _riskColor(riskScore),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Divider(height: 1, color: AppColors.border),
              SizedBox(height: 10.h),
              // 2x2 metrics
              _metricsRow([
                _metricCell('TOTAL GAIN', gainText, gainColor),
                _metricCell('MAX DRAWDOWN', '-$drawdownText', AppColors.error),
              ]),
              SizedBox(height: 6.h),
              _metricsRow([
                _metricCell('TOTAL P&L', pnlText, pnlColor),
                _metricCell(
                  'MIN INVESTMENT',
                  minInvestText,
                  AppColors.textPrimary,
                ),
              ]),
              SizedBox(height: 10.h),
              Divider(height: 1, color: AppColors.border),
              SizedBox(height: 8.h),
              // Footer
              Row(
                children: [
                  Text(
                    'Fee: ',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                  Text(
                    '${(item.commissionPercentage as num).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.people_outline,
                    size: 14.r,
                    color: AppColors.textGrey,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '$totalCopiers',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  SizedBox(
                    height: 32.h,
                    child: ElevatedButton(
                      onPressed: hasPlan ? onCopy : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.textGrey.withValues(
                          alpha: 0.20,
                        ),
                        foregroundColor: AppColors.whiteColor,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        hasPlan ? 'Copy' : 'No Plan',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricsRow(List<Widget> cells) {
    return Row(
      children: [
        Expanded(child: cells[0]),
        SizedBox(width: 10.w),
        Expanded(child: cells[1]),
      ],
    );
  }

  Widget _metricCell(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.sp,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

Color _riskColor(int risk) {
  if (risk <= 2) return AppColors.success;
  if (risk == 3) return const Color(0xFFF59E0B);
  return AppColors.error;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String _formatMoney(num n) {
  final abs = n.abs();
  if (abs >= 1000000) {
    return '\$${(n / 1000000).toStringAsFixed(2)}M';
  }
  if (abs >= 1000) {
    return '\$${(n / 1000).toStringAsFixed(2)}K';
  }
  return '\$${n.toStringAsFixed(0)}';
}

String _formatPct(num n) {
  return n.toStringAsFixed(n.abs() >= 100 ? 0 : 2);
}

String _formatPnl(num n) {
  final abs = n.abs();
  String body;
  if (abs >= 1000) {
    body = '${(n.abs() / 1000).toStringAsFixed(2)}K';
  } else {
    body = n.abs().toStringAsFixed(2);
  }
  return '${n < 0 ? '-' : (n > 0 ? '+' : '')}\$$body';
}

// ─────────────────────────── loading / empty / error states ───────────────────────────

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 24.h),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 200.h,
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }
}

class _NoSearchMatchesState extends StatelessWidget {
  final String query;
  const _NoSearchMatchesState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40.r, color: AppColors.textGrey),
            SizedBox(height: 10.h),
            Text(
              query.isEmpty
                  ? 'No masters in this view'
                  : 'No Masters Match "$query"',
              textAlign: TextAlign.center,
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.textGrey,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Try a different filter or clear the search.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            ),
          ],
        ),
      ),
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
            Icon(Icons.error_outline, size: 40.r, color: AppColors.error),
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
