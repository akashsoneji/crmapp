import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_dashboard_controller.dart';
import 'package:crm_app/utils/app_logger.dart';
import 'package:crm_app/widgets/app_select_field.dart';
import 'package:crm_app/widgets/app_svg_back_button.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CopyTradingCreatePlanScreen extends StatefulWidget {
  final CopyTradingMasterDashboardController controller;

  const CopyTradingCreatePlanScreen({super.key, required this.controller});

  @override
  State<CopyTradingCreatePlanScreen> createState() =>
      _CopyTradingCreatePlanScreenState();
}

class _CopyTradingCreatePlanScreenState
    extends State<CopyTradingCreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedEligibleAccountIndex;
  final _nameCtrl = TextEditingController();
  String _commissionType = 'per_trade';
  final _commissionCtrl = TextEditingController();
  String? _subscriptionPeriod;
  final _noFeeDaysCtrl = TextEditingController(text: '0');
  final _minCapitalCtrl = TextEditingController();
  final _strategyCtrl = TextEditingController();
  final _riskCtrl = TextEditingController();
  final _tpPipsCtrl = TextEditingController();
  final _slPipsCtrl = TextEditingController();

  CopyTradingMasterDashboardController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.loadEligibleAccountsForCreatePlan();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commissionCtrl.dispose();
    _noFeeDaysCtrl.dispose();
    _minCapitalCtrl.dispose();
    _strategyCtrl.dispose();
    _riskCtrl.dispose();
    _tpPipsCtrl.dispose();
    _slPipsCtrl.dispose();
    super.dispose();
  }

  Color get _mutedText => AppColors.textGrey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        centerTitle: true,
        title: Text('Create New Plan', style: AppTextStyles.heading),
        leading: AppSvgBackButton(
          onPressed: () => Get.back(closeOverlays: true),
          iconWidth: 30.w,
          iconHeight: 30.h,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.15),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trading Account *',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Obx(() {
                        if (_controller.eligibleAccountsLoading.value) {
                          return const LinearProgressIndicator(minHeight: 2);
                        }
                        final err = _controller.eligibleAccountsError.value;
                        if (err.isNotEmpty) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 6.h),
                            child: Text(
                              err,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        final accounts = _controller.eligibleAccounts;
                        return AppSelectField<int>(
                          value: _selectedEligibleAccountIndex,
                          hint: '-- Select Account --',
                          sheetTitle: 'Trading Account',
                          enabled: accounts.isNotEmpty,
                          options: List.generate(accounts.length, (i) {
                            final a = accounts[i];
                            return AppSelectOption<int>(
                              value: i,
                              title:
                                  '${a.metaAccountNumber} (\$${a.balance}) - ${a.lpProviderName}',
                              subtitle: '${a.tradingServer} · ${a.accountType}',
                            );
                          }),
                          onChanged:
                              (i) => setState(
                                () => _selectedEligibleAccountIndex = i,
                              ),
                        );
                      }),
                      SizedBox(height: 14.h),
                      Text(
                        'Plan Name *',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _nameCtrl,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Enter plan name'
                                    : null,
                        decoration: InputDecoration(
                          hintText: 'e.g. Conservative Growth Plan',
                          hintStyle: TextStyle(
                            fontSize: 12.sp,
                            color: _mutedText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      _buildCommissionSection(),
                      if (_commissionType == 'subscription') ...[
                        SizedBox(height: 14.h),
                        Text(
                          'Billing Period *',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: _mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        AppSelectField<String>(
                          value: _subscriptionPeriod ?? 'monthly',
                          hint: 'Select billing period',
                          sheetTitle: 'Billing Period',
                          options: const [
                            AppSelectOption(value: 'weekly', title: 'Weekly'),
                            AppSelectOption(value: 'monthly', title: 'Monthly'),
                            AppSelectOption(
                              value: 'quarterly',
                              title: 'Quarterly',
                            ),
                          ],
                          onChanged:
                              (v) => setState(
                                () => _subscriptionPeriod = v ?? 'monthly',
                              ),
                        ),
                      ],
                      SizedBox(height: 14.h),
                      _buildGraceAndCapitalRow(),
                      SizedBox(height: 14.h),
                      Text(
                        'Strategy Description',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _strategyCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Describe your trading strategy, risk management approach, and what makes your trading unique.',
                          hintStyle: TextStyle(
                            fontSize: 12.sp,
                            color: _mutedText,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Risk Information',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _riskCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Describe the risk level and potential drawdowns of your strategy.',
                          hintStyle: TextStyle(
                            fontSize: 12.sp,
                            color: _mutedText,
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      _buildTpSlSection(),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 24.h),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 360;

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commission Type *',
              style: TextStyle(
                fontSize: 12.sp,
                color: _mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            AppSelectField<String>(
              value: _commissionType,
              hint: 'Select commission type',
              sheetTitle: 'Commission Type',
              options: const [
                AppSelectOption(
                  value: 'per_trade',
                  title: 'Per Trade (% commission)',
                ),
                AppSelectOption(
                  value: 'subscription',
                  title: 'Subscription (flat fee)',
                ),
              ],
              onChanged:
                  (v) => setState(() {
                    _commissionType = v ?? 'per_trade';
                    if (_commissionType != 'subscription') {
                      _subscriptionPeriod = null;
                      _commissionCtrl.clear();
                    } else {
                      _subscriptionPeriod ??= 'monthly';
                    }
                  }),
            ),
          ],
        );

        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _commissionType == 'per_trade'
                  ? 'Commission (%) *'
                  : 'Subscription Fee (USD) *',
              style: TextStyle(
                fontSize: 12.sp,
                color: _mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _commissionCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: InputDecoration(
                hintText:
                    _commissionType == 'per_trade' ? 'e.g. 30' : 'e.g. 50',
                hintStyle: TextStyle(fontSize: 12.sp, color: _mutedText),
              ),
            ),
          ],
        );

        if (stack) {
          return Column(children: [left, SizedBox(height: 12.h), right]);
        }
        return Row(
          children: [
            Expanded(child: left),
            SizedBox(width: 12.w),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _buildGraceAndCapitalRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 360;

        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No-Fee Grace Period (days)',
              style: TextStyle(
                fontSize: 12.sp,
                color: _mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _noFeeDaysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(),
            ),
          ],
        );

        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minimum Capital (USD) *',
              style: TextStyle(
                fontSize: 12.sp,
                color: _mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _minCapitalCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: InputDecoration(
                hintText: 'e.g. 100',
                hintStyle: TextStyle(fontSize: 12.sp, color: _mutedText),
              ),
            ),
          ],
        );

        if (stack) {
          return Column(children: [left, SizedBox(height: 12.h), right]);
        }
        return Row(
          children: [
            Expanded(child: left),
            SizedBox(width: 12.w),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _buildTpSlSection() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PER-TRADE TP / SL (PIPS)',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Set fixed take profit and stop loss for every copied trade. Leave empty or 0 to disable.',
            style: TextStyle(
              fontSize: 11.sp,
              color: _mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Take Profit (Pips)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _tpPipsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(hintText: 'e.g. 50'),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stop Loss (Pips)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _slPipsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(hintText: 'e.g. 30'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Obx(() {
      final loading = _controller.isLoading.value;
      return Row(
        children: [
          Expanded(child: _buildCancelButton(loading: loading)),
          SizedBox(width: 12.w),
          Expanded(child: _buildCreatePlanButton(loading: loading)),
        ],
      );
    });
  }

  Widget _buildCancelButton({required bool loading}) {
    return SizedBox(
      height: 46.h,
      child: OutlinedButton(
        onPressed: loading ? null : () => Get.back(),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          'Cancel',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePlanButton({required bool loading}) {
    return SizedBox(
      height: 46.h,
      child: ElevatedButton(
        onPressed: loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.whiteColor,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child:
            loading
                ? CommonLoadingWidget(size: 22, color: AppColors.whiteColor)
                : Text(
                  'Create Plan',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteColor,
                  ),
                ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedEligibleAccountIndex == null) {
      Get.snackbar(
        'Required',
        'Select trading account',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final idx = _selectedEligibleAccountIndex!;
    if (idx < 0 || idx >= _controller.eligibleAccounts.length) {
      Get.snackbar(
        'Invalid',
        'Select a valid trading account',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final acc = _controller.eligibleAccounts[idx];
    final commissionValue = num.tryParse(_commissionCtrl.text.trim());
    final minCap = num.tryParse(_minCapitalCtrl.text.trim());
    if (commissionValue == null || minCap == null) {
      Get.snackbar(
        'Invalid',
        'Enter valid numeric values',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final body = <String, dynamic>{
      'trading_account_id': acc.id,
      'name': _nameCtrl.text.trim(),
      'commission_type': _commissionType,
      'commission_value': commissionValue,
      'min_capital': minCap,
      'no_fee_days': int.tryParse(_noFeeDaysCtrl.text.trim()) ?? 0,
      'strategy_description': _strategyCtrl.text.trim(),
      'risk_info': _riskCtrl.text.trim(),
    };
    if (_commissionType == 'subscription') {
      body['subscription_fee'] = commissionValue;
      body['subscription_period'] = (_subscriptionPeriod ?? 'monthly');
    }
    final tp = num.tryParse(_tpPipsCtrl.text.trim());
    final sl = num.tryParse(_slPipsCtrl.text.trim());
    if (tp != null && tp > 0) body['take_profit_pips'] = tp;
    if (sl != null && sl > 0) body['stop_loss_pips'] = sl;

    AppLogger.debug('Create plan payload: $body');
    final res = await _controller.createPlan(body);
    if (res.success) {
      Get.back();
      Get.snackbar(
        'Created',
        res.message ?? 'Plan created',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Failed',
        res.message ?? _controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
