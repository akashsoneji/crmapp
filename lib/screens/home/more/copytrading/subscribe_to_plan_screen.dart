import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_hub_controller.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_details_controller.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_subscribe_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/widgets/labeled_app_text_field.dart';
import 'package:crm_app/widgets/custom_toast.dart';

class SubscribeToPlanScreen extends StatefulWidget {
  final String masterCode;
  final CopyTradingPlan plan;
  const SubscribeToPlanScreen({super.key, required this.masterCode, required this.plan});

  @override
  State<SubscribeToPlanScreen> createState() => _SubscribeToPlanScreenState();
}

class _SubscribeToPlanScreenState extends State<SubscribeToPlanScreen> {
  late final CopyTradingMasterDetailsController masterController;
  CopyTradingSubscribeController? controller;
  final _selectedPlan = Rxn<CopyTradingPlan>();
  final _step = 0.obs; // 0: plan+account, 1: settings+subscribe
  final _customMultiplier = false.obs;
  final _multiplierCtrl = TextEditingController();
  final _investmentCtrl = TextEditingController();
  final _fixedLotCtrl = TextEditingController();
  final _multiplierOnlyCtrl = TextEditingController();
  final _mirrorRatioCtrl = TextEditingController();
  final _riskPercentCtrl = TextEditingController();
  final _riskSlPipsCtrl = TextEditingController();
  final _dynamicDdCtrl = TextEditingController();
  final _dynamicReduceCtrl = TextEditingController();
  final _fixedRatioProfitStepCtrl = TextEditingController();
  final _fixedRatioLotStepCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();
  final _slCtrl = TextEditingController();

  void _showTopError(String message) {
    final msg = message.trim();
    if (msg.isEmpty) return;
    // Use app's existing notification/toast UI (matches other screens)
    CustomToastService.showError(
      title: 'Error',
      message: msg,
      duration: const Duration(milliseconds: 2500),
      position: SnackPosition.TOP,
    );
  }

  @override
  void initState() {
    super.initState();

    masterController = Get.put(
      CopyTradingMasterDetailsController(masterCode: widget.masterCode),
      tag: 'master:${widget.masterCode}',
    );

    // initial plan (will be replaced by API plans if available)
    _selectedPlan.value = widget.plan;
    _ensureSubscribeController(widget.plan.planId);
  }

  @override
  void dispose() {
    _multiplierCtrl.dispose();
    _investmentCtrl.dispose();
    _fixedLotCtrl.dispose();
    _multiplierOnlyCtrl.dispose();
    _mirrorRatioCtrl.dispose();
    _riskPercentCtrl.dispose();
    _riskSlPipsCtrl.dispose();
    _dynamicDdCtrl.dispose();
    _dynamicReduceCtrl.dispose();
    _fixedRatioProfitStepCtrl.dispose();
    _fixedRatioLotStepCtrl.dispose();
    _tpCtrl.dispose();
    _slCtrl.dispose();
    final current = controller;
    if (current != null) {
      Get.delete<CopyTradingSubscribeController>(tag: '${widget.masterCode}:${current.planId}', force: true);
    }
    Get.delete<CopyTradingMasterDetailsController>(tag: 'master:${widget.masterCode}', force: true);
    super.dispose();
  }

