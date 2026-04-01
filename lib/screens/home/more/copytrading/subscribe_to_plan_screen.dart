import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_hub_controller.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_details_controller.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_subscribe_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SubscribeToPlanScreen extends StatefulWidget {
  final String masterCode;
  final CopyTradingPlan plan;
  const SubscribeToPlanScreen({super.key, required this.masterCode, required this.plan});

  @override
  State<SubscribeToPlanScreen> createState() => _SubscribeToPlanScreenState();
}

class _SubscribeToPlanScreenState extends State<SubscribeToPlanScreen> {
  late final CopyTradingSubscribeController controller;
  final _investmentCtrl = TextEditingController();
  final _fixedLotCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();
  final _slCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      CopyTradingSubscribeController(masterCode: widget.masterCode, planId: widget.plan.planId),
      tag: '${widget.masterCode}:${widget.plan.planId}',
    );
  }

  @override
  void dispose() {
    _investmentCtrl.dispose();
    _fixedLotCtrl.dispose();
    _tpCtrl.dispose();
    _slCtrl.dispose();
    Get.delete<CopyTradingSubscribeController>(tag: '${widget.masterCode}:${widget.plan.planId}', force: true);
    super.dispose();
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
        title: Text(
          'Subscribe',
          style: AppTextStyles.heading.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios, size: 18.r, color: AppColors.textPrimary),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.eligibleAccounts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty && controller.eligibleAccounts.isEmpty) {
          return _ErrorState(
            message: controller.errorMessage.value,
            onRetry: () => controller.loadEligibleAccounts(showLoading: true),
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 22.h),
          children: [
            _PlanSummary(plan: widget.plan),
            SizedBox(height: 12.h),
            _AccountsCard(controller: controller),
            SizedBox(height: 12.h),
            _CopySettingsCard(
              controller: controller,
              fixedLotCtrl: _fixedLotCtrl,
            ),
            SizedBox(height: 12.h),
            _AdvancedSettingsCard(
              controller: controller,
              tpCtrl: _tpCtrl,
              slCtrl: _slCtrl,
            ),
            SizedBox(height: 12.h),
            _InvestmentCard(
              investmentCtrl: _investmentCtrl,
              minCapital: widget.plan.minimumCapital,
              onQuickFill: (value) => _investmentCtrl.text = value,
            ),
            SizedBox(height: 14.h),
            if (controller.errorMessage.value.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12.sp),
                ),
              ),
            _SubscribeButton(
              isLoading: controller.isLoading,
              onPressed: () async {
                final acc = controller.selectedAccount.value;
                if (acc == null) {
                  controller.errorMessage.value = 'Select an account';
                  return;
                }

                final investment =
                    num.tryParse(_investmentCtrl.text.trim()) ?? acc.equity; // default to equity if empty
                if (investment <= 0) {
                  controller.errorMessage.value = 'Enter a valid investment amount';
                  return;
                }
                if (widget.plan.minimumCapital > 0 && investment < widget.plan.minimumCapital) {
                  controller.errorMessage.value = 'Minimum capital is ${widget.plan.minimumCapital}';
                  return;
                }

                // Validate copying method fields
                if (controller.copyingMethod.value == 'fixed') {
                  final fixedLot = double.tryParse(_fixedLotCtrl.text.trim());
                  if (fixedLot == null || fixedLot <= 0) {
                    controller.errorMessage.value = 'Enter a valid fixed lot size';
                    return;
                  }
                  controller.fixedLotSize.value = fixedLot;
                }

                // Validate TP/SL override fields
                if (controller.overridesSlTp.value) {
                  final tp = double.tryParse(_tpCtrl.text.trim());
                  final sl = double.tryParse(_slCtrl.text.trim());
                  if (tp == null || tp <= 0 || sl == null || sl <= 0) {
                    controller.errorMessage.value = 'Enter valid Take Profit and Stop Loss values';
                    return;
                  }
                  if (controller.slTpMode.value == 'pip') {
                    controller.takeProfitPips.value = tp;
                    controller.stopLossPips.value = sl;
                  } else {
                    controller.takeProfitDollar.value = tp;
                    controller.stopLossDollar.value = sl;
                  }
                }

                final res = await controller.subscribe(investmentAmount: investment);
                if (res.success) {
                  // refresh hub menu pills (My Copies / status)
                  if (Get.isRegistered<CopyTradingHubController>()) {
                    await Get.find<CopyTradingHubController>().refreshAll(showLoading: false);
                  }
                  if (mounted) {
                    Get.back();
                    Get.snackbar(
                      'Subscribed',
                      res.message ?? 'Successfully subscribed',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                } else {
                  Get.snackbar(
                    'Failed',
                    res.message ?? controller.errorMessage.value,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
          ],
        );
      }),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  final CopyTradingPlan plan;
  const _PlanSummary({required this.plan});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.planName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          SizedBox(height: 8.h),
          _Row(label: 'Commission', value: plan.commissionLabel.isNotEmpty ? plan.commissionLabel : plan.commissionType),
          _Row(label: 'Min capital', value: plan.minimumCapital.toString()),
          _Row(label: 'Period (days)', value: plan.subscriptionPeriodDays.toString()),
          _Row(label: 'No-fee days', value: plan.noFeeDays.toString()),
        ],
      ),
    );
  }
}

