import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_copier_subscriptions_controller.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class MyCopiesScreen extends StatefulWidget {
  const MyCopiesScreen({super.key});

  @override
  State<MyCopiesScreen> createState() => _MyCopiesScreenState();
}

class _MyCopiesScreenState extends State<MyCopiesScreen> {
  late final CopyTradingCopierSubscriptionsController controller;
  final _searchCtrl = TextEditingController();
  final _statusFilter = 'all'.obs; // all | active | paused | stopped

  @override
  void initState() {
    super.initState();
    controller = Get.put(CopyTradingCopierSubscriptionsController(), tag: 'copytrading:my_copies');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    Get.delete<CopyTradingCopierSubscriptionsController>(tag: 'copytrading:my_copies', force: true);
    super.dispose();
  }

  List<CopierSubscriptionItem> _filtered(List<CopierSubscriptionItem> all) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final status = _statusFilter.value;
    return all.where((s) {
      final statusOk = status == 'all' ? true : s.status.toLowerCase() == status;
      if (!statusOk) return false;
      if (q.isEmpty) return true;
      return s.masterName.toLowerCase().contains(q) ||
          s.masterCode.toLowerCase().contains(q) ||
          s.planName.toLowerCase().contains(q) ||
          s.accountNumber.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        centerTitle: true,
        title: Text('My Copies', style: AppTextStyles.screenTitle),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios, size: 18.r, color: AppColors.textPrimary),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.load(showLoading: false),
        child: Obx(() {
          final loading = controller.isLoading.value;
          final err = controller.errorMessage.value;
          final list = controller.subscriptions.toList();
          final filtered = _filtered(list);

          if (loading && list.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            children: [
              if (err.isNotEmpty)
                _InlineError(
                  message: err,
                  onRetry: () {
                    CustomToastService.showError(message: err, title: 'Error');
                    controller.load(showLoading: true);
                  },
                ),
              if (err.isNotEmpty) SizedBox(height: 12.h),

              _SearchBox(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 12.h),

              Obx(() {
                return _FilterRow(
                  selected: _statusFilter.value,
                  onChanged: (v) => _statusFilter.value = v,
                );
              }),
              SizedBox(height: 12.h),

              _SummaryCard(items: filtered),
              SizedBox(height: 12.h),

              if (filtered.isEmpty)
                _EmptyState(
                  title: 'No copies found',
                  subtitle: list.isEmpty
                      ? 'Explore masters and subscribe to start copy trading.'
                      : 'Try changing search or filter.',
                )
              else
                ...filtered.map((s) => _SubscriptionCard(item: s)),

              if (loading) ...[
                SizedBox(height: 12.h),
                Center(
                  child: SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search master / plan / account',
          hintStyle: AppTextStyles.hint,
          icon: Icon(Icons.search, color: AppColors.textGrey),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: Icon(Icons.close, size: 18.r, color: AppColors.textGrey),
                ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        _FilterChip(label: 'All', value: 'all', selected: selected, onChanged: onChanged),
        _FilterChip(label: 'Active', value: 'active', selected: selected, onChanged: onChanged),
        _FilterChip(label: 'Paused', value: 'paused', selected: selected, onChanged: onChanged),
        _FilterChip(label: 'Stopped', value: 'stopped', selected: selected, onChanged: onChanged),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isOn = selected == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isOn ? AppColors.primary : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isOn ? AppColors.primary : Colors.grey.withOpacity(0.18)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isOn ? AppColors.whiteColor : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<CopierSubscriptionItem> items;
  const _SummaryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final active = items.where((e) => e.isActive).length;
    final capital = items.fold<num>(0, (p, e) => p + e.capitalAmount);
    final pnl = items.fold<num>(0, (p, e) => p + e.totalPnl);
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(child: _Metric(label: 'Active', value: '$active')),
          Expanded(child: _Metric(label: 'Capital', value: '\$${capital.toStringAsFixed(2)}')),
          Expanded(
            child: _Metric(
              label: 'P&L',
              value: '\$${pnl.toStringAsFixed(2)}',
              valueColor: pnl >= 0 ? AppColors.green : AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Metric({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        SizedBox(height: 4.h),
        Text(value, style: AppTextStyles.black16600.copyWith(color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final CopierSubscriptionItem item;
  const _SubscriptionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item.status.toLowerCase();
    final Color pillColor = switch (status) {
      'active' => AppColors.success,
      'paused' => AppColors.warning,
      'stopped' => AppColors.error,
      _ => AppColors.textGrey,
    };

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.masterName.isNotEmpty ? item.masterName : item.masterCode, style: AppTextStyles.black16600),
                    SizedBox(height: 2.h),
                    Text(item.planName, style: AppTextStyles.caption),
                  ],
                ),
              ),
              _StatusPill(text: status.isEmpty ? 'unknown' : status, color: pillColor),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(child: _Line(label: 'Account', value: item.accountNumber)),
              Expanded(child: _Line(label: 'Open trades', value: item.openTrades.toString())),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: _Line(label: 'Capital', value: '\$${item.capitalAmount.toStringAsFixed(2)}')),
              Expanded(
                child: _Line(
                  label: 'P&L',
                  value: '\$${item.totalPnl.toStringAsFixed(2)}',
                  valueColor: item.totalPnl >= 0 ? AppColors.green : AppColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Line({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        SizedBox(height: 4.h),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.black14600.copyWith(color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.black16600),
          SizedBox(height: 6.h),
          Text(subtitle, style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 18.r),
          SizedBox(width: 8.w),
          Expanded(child: Text(message, style: AppTextStyles.caption.copyWith(color: AppColors.error))),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text('Retry', style: AppTextStyles.textButton),
          ),
        ],
      ),
    );
  }
}