  void _ensureSubscribeController(int planId) {
    final existing = controller;
    if (existing != null && existing.planId == planId) return;

    if (existing != null) {
      Get.delete<CopyTradingSubscribeController>(tag: '${widget.masterCode}:${existing.planId}', force: true);
    }
    controller = Get.put(
      CopyTradingSubscribeController(masterCode: widget.masterCode, planId: planId, autoSelectFirstAccount: false),
      tag: '${widget.masterCode}:$planId',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        centerTitle: false,
        title: Obx(() {
          final p = masterController.profile.value;
          final name = (p?.nickname.isNotEmpty ?? false) ? p!.nickname : widget.masterCode;
          return Text(
            'Start Copy to $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.screenTitle,
          );
        }),
        leading: Obx(() {
          final s = _step.value;
          return IconButton(
            onPressed: () {
              if (s == 0) {
                Get.back();
              } else {
                _step.value = 0;
              }
            },
            icon: Icon(Icons.arrow_back_ios, size: 18.r, color: AppColors.textPrimary),
          );
        }),
        actions: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.close, size: 20.r, color: AppColors.textPrimary),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Obx(() {
        final selectedPlan = _selectedPlan.value;
        final sub = controller;

        if (masterController.isLoading.value && masterController.profile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (masterController.errorMessage.value.isNotEmpty && masterController.profile.value == null) {
          return _ErrorState(
            message: masterController.errorMessage.value,
            onRetry: () => masterController.loadProfile(showLoading: true),
          );
        }

        final profile = masterController.profile.value;
        final plans = profile?.plans ?? const <CopyTradingPlan>[];
        final effectivePlan = selectedPlan;

        return Column(
          children: [
            Expanded(
              child: Obx(() {
                final s = _step.value;
                return ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 22.h),
                  children: [
                    if (s == 0) ...[
                      _PlanPickerCard(
                        plans: plans.isNotEmpty ? plans : [widget.plan],
                        selectedPlan: effectivePlan,
                        onPlanChanged: (p) {
                          _selectedPlan.value = p;
                          _step.value = 0;
                          _investmentCtrl.text = '';
                          _fixedLotCtrl.text = '';
                          _tpCtrl.text = '';
                          _slCtrl.text = '';
                          _multiplierCtrl.text = '';
                          _customMultiplier.value = false;
                          _ensureSubscribeController(p.planId);
                        },
                      ),
                      if (effectivePlan != null) ...[
                        SizedBox(height: 12.h),
                        _PlanInfoCard(plan: effectivePlan),
                        SizedBox(height: 12.h),
                        _AccountPickerCard(
                          controller: controller,
                          minCapital: effectivePlan.minimumCapital,
                        ),
                      ] else ...[
                        SizedBox(height: 12.h),
                        _Card(
                          child: Text(
                            'Select a plan to view eligible accounts.',
                            style: AppTextStyles.cardSubtitle,
                          ),
                        ),
                      ],
                      SizedBox(height: 90.h),
                    ] else ...[
                      if (effectivePlan != null && sub != null) ...[
                        _InvestmentCard(
                          investmentCtrl: _investmentCtrl,
                          minCapital: effectivePlan.minimumCapital,
                          onQuickFill: (value) => _investmentCtrl.text = value,
                        ),
                        SizedBox(height: 12.h),
                        _CopySettingsCard(
                          controller: sub,
                          fixedLotCtrl: _fixedLotCtrl,
                          multiplierOnlyCtrl: _multiplierOnlyCtrl,
                          mirrorRatioCtrl: _mirrorRatioCtrl,
                          riskPercentCtrl: _riskPercentCtrl,
                          riskSlPipsCtrl: _riskSlPipsCtrl,
                          dynamicDdCtrl: _dynamicDdCtrl,
                          dynamicReduceCtrl: _dynamicReduceCtrl,
                          fixedRatioProfitStepCtrl: _fixedRatioProfitStepCtrl,
                          fixedRatioLotStepCtrl: _fixedRatioLotStepCtrl,
                        ),
                        SizedBox(height: 12.h),
                        _AdvancedSettingsCard(
                          controller: sub,
                          tpCtrl: _tpCtrl,
                          slCtrl: _slCtrl,
                          customMultiplier: _customMultiplier,
                          multiplierCtrl: _multiplierCtrl,
                          onMultiplierPreset: (v) {
                            sub.lotMultiplier.value = v;
                            _multiplierCtrl.text = '';
                            _customMultiplier.value = false;
                          },
                          onMultiplierCustom: () {
                            _customMultiplier.value = true;
                            if (sub.lotMultiplier.value > 0) {
                              _multiplierCtrl.text = sub.lotMultiplier.value.toString();
                            }
                          },
                          onTpPreset: (v) => _tpCtrl.text = v.toString(),
                          onSlPreset: (v) => _slCtrl.text = v.toString(),
                        ),
                        SizedBox(height: 12.h),
                        if (sub.errorMessage.value.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Text(sub.errorMessage.value, style: AppTextStyles.error),
                          ),
                        SizedBox(height: 90.h),
                      ] else ...[
                        _Card(child: Text('Please go back and select a plan/account.', style: AppTextStyles.cardSubtitle)),
                        SizedBox(height: 90.h),
                      ],
                    ],
                  ],
                );
              }),
            ),
            _BottomBar(
              isLoading: (controller?.isLoading ?? false.obs),
              step: _step,
              onNext: () {
                final plan = _selectedPlan.value;
                final sub = controller;
                if (plan == null) {
                  if (sub != null) sub.errorMessage.value = 'Select a plan';
                  _showTopError('Select a plan');
                  return;
                }
                final acc = sub?.selectedAccount.value;
                if (sub == null || acc == null) {
                  if (sub != null) sub.errorMessage.value = 'Select an account';
                  _showTopError('Select an account');
                  return;
                }
                if (plan.minimumCapital > 0 && acc.equity < plan.minimumCapital) {
                  sub.errorMessage.value = 'Account equity is below minimum required (${plan.minimumCapital}).';
                  _showTopError(sub.errorMessage.value);
                  return;
                }
                sub.errorMessage.value = '';
                _step.value = 1;
              },
              onSubscribe: () async {
                final plan = _selectedPlan.value;
                final sub = controller;
                if (plan == null || sub == null) return;
                final acc = sub.selectedAccount.value;
                if (acc == null) {
                  sub.errorMessage.value = 'Select an account';
                  _showTopError(sub.errorMessage.value);
                  _step.value = 0;
                  return;
                }
                if (plan.minimumCapital > 0 && acc.equity < plan.minimumCapital) {
                  sub.errorMessage.value = 'Account equity is below minimum required (${plan.minimumCapital}).';
                  _showTopError(sub.errorMessage.value);
                  _step.value = 0;
                  return;
                }

                final investment = num.tryParse(_investmentCtrl.text.trim()) ?? 0;
                if (investment <= 0) {
                  sub.errorMessage.value = 'Enter a valid investment amount';
                  _showTopError(sub.errorMessage.value);
                  return;
                }
                if (plan.minimumCapital > 0 && investment < plan.minimumCapital) {
                  sub.errorMessage.value = 'Minimum investment is ${plan.minimumCapital}';
                  _showTopError(sub.errorMessage.value);
                  return;
                }
                if (acc.equity > 0 && investment > acc.equity) {
                  sub.errorMessage.value = 'Investment cannot exceed account equity (${acc.equity})';
                  _showTopError(sub.errorMessage.value);
                  return;
                }

                // Validate/assign method-specific fields
                switch (sub.sizingMethod.value) {
                  case 'fixed':
                    final fixedLot = double.tryParse(_fixedLotCtrl.text.trim());
                    if (fixedLot == null || fixedLot <= 0) {
                      sub.errorMessage.value = 'Enter a valid fixed lot size';
                      _showTopError(sub.errorMessage.value);
                      return;
                    }
                    sub.fixedLotSize.value = fixedLot;
                    break;
                  case 'multiplier_only':
                    // backend uses lot_multiplier for this method too; no extra required fields
                    break;
                  case 'mirror_ratio':
                    final r = double.tryParse(_mirrorRatioCtrl.text.trim());
                    if (r == null || r <= 0) {
                      sub.errorMessage.value = 'Enter a valid ratio';
                      _showTopError(sub.errorMessage.value);
                      return;
                    }
                    sub.mirrorRatio.value = r;
                    break;
                  case 'percentage_risk':
                    final rp = double.tryParse(_riskPercentCtrl.text.trim());
                    if (rp == null || rp <= 0) {
                      sub.errorMessage.value = 'Enter a valid risk %';
                      _showTopError(sub.errorMessage.value);
                      return;
                    }
                    sub.percentageRisk.value = rp;
                    break;
                  case 'dynamic_lot':
                    // backend allows null dynamic_lot_rules; keep optional fields
                    final dd = double.tryParse(_dynamicDdCtrl.text.trim());
                    final rr = double.tryParse(_dynamicReduceCtrl.text.trim());
                    if (dd != null && dd > 0) sub.dynamicDrawdownThreshold.value = dd;
                    if (rr != null && rr > 0) sub.dynamicReductionRatio.value = rr;
                    break;
                  case 'fixed_ratio':
                    // backend allows null fixed_ratio_rules; keep optional fields
                    final ps = double.tryParse(_fixedRatioProfitStepCtrl.text.trim());
                    final ls = double.tryParse(_fixedRatioLotStepCtrl.text.trim());
                    if (ps != null && ps > 0) sub.fixedRatioProfitStep.value = ps;
                    if (ls != null && ls > 0) sub.fixedRatioLotStep.value = ls;
                    break;
                  default:
                    // proportional_* has no required extra fields on UI
                    break;
                }

                // Assign optional proportional multiplier when using proportional-style sizing
                if (sub.copyingMethod.value == 'proportional') {
                  if (_customMultiplier.value) {
                    final m = double.tryParse(_multiplierCtrl.text.trim());
                    if (m == null || m <= 0) {
                      sub.errorMessage.value = 'Enter a valid lot multiplier';
                      _showTopError(sub.errorMessage.value);
                      return;
                    }
                    sub.lotMultiplier.value = m;
                  }
                }

                if (sub.overridesSlTp.value) {
                  final tp = double.tryParse(_tpCtrl.text.trim());
                  final sl = double.tryParse(_slCtrl.text.trim());
                  if (tp == null || tp <= 0 || sl == null || sl <= 0) {
                    sub.errorMessage.value = 'Enter valid Take Profit and Stop Loss values';
                    _showTopError(sub.errorMessage.value);
                    return;
                  }
                  if (sub.slTpMode.value == 'pip') {
                    sub.takeProfitPips.value = tp;
                    sub.stopLossPips.value = sl;
                  } else {
                    sub.takeProfitDollar.value = tp;
                    sub.stopLossDollar.value = sl;
                  }
                }

                final res = await sub.subscribe(investmentAmount: investment);
                if (res.success) {
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
                  // Show API business errors inline on-screen (per COPYTRADING_API.md)
                  sub.errorMessage.value = res.message ?? sub.errorMessage.value;
                  _showTopError(sub.errorMessage.value);
                }
              },
            ),
          ],
        );
      }),
    );
  }
}