class _AccountsCard extends StatelessWidget {
  final CopyTradingSubscribeController controller;
  const _AccountsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select account', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          SizedBox(height: 10.h),
          ...controller.eligibleAccounts.map((a) {
            final selected = controller.selectedAccount.value?.id == a.id;
            return InkWell(
              onTap: () => controller.selectedAccount.value = a,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.tradeBackgroundCenterColor.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: selected ? AppColors.primary.withOpacity(0.25) : Colors.grey.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.primary : AppColors.textGrey),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.metaAccountNumber,
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${a.accountType} • Equity ${a.equity}',
                            style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    if (a.isEnrolled)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
                        ),
                        child: Text('Already enrolled', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B))),
                      ),
                  ],
                ),
              ),
            );
          }),
          if (controller.eligibleAccounts.isEmpty)
            Text('No eligible accounts found.', style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

class _CopySettingsCard extends StatelessWidget {
  final CopyTradingSubscribeController controller;
  final TextEditingController fixedLotCtrl;
  const _CopySettingsCard({required this.controller, required this.fixedLotCtrl});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Copy settings', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          SizedBox(height: 10.h),
          Text('Copying method', style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey)),
          SizedBox(height: 6.h),
          Obx(() {
            final method = controller.copyingMethod.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectTile(
                  value: method,
                  items: const [
                    _SelectItem(value: 'proportional', label: 'In proportion to master (100% of master lot)'),
                    _SelectItem(value: 'fixed', label: 'Fixed lot size'),
                  ],
                  onChanged: (v) {
                    controller.copyingMethod.value = v;
                  },
                ),
                if (method == 'fixed') ...[
                  SizedBox(height: 12.h),
                  Text('Fixed Lot Size', style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey)),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: fixedLotCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'e.g. 0.10'),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _AdvancedSettingsCard extends StatelessWidget {
  final CopyTradingSubscribeController controller;
  final TextEditingController tpCtrl;
  final TextEditingController slCtrl;
  const _AdvancedSettingsCard({required this.controller, required this.tpCtrl, required this.slCtrl});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.only(top: 10.h),
          title: Text('Advanced Settings', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.tradeBackgroundCenterColor.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.grey.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('PER-TRADE TP / SL', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      const Spacer(),
                      Obx(() {
                        return Row(
                          children: [
                            Checkbox(
                              value: controller.overridesSlTp.value,
                              onChanged: (v) => controller.overridesSlTp.value = v ?? false,
                            ),
                            Text('Override master', style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w800)),
                          ],
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Set your own TP / SL in pips or a fixed dollar amount.',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.textGrey, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10.h),
                  Obx(() {
                    final enabled = controller.overridesSlTp.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ModeChip(
                              label: 'Pip',
                              selected: controller.slTpMode.value == 'pip',
                              onTap: enabled ? () => controller.slTpMode.value = 'pip' : null,
                            ),
                            SizedBox(width: 8.w),
                            _ModeChip(
                              label: r'$ Dollar',
                              selected: controller.slTpMode.value == 'dollar',
                              onTap: enabled ? () => controller.slTpMode.value = 'dollar' : null,
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Take Profit (${controller.slTpMode.value})', style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey)),
                                  SizedBox(height: 6.h),
                                  TextField(
                                    enabled: enabled,
                                    controller: tpCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(hintText: enabled ? 'e.g. 5' : 'Disabled'),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Stop Loss (${controller.slTpMode.value})', style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey)),
                                  SizedBox(height: 6.h),
                                  TextField(
                                    enabled: enabled,
                                    controller: slCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(hintText: enabled ? 'e.g. 5' : 'Disabled'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.withOpacity(0.18)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.whiteColor : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SelectItem {
  final String value;
  final String label;
  const _SelectItem({required this.value, required this.label});
}

class _SelectTile extends StatelessWidget {
  final String value;
  final List<_SelectItem> items;
  final ValueChanged<String> onChanged;
  const _SelectTile({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.value,
                  child: Text(
                    e.label,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
class _InvestmentCard extends StatelessWidget {
  final TextEditingController investmentCtrl;
  final num minCapital;
  final ValueChanged<String> onQuickFill;
  const _InvestmentCard({required this.investmentCtrl, required this.minCapital, required this.onQuickFill});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Investment amount', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          SizedBox(height: 10.h),
          TextField(
            controller: investmentCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: minCapital > 0 ? 'Min $minCapital' : 'Enter amount',
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _Chip(label: 'Min', onTap: () => onQuickFill(minCapital.toString())),
              _Chip(label: '100', onTap: () => onQuickFill('100')),
              _Chip(label: '500', onTap: () => onQuickFill('500')),
              _Chip(label: '1000', onTap: () => onQuickFill('1000')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  final RxBool isLoading;
  final VoidCallback onPressed;
  const _SubscribeButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = isLoading.value;
      return SizedBox(
        width: double.infinity,
        height: 46.h,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: loading
              ? SizedBox(width: 18.r, height: 18.r, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Subscribe'),
        ),
      );
    });
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey)),
          Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        ],
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
            Icon(Icons.error_outline, size: 40.r, color: AppColors.red),
            SizedBox(height: 10.h),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey)),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