class _PlanPickerCard extends StatelessWidget {
  final List<CopyTradingPlan> plans;
  final CopyTradingPlan? selectedPlan;
  final ValueChanged<CopyTradingPlan> onPlanChanged;
  const _PlanPickerCard({required this.plans, required this.selectedPlan, required this.onPlanChanged});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a Plan *', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 10.h),
          _PlanDropdown(plans: plans, selected: selectedPlan, onChanged: onPlanChanged),
        ],
      ),
    );
  }
}

class _AccountPickerCard extends StatelessWidget {
  final CopyTradingSubscribeController? controller;
  final num minCapital;
  const _AccountPickerCard({required this.controller, required this.minCapital});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Your Trading Account *', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 10.h),
          if (controller == null)
            Text('Select a plan first.', style: AppTextStyles.cardSubtitle)
          else
            Obx(() {
              final c = controller!;
              if (c.isLoading.value && c.eligibleAccounts.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
            }
            if (c.errorMessage.value.isNotEmpty && c.eligibleAccounts.isEmpty) {
              return _InlineError(
                message: c.errorMessage.value,
                onRetry: () => c.loadEligibleAccounts(showLoading: true),
              );
            }
            return _AccountDropdown(
              accounts: c.eligibleAccounts,
              selected: c.selectedAccount.value,
              minCapital: minCapital,
              onChanged: (a) => c.selectedAccount.value = a,
            );
          }),
          if (controller != null && controller!.eligibleAccounts.isEmpty && controller!.errorMessage.value.isEmpty)
            Text('No eligible accounts found.', style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}

class _CopySettingsCard extends StatelessWidget {
  final CopyTradingSubscribeController controller;
  final TextEditingController fixedLotCtrl;
  final TextEditingController multiplierOnlyCtrl;
  final TextEditingController mirrorRatioCtrl;
  final TextEditingController riskPercentCtrl;
  final TextEditingController riskSlPipsCtrl;
  final TextEditingController dynamicDdCtrl;
  final TextEditingController dynamicReduceCtrl;
  final TextEditingController fixedRatioProfitStepCtrl;
  final TextEditingController fixedRatioLotStepCtrl;

  const _CopySettingsCard({
    required this.controller,
    required this.fixedLotCtrl,
    required this.multiplierOnlyCtrl,
    required this.mirrorRatioCtrl,
    required this.riskPercentCtrl,
    required this.riskSlPipsCtrl,
    required this.dynamicDdCtrl,
    required this.dynamicReduceCtrl,
    required this.fixedRatioProfitStepCtrl,
    required this.fixedRatioLotStepCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Copy settings', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          SizedBox(height: 10.h),
          Obx(() {
            final method = controller.sizingMethod.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectTile(
                  value: method,
                  items: const [
                    _SelectItem(value: 'fixed', label: 'Fixed Lot — e.g. always trade 0.10 lot'),
                    _SelectItem(value: 'proportional_equity', label: 'Equity-Based — scales by your equity vs master\'s'),
                    _SelectItem(value: 'proportional_balance', label: 'Balance-Based — scales by your balance vs master\'s'),
                    _SelectItem(value: 'multiplier_only', label: 'Multiplier — master lots × your multiplier'),
                    _SelectItem(value: 'mirror_ratio', label: 'Mirror Ratio — master lots × fixed ratio'),
                    _SelectItem(value: 'percentage_risk', label: 'Percentage Risk — risk % of balance per trade'),
                    _SelectItem(value: 'reverse', label: 'Reverse — master buys, you sell (vice versa)'),
                    _SelectItem(value: 'dynamic_lot', label: 'Dynamic Lot — reduces lots on drawdown'),
                    _SelectItem(value: 'fixed_ratio', label: 'Fixed Ratio — adds lots per profit milestone'),
                  ],
                  onChanged: (v) {
                    controller.sizingMethod.value = v;
                    controller.copyingMethod.value = v == 'fixed' ? 'fixed' : 'proportional';
                    // Pre-fill defaults into the visible inputs for good UX
                    if (v == 'fixed' && fixedLotCtrl.text.trim().isEmpty) {
                      fixedLotCtrl.text = controller.fixedLotSize.value.toString();
                    }
                    if (v == 'multiplier_only' && multiplierOnlyCtrl.text.trim().isEmpty) {
                      multiplierOnlyCtrl.text = controller.multiplierOnly.value.toString();
                    }
                    if (v == 'mirror_ratio' && mirrorRatioCtrl.text.trim().isEmpty) {
                      mirrorRatioCtrl.text = controller.mirrorRatio.value.toString();
                    }
                    if (v == 'percentage_risk') {
                      if (riskPercentCtrl.text.trim().isEmpty) riskPercentCtrl.text = controller.percentageRisk.value.toString();
                      if (riskSlPipsCtrl.text.trim().isEmpty) riskSlPipsCtrl.text = controller.percentageRiskSlPips.value.toString();
                    }
                    if (v == 'dynamic_lot') {
                      if (dynamicDdCtrl.text.trim().isEmpty) dynamicDdCtrl.text = controller.dynamicDrawdownThreshold.value.toString();
                      if (dynamicReduceCtrl.text.trim().isEmpty) dynamicReduceCtrl.text = controller.dynamicReductionRatio.value.toString();
                    }
                    if (v == 'fixed_ratio') {
                      if (fixedRatioProfitStepCtrl.text.trim().isEmpty) fixedRatioProfitStepCtrl.text = controller.fixedRatioProfitStep.value.toString();
                      if (fixedRatioLotStepCtrl.text.trim().isEmpty) fixedRatioLotStepCtrl.text = controller.fixedRatioLotStep.value.toString();
                    }
                  },
                ),
                SizedBox(height: 8.h),
                _MethodHelpText(method: method),
                if (method == 'fixed') ...[
                  SizedBox(height: 12.h),
                  LabeledAppTextField(
                    label: 'Fixed Lot Size *',
                    controller: fixedLotCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: 'e.g. 0.10',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      const SingleDecimalTextFormatter(),
                    ],
                  ),
                ],
                // if (method == 'multiplier_only') ...[
                //   SizedBox(height: 12.h),
                //   LabeledAppTextField(
                //     label: 'Multiplier *',
                //     controller: multiplierOnlyCtrl,
                //     keyboardType: const TextInputType.numberWithOptions(decimal: true),
                //     hintText: 'e.g. 2',
                //     inputFormatters: [
                //       FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                //       const SingleDecimalTextFormatter(),
                //     ],
                //   ),
                // ],
                if (method == 'mirror_ratio') ...[
                  SizedBox(height: 12.h),
                  LabeledAppTextField(
                    label: 'Ratio *',
                    controller: mirrorRatioCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: 'e.g. 0.5',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      const SingleDecimalTextFormatter(),
                    ],
                  ),
                ],
                if (method == 'percentage_risk') ...[
                  SizedBox(height: 12.h),
                  LabeledAppTextField(
                    label: 'Risk % per trade *',
                    controller: riskPercentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: 'e.g. 2',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      const SingleDecimalTextFormatter(),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
                if (method == 'reverse') ...[
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      SizedBox(
                        width: 34.w,
                        height: 34.h,
                        child: Obx(() {
                          return Checkbox(
                            value: controller.isReverse.value,
                            onChanged: (v) => controller.isReverse.value = v ?? true,
                          );
                        }),
                      ),
                      Expanded(
                        child: Text(
                          'Invert BUY/SELL for copied trades',
                          style: AppTextStyles.black14500,
                        ),
                      ),
                    ],
                  ),
                  
                ],
                if (method == 'dynamic_lot') ...[
                  SizedBox(height: 12.h),
                  LabeledAppTextField(
                    label: 'Drawdown threshold (%) *',
                    controller: dynamicDdCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: 'e.g. 20',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      const SingleDecimalTextFormatter(),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  LabeledAppTextField(
                    label: 'Reduction ratio (0–1) *',
                    controller: dynamicReduceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: 'e.g. 0.5',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      const SingleDecimalTextFormatter(),
                    ],
                  ),
                ],
                if (method == 'fixed_ratio') ...[
                  SizedBox(height: 12.h),
                  LabeledAppTextField(
                    label: 'Profit milestone (USD) *',
                    controller: fixedRatioProfitStepCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: 'e.g. 1000',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      const SingleDecimalTextFormatter(),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  LabeledAppTextField(
                    label: 'Lot increase per milestone *',
                    controller: fixedRatioLotStepCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: 'e.g. 0.01',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      const SingleDecimalTextFormatter(),
                    ],
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

class _MethodHelpText extends StatelessWidget {
  final String method;
  const _MethodHelpText({required this.method});

  @override
  Widget build(BuildContext context) {
    String text;
    switch (method) {
      case 'fixed':
        text = 'Example: You set 0.10 lot. Master opens 1.00 lot → your order is placed at 0.10 lot (always same fixed size).';
        break;
      case 'proportional_equity':
        text = 'Example: Your equity \$5,000, master equity \$50,000 (ratio 10%). Master opens 1.00 lot → your order is placed at 0.10 lot.';
        break;
      case 'proportional_balance':
        text = 'Example: Your balance \$5,000, master balance \$50,000 (ratio 10%). Master opens 1.00 lot → your order is placed at 0.10 lot.';
        break;
      case 'multiplier_only':
        text = 'Example: Multiplier set to 2×. Master opens 0.50 lot → your order is placed at 1.00 lot (0.50 × 2 = 1.00).';
        break;
      case 'mirror_ratio':
        text = 'Example: Ratio set to 0.5. Master opens 1.00 lot → your order is placed at 0.50 lot (1.00 × 0.5 = 0.50).';
        break;
      case 'percentage_risk':
        text = 'Example: Risk 2% of your \$10,000 balance = \$200 at risk. With 50‑pip SL → lot is auto-calculated.';
        break;
      case 'reverse':
        text = 'Lots follow the selected sizing method; only direction flips.';
        break;
      case 'dynamic_lot':
        text = 'Example: Equity-based → your order is placed at 0.10 lot. If drawdown exceeds your threshold, future orders reduce (e.g. to 0.05 lot).';
        break;
      case 'fixed_ratio':
        text = 'Example: Equity-based → your order is placed at 0.10 lot. For every \$1,000 profit earned, future orders increase by 0.01 lot.';
        break;
      default:
        text = '';
    }
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(text, style: AppTextStyles.caption);
  }
}

class _AdvancedSettingsCard extends StatelessWidget {
  final CopyTradingSubscribeController controller;
  final TextEditingController tpCtrl;
  final TextEditingController slCtrl;
  final RxBool customMultiplier;
  final TextEditingController multiplierCtrl;
  final ValueChanged<double> onMultiplierPreset;
  final VoidCallback onMultiplierCustom;
  final ValueChanged<num> onTpPreset;
  final ValueChanged<num> onSlPreset;
  const _AdvancedSettingsCard({
    required this.controller,
    required this.tpCtrl,
    required this.slCtrl,
    required this.customMultiplier,
    required this.multiplierCtrl,
    required this.onMultiplierPreset,
    required this.onMultiplierCustom,
    required this.onTpPreset,
    required this.onSlPreset,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      elevation: 0.10,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.only(top: 10.h),
          title: Text('Advanced Settings', style: AppTextStyles.black14600),
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.tradeBackgroundCenterColor.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.grey.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final proportional = controller.copyingMethod.value == 'proportional';
                    if (!proportional) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LOT MULTIPLIER', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                        SizedBox(height: 8.h),
                        Text('Multiply master lot size', style: AppTextStyles.black14500),
                        SizedBox(height: 10.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            _SmallChoiceChip(
                              label: '1x',
                              selected: !customMultiplier.value && controller.lotMultiplier.value == 1,
                              onTap: () => onMultiplierPreset(1),
                            ),
                            _SmallChoiceChip(
                              label: '2x',
                              selected: !customMultiplier.value && controller.lotMultiplier.value == 2,
                              onTap: () => onMultiplierPreset(2),
                            ),
                            _SmallChoiceChip(
                              label: '3x',
                              selected: !customMultiplier.value && controller.lotMultiplier.value == 3,
                              onTap: () => onMultiplierPreset(3),
                            ),
                            _SmallChoiceChip(
                              label: '4x',
                              selected: !customMultiplier.value && controller.lotMultiplier.value == 4,
                              onTap: () => onMultiplierPreset(4),
                            ),
                            _SmallChoiceChip(
                              label: '5x',
                              selected: !customMultiplier.value && controller.lotMultiplier.value == 5,
                              onTap: () => onMultiplierPreset(5),
                            ),
                            _SmallChoiceChip(
                              label: 'Custom',
                              selected: customMultiplier.value,
                              onTap: onMultiplierCustom,
                            ),
                          ],
                        ),
                        if (customMultiplier.value) ...[
                          SizedBox(height: 10.h),
                          LabeledAppTextField(
                            label: '',
                            controller: multiplierCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            hintText: 'e.g. 2',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              const SingleDecimalTextFormatter(),
                            ],
                          ),
                        ],
                        SizedBox(height: 6.h),
                        Text(
                          'Master trades 1 lot → your lot = 1 lot × ${customMultiplier.value ? (multiplierCtrl.text.isEmpty ? 'x' : multiplierCtrl.text) : '${controller.lotMultiplier.value}x'}',
                          style: AppTextStyles.caption,
                        ),
                        SizedBox(height: 14.h),
                        Divider(color: Colors.grey.withOpacity(0.16), height: 1),
                        SizedBox(height: 14.h),
                      ],
                    );
                  }),
                  Row(
                    children: [
                      Text('PER-TRADE TP / SL', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const Spacer(),
                      Obx(() {
                        return Row(
                          children: [
                            SizedBox(
                              width: 35.w,
                              height: 35.h,
                              child: Checkbox(
                                value: controller.overridesSlTp.value,
                                onChanged: (v) => controller.overridesSlTp.value = v ?? false,
                              ),
                            ),
                            Text('Override master', style: AppTextStyles.textButton),
                          ],
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Set your own TP / SL in pips or a fixed dollar amount. Pip mode: 1 pip = 0.0001 for EURUSD · 0.01 for JPY pairs · \$1.00 for XAUUSD / metals. Dollar mode: trade closes when profit or loss reaches the dollar target you set.',
                    style: AppTextStyles.caption,
                  ),
                  
                  SizedBox(height: 10.h),
                  Obx(() {
                    final enabled = controller.overridesSlTp.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(!enabled)...[
                          SizedBox(height: 10.h),
                  Text(
                    'No TP/SL configured by master — trades will open without automatic TP/SL.',
                    style: AppTextStyles.caption,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Using master\'s TP/SL. Enable "Override master" to set your own levels.',
                    style: AppTextStyles.caption,
                  ),
                        ],
                       
                        if (enabled) ...[
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
                                child: Wrap(
                                  spacing: 6.w,
                                  runSpacing: 6.h,
                                  children: (controller.slTpMode.value == 'pip'
                                          ? const [5, 10, 15]
                                          : const [5, 10, 20])
                                      .map((v) => _MiniPresetChip(
                                            label: controller.slTpMode.value == 'pip' ? '$v' : r'$' '$v',
                                            onTap: () => onTpPreset(v),
                                          ))
                                      .toList(),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Wrap(
                                  spacing: 6.w,
                                  runSpacing: 6.h,
                                  children: (controller.slTpMode.value == 'pip'
                                          ? const [5, 10, 15]
                                          : const [5, 10, 20])
                                      .map((v) => _MiniPresetChip(
                                            label: controller.slTpMode.value == 'pip' ? '$v' : r'$' '$v',
                                            onTap: () => onSlPreset(v),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                           Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.slTpMode.value == 'pip' ? 'Take Profit (pips)' : 'Take Profit (\$)',
                                    style: AppTextStyles.caption,
                                  ),
                                  SizedBox(height: 6.h),
                                  LabeledAppTextField(
                                    label: '',
                                    controller: tpCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    hintText: enabled ? (controller.slTpMode.value == 'pip' ? 'Custom pips' : 'e.g. 25') : 'Disabled',
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                      // const SingleDecimalTextFormatter(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.slTpMode.value == 'pip' ? 'Stop Loss (pips)' : 'Stop Loss (\$)',
                                    style: AppTextStyles.caption,
                                  ),
                                  SizedBox(height: 6.h),
                                  LabeledAppTextField(
                                    label: '',
                                    controller: slCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    hintText: enabled ? (controller.slTpMode.value == 'pip' ? 'Custom pips' : 'e.g. 20') : 'Disabled',
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                      const SingleDecimalTextFormatter(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      
                        SizedBox(height: 10.h),
                  Text(
                    'Your own TP/SL will be used instead of master\'s. Master\'s SL/TP changes will not affect your trades.',
                    style: AppTextStyles.caption,
                  ),
                  ],
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

class _SmallChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SmallChoiceChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.withOpacity(0.18)),
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

class _MiniPresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MiniPresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.withOpacity(0.18)),
        ),
        child: Text(label, style: AppTextStyles.grey11400),
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
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
          LabeledAppTextField(
            label: 'Investment Amount (USD) *',
            controller: investmentCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: minCapital > 0 ? 'Min $minCapital' : 'Enter amount',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              const SingleDecimalTextFormatter(),
            ],
            prefixIcon: Padding(
              padding: EdgeInsets.all(0.w),
              child: Text(r'$', style: AppTextStyles.input),
            ),
          ),
          SizedBox(height: 6.h),
          if (minCapital > 0) Text('Minimum investment: \$$minCapital', style: AppTextStyles.caption), 
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final double elevation;
  const _Card({required this.child, this.elevation = 0.03});

  @override
  Widget build(BuildContext context) {
    final clamped = elevation.clamp(0.0, 0.25);
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(clamped),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: EdgeInsets.zero),
              child: SizedBox(
                height: 44.h,
                child: Center(child: Text('Retry', style: AppTextStyles.button)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanInfoCard extends StatelessWidget {
  final CopyTradingPlan plan;
  const _PlanInfoCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.planName, style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (plan.commissionType.isNotEmpty)
                _Pill(
                  text: plan.commissionType.toUpperCase(),
                  tone: _PillTone.primary,
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text('Min: \$${plan.minimumCapital}', style: AppTextStyles.caption),
              SizedBox(width: 12.w),
              Text('Fee: ${plan.commissionLabel.isNotEmpty ? plan.commissionLabel : plan.commissionType}', style: AppTextStyles.caption),
              SizedBox(width: 12.w),
              Text('${plan.subscriptionFee > 0 ? '\$${plan.subscriptionFee}' : '\$0'} / ${plan.subscriptionPeriodDays} days', style: AppTextStyles.caption),
            ],
          ),
          SizedBox(height: 6.h),
          Text('Grace: ${plan.noFeeDays} days', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _PlanDropdown extends StatelessWidget {
  final List<CopyTradingPlan> plans;
  final CopyTradingPlan? selected;
  final ValueChanged<CopyTradingPlan> onChanged;
  const _PlanDropdown({required this.plans, required this.selected, required this.onChanged});

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
        child: DropdownButton<int?>(
          value: selected?.planId,
          isExpanded: true,
          items: plans
              .map((p) => DropdownMenuItem<int>(
                    value: p.planId,
                    child: Text(
                      '${p.planName.isNotEmpty ? p.planName : 'Plan ${p.planId}'} — Fee ${p.subscriptionFee > 0 ? '\$${p.subscriptionFee}' : p.commissionLabel} / ${p.subscriptionPeriodDays} days',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.black14500,
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            for (final p in plans) {
              if (p.planId == v) {
                onChanged(p);
                break;
              }
            }
          },
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final List<EligibleCopyAccount> accounts;
  final EligibleCopyAccount? selected;
  final num minCapital;
  final ValueChanged<EligibleCopyAccount> onChanged;
  const _AccountDropdown({required this.accounts, required this.selected, required this.minCapital, required this.onChanged});

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
        child: DropdownButton<int?>(
          value: selected?.id,
          hint: Text('-- Select Account --', style: AppTextStyles.black14500.copyWith(color: AppColors.textGrey)),
          isExpanded: true,
          items: accounts
              .map((a) => DropdownMenuItem<int>(
                    value: a.id,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.metaAccountNumber, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.black14600),
                              SizedBox(height: 1.h),
                              Text('${a.accountType} • Equity \$${a.equity}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        if (minCapital > 0 && a.equity < minCapital) _Pill(text: 'Below min', tone: _PillTone.warning),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            for (final a in accounts) {
              if (a.id == v) {
                onChanged(a);
                break;
              }
            }
          },
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final RxBool isLoading;
  final RxInt step;
  final VoidCallback onNext;
  final Future<void> Function() onSubscribe;
  const _BottomBar({required this.isLoading, required this.step, required this.onNext, required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.tradeBackgroundCenterColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Obx(() {
        final s = step.value;
        final loading = isLoading.value;
        return SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44.h,
                  child: OutlinedButton(
                    onPressed: loading
                        ? null
                        : () {
                            if (s == 0) {
                              Get.back();
                            } else {
                              step.value = 0;
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: AppColors.primary.withOpacity(0.55)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: Text('Back', style: AppTextStyles.outlinedButton),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (s == 0) {
                              onNext();
                            } else {
                              await onSubscribe();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: loading
                        ? SizedBox(width: 18.r, height: 18.r, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(s == 0 ? 'Next' : 'Subscribe', style: AppTextStyles.button),
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

enum _PillTone { primary, warning }

class _Pill extends StatelessWidget {
  final String text;
  final _PillTone tone;
  const _Pill({required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;
    if (tone == _PillTone.primary) {
      bg = AppColors.primary.withOpacity(0.10);
      border = AppColors.primary.withOpacity(0.22);
      fg = AppColors.primary;
    } else {
      bg = const Color(0xFFF59E0B).withOpacity(0.12);
      border = const Color(0xFFF59E0B).withOpacity(0.25);
      fg = const Color(0xFFF59E0B);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: border)),
      child: Text(text, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: fg)),
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
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18.r, color: AppColors.error),
          SizedBox(width: 8.w),
          Expanded(child: Text(message, style: AppTextStyles.caption.copyWith(color: AppColors.error))),
          SizedBox(width: 8.w),
          TextButton(onPressed: onRetry, style: TextButton.styleFrom(padding: EdgeInsets.zero), child: Text('Retry', style: AppTextStyles.textButton)),
        ],
      ),
    );
  }
}

