import 'package:crm_app/widgets/app_svg_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/finance/deposit_controller.dart';
import 'package:crm_app/screens/home/more/finance/deposit_instruction_screen.dart';
import 'package:crm_app/utils/trl_helper.dart';
import 'package:crm_app/utils/navigation_helper.dart';
import 'package:crm_app/utils/currency_format.dart';
import 'package:crm_app/models/mt5_account.dart' as mt5m;
import 'package:crm_app/controllers/account_controller.dart';
import '../../../../services/api_service.dart';
import '../../../../services/language_service.dart';
import '../../../../widgets/custom_toast.dart';

mt5m.MT5Account? _resolveMt5Account(String? metaAccountNumber) {
  if (metaAccountNumber == null || metaAccountNumber.isEmpty) return null;
  if (!Get.isRegistered<AccountController>()) return null;
  for (final acc in Get.find<AccountController>().mt5Accounts) {
    if (acc.metaAccountNumber == metaAccountNumber) return acc;
  }
  return null;
}

/// Formats an MT5 balance with `¢` for cent accounts and `$` otherwise.
String _fmtMt5(dynamic balanceLike, String? metaAccountNumber) {
  final n = double.tryParse(balanceLike?.toString() ?? '') ?? 0;
  return CurrencyFormat.amount(n, _resolveMt5Account(metaAccountNumber));
}

class DepositRealScreen extends StatefulWidget {
  final Map<String, dynamic> object;
  final String? preselectedAccountNumber;

  DepositRealScreen({
    super.key,
    required this.object,
    String? preselectedAccountNumber,
  }) : preselectedAccountNumber =
           // Prioritize Get.arguments first (set during navigation), then fall back to parameter
           (Get.arguments != null && Get.arguments!['accountNumber'] != null
               ? (Get.arguments!['accountNumber'] as String)
               : null) ??
           preselectedAccountNumber {
    // Debug: Log when widget is created
    print('========================================');
    print('DepositRealScreen: WIDGET CONSTRUCTOR CALLED');
    print(
      'DepositRealScreen: constructor parameter: "$preselectedAccountNumber"',
    );
    print('DepositRealScreen: Get.arguments: ${Get.arguments}');
    print(
      'DepositRealScreen: Get.arguments accountNumber: ${Get.arguments?['accountNumber']}',
    );
    print(
      'DepositRealScreen: final preselectedAccountNumber: "${this.preselectedAccountNumber}"',
    );
    print(
      'DepositRealScreen: preselectedAccountNumber is null: ${this.preselectedAccountNumber == null}',
    );
    print(
      'DepositRealScreen: preselectedAccountNumber type: ${this.preselectedAccountNumber.runtimeType}',
    );
    print('========================================');
  }

  @override
  State<DepositRealScreen> createState() => _DepositRealScreenState();
}

class _DepositRealScreenState extends State<DepositRealScreen> {
  late final DepositController controller;
  final ApiService apiService = Get.put(ApiService());

  String selectedPaymentMode = 'UPI';
  String selectedAccount = '0';
  String selectedCurrency = 'USD';
  final TextEditingController amountController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController transferToController = TextEditingController(
    text: '',
  );
  /// Read-only amount credited to the account (USD/USC), derived from
  /// [amountController] using the API's conversion_rate.
  final TextEditingController targetAmountController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController paymentModeController = TextEditingController(
    text: '',
  );
  final double fee = 20.00; // Fee in INR

  final List<String> accounts = ['0', '0', '0'];
  final List<String> currencies = ['USD', 'EUR', 'GBP'];

  late final LanguageService languageService;
  late final FocusNode amountFocusNode;

  @override
  void initState() {
    super.initState();
    // Delete any existing instance to ensure fresh state
    if (Get.isRegistered<DepositController>()) {
      Get.delete<DepositController>();
    }
    controller = Get.put(DepositController());

    languageService = Get.find<LanguageService>();

    // Initialize FocusNode for amount field
    amountFocusNode = FocusNode();
    amountFocusNode.addListener(() {
      if (amountFocusNode.hasFocus && amountController.text == '0.00') {
        amountController.text = '';
      } else if (!amountFocusNode.hasFocus && amountController.text.isEmpty) {
        amountController.text = '0.00';
      }
    });

    // Rebuild "To be deposited" as user types
    amountController.addListener(() {
      _syncTargetAmount();
      if (mounted) setState(() {});
    });
    // Switching to/from a cent account or a new rate changes the credited amount.
    ever(controller.selectedTransferAccount, (_) => _syncTargetAmount());
    ever(controller.depositMethod, (_) => _syncTargetAmount());
    final preselectedAccount = widget.preselectedAccountNumber;
    print('DepositRealScreen: initState called');
    print('DepositRealScreen: preselectedAccountNumber: "$preselectedAccount"');
    print(
      'DepositRealScreen: preselectedAccountNumber is null: ${preselectedAccount == null}',
    );
    print(
      'DepositRealScreen: preselectedAccountNumber isEmpty: ${preselectedAccount?.isEmpty ?? true}',
    );
    print(
      'DepositRealScreen: preselectedAccountNumber type: ${preselectedAccount.runtimeType}',
    );

    paymentModeController.text =
        widget.object['display_name']; // adjust field name per API
    selectedPaymentMode = widget.object['display_name'];

    // CRITICAL: Store account number in a local variable to ensure it's captured
    final accountNumberToPass = preselectedAccount;
    print('DepositRealScreen: Calling fetchAccountsForPaymentMethod');
    print(
      'DepositRealScreen: accountNumberToPass value: "$accountNumberToPass"',
    );
    print(
      'DepositRealScreen: accountNumberToPass is null: ${accountNumberToPass == null}',
    );
    print(
      'DepositRealScreen: accountNumberToPass isEmpty: ${accountNumberToPass?.isEmpty ?? true}',
    );

    if (accountNumberToPass != null && accountNumberToPass.isNotEmpty) {
      print(
        'DepositRealScreen: ✅ Account number is valid, passing to controller: "$accountNumberToPass"',
      );
    } else {
      print('DepositRealScreen: ❌ WARNING: Account number is null or empty!');
      print(
        'DepositRealScreen: widget.preselectedAccountNumber: "${widget.preselectedAccountNumber}"',
      );
    }

    controller.fetchAccountsForPaymentMethod(
      widget.object['deposit_slug'],
      preselectedAccountNumber: accountNumberToPass,
    );

    ever(controller.selectedTransferAccount, (account) {
      if (account != null) {
        final accountNumber =
            account['meta_account_number']?.toString() ?? 'null';
        print(
          'DepositRealScreen: selectedTransferAccount changed to: $accountNumber',
        );
        transferToController.text =
            "${account['meta_account_number']} - ${_fmtMt5(account['balance'], account['meta_account_number']?.toString())}";
        selectedAccount = account['meta_account_number'].toString();
        print(
          'DepositRealScreen: Updated transferToController.text to: ${transferToController.text}',
        );
      } else {
        print('DepositRealScreen: selectedTransferAccount is null');
      }
    });
  }

  @override
  void dispose() {
    amountFocusNode.dispose();
    amountController.dispose();
    targetAmountController.dispose();
    transferToController.dispose();
    paymentModeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is visible
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: 
        AppSvgBackButton(
          onPressed: () => NavigationHelper.safeBack(context: context),
          iconWidth: 30.w,
          iconHeight: 30.h,
        ),
            title: Text(
          languageService.tr('deposit'),
          style: AppTextStyles.screenTitle,
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                // Payment Mode Field
                _buildPaymentModeField(),

                SizedBox(height: 24.h),

                // Transfer to Field
                _buildTransferToField(),

                SizedBox(height: 24.h),

                // Amount Field
                _buildAmountField(),

                // Fee Display
                SizedBox(height: 26.h),

                // _buildFeeDisplay(),

                // To be deposited Section
                _buildToBeDepositedSection(),

                SizedBox(height: 24.h),

                // Continue Button

                // Flexible space to push like button down
                // SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                // _buildContinueButton(),

                // Dynamic bottom padding based on keyboard visibility
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 40.h,
            child: _buildContinueButton(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentModeField() {
    return RTLHelper.rtlTextField(
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      controller: paymentModeController,
      readOnly: true, // field is non-editable
      onTap: null, // disable dropdown tap
      decoration: InputDecoration(
        labelText: 'Payment Mode',
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildTransferToField() {
    return RTLHelper.rtlTextField(
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      controller: transferToController,
      readOnly: true,
      onTap: () => _showAccountDropdown(),
      suffixIcon: InkWell(
        onTap: () => _showAccountDropdown(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: RTLHelper.rtlIcon(Icons.arrow_drop_down, color: AppColors.textGrey),
        ),
      ),
      decoration: InputDecoration(
        labelText: 'Deposit to',
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Obx(() {
      final m = controller.depositMethod.value;
      controller.selectedTransferAccount.value; // reactive trigger
      final minLimit = double.tryParse(m?['min_limit']?.toString() ?? '');
      final maxLimit = double.tryParse(m?['max_limit']?.toString() ?? '');
      final sourceCurrency = _sourceCurrency;
      final targetCurrency = _targetCurrency;
      final showTarget = sourceCurrency != targetCurrency;

      final entered = double.tryParse(amountController.text.trim()) ?? 0;
      final usdValue = _convertedAmount(entered);

      String? error;
      if (entered > 0) {
        if (minLimit != null && usdValue < minLimit) {
          error = 'Minimum deposit is ${_formatLimit(minLimit)}';
        } else if (maxLimit != null && usdValue > maxLimit) {
          error = 'Maximum deposit is ${_formatLimit(maxLimit)}';
        }
      }
      final limitText = (minLimit != null && maxLimit != null)
          ? 'Limit: ${_formatLimit(minLimit)} - ${_formatLimit(maxLimit)}'
          : null;

      final amountStyle = TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );
      final helperStyle = TextStyle(color: AppColors.textGrey, fontSize: 12.sp);

      final sourceField = RTLHelper.rtlTextField(
        style: amountStyle,
        controller: amountController,
        focusNode: amountFocusNode,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          _SingleDecimalTextFormatter(),
        ],
        decoration: _amountDecoration(
          label: 'Amount',
          currency: sourceCurrency,
          hasError: error != null,
        ),
      );

      final flowParts = <String>[
        '${entered.toStringAsFixed(2)} $sourceCurrency',
        if (sourceCurrency != 'USD') '${usdValue.toStringAsFixed(2)} USD',
        if (targetCurrency != 'USD')
          '${_toTargetAmount(entered).toStringAsFixed(2)} $targetCurrency',
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTarget)
            Row(
              children: [
                Expanded(child: sourceField),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    '=',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: targetAmountController,
                    readOnly: true,
                    canRequestFocus: false,
                    enableInteractiveSelection: false,
                    style: amountStyle.copyWith(fontWeight: FontWeight.w600),
                    textDirection: TextDirection.ltr,
                    decoration: _amountDecoration(
                      label: 'You will receive',
                      currency: targetCurrency,
                    ).copyWith(
                      filled: true,
                      fillColor: AppColors.primary.withOpacity(0.05),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),
                ),
              ],
            )
          else
            sourceField,
          SizedBox(height: 6.h),
          if (error != null)
            Text(
              error,
              style: TextStyle(color: AppColors.error, fontSize: 12.sp),
            )
          else if (limitText != null)
            Text(limitText, style: helperStyle),
          if (showTarget && entered > 0) ...[
            SizedBox(height: 4.h),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                flowParts.join(' → '),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          if (_hasConversion && _conversionRate > 0) ...[
            SizedBox(height: 4.h),
            Text(
              '1 USD = ${NumberFormat('#,##0.00', 'en_US').format(_conversionRate)} $sourceCurrency',
              style: helperStyle,
            ),
          ],
        ],
      );
    });
  }

  InputDecoration _amountDecoration({
    required String label,
    required String currency,
    bool hasError = false,
  }) {
    final borderColor = hasError ? AppColors.error : AppColors.border;
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: TextStyle(
        color: hasError ? AppColors.error : AppColors.primary,
      ),
      hintText: '0.00',
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      suffixIcon: _buildCurrencyTag(currency),
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? AppColors.error : AppColors.primary,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildCurrencyTag(String currency) {
    return Container(
      margin: EdgeInsetsDirectional.only(end: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        currency,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  bool get _hasConversion {
    final m = controller.depositMethod.value;
    return m != null && m['has_conversion'] == true;
  }

  /// Currency the user pays in (e.g. INR from the method's currency_name).
  String get _sourceCurrency {
    final m = controller.depositMethod.value;
    final name = m?['currency_name']?.toString();
    return (name == null || name.isEmpty) ? selectedCurrency : name;
  }

  double get _conversionRate {
    final m = controller.depositMethod.value;
    final raw = m?['conversion_rate'];
    if (raw == null) return 0;
    return double.tryParse(raw.toString()) ?? 0;
  }

  /// Gateway fee percentage from the method detail (`fees`, e.g. "1.00").
  double get _feePercent =>
      double.tryParse(controller.depositMethod.value?['fees']?.toString() ?? '') ??
      0;

  /// Rate as shown on the web (2 dp); the gateway converts back with this
  /// figure, so using it keeps the payer's charge equal to the entered amount.
  double get _displayRate =>
      double.parse(_conversionRate.toStringAsFixed(2));

  bool get _isCentAccount {
    final account = controller.selectedTransferAccount.value;
    if (account == null) return false;
    return account['is_cent_account'] == true ||
        account['currency']?.toString().toUpperCase() == 'USC';
  }

  /// Currency the selected MT5 account / wallet is credited in.
  String get _targetCurrency => _isCentAccount ? 'USC' : 'USD';

  /// Limits from the API are in USD; cent accounts also see the USC figure.
  String _formatLimit(double usdLimit) {
    final usd = '${usdLimit.toStringAsFixed(2)} USD';
    if (!_isCentAccount) return usd;
    return '$usd (${(usdLimit * 100).toStringAsFixed(2)} USC)';
  }

  /// Converts the entered source-currency amount into USD, which is what
  /// min/max limits are expressed in. The fee is taken out here because the
  /// gateway adds it back on top, so the payer is charged exactly [entered].
  double _convertedAmount(double entered) {
    if (_hasConversion && _displayRate > 0) {
      return entered / (1 + _feePercent / 100) / _displayRate;
    }
    return entered;
  }

  /// USD amount sent to redirect gateways: 6 dp when converted, raw otherwise.
  String _redirectUsdAmount(double entered) {
    if (!(_hasConversion && _conversionRate > 0)) return entered.toString();
    return _convertedAmount(entered).toStringAsFixed(6);
  }

  /// Amount credited to the account, in [_targetCurrency] (100 USC = 1 USD).
  double _toTargetAmount(double entered) {
    final usd = _convertedAmount(entered);
    return _isCentAccount ? usd * 100 : usd;
  }

  void _syncTargetAmount() {
    if (!mounted) return;
    final entered = double.tryParse(amountController.text.trim()) ?? 0;
    targetAmountController.text = _toTargetAmount(entered).toStringAsFixed(6);
  }

  Widget _buildFeeDisplay() {
    return Align(
      alignment: Alignment.centerRight,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '₹',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
            TextSpan(
              text: '${fee.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.icongrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToBeDepositedSection() {
    return Obx(() {
      controller.depositMethod.value; // reactive trigger
      controller.selectedTransferAccount.value;
      final entered = double.tryParse(amountController.text.trim()) ?? 0;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'To be deposited',
                style: TextStyle(fontSize: 13.sp, color: AppColors.textGrey),
              ),
            ),
            SizedBox(width: 8.w),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '$_targetCurrency ${_toTargetAmount(entered).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: _handleDeposit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        padding: EdgeInsets.zero,
      ),
      child: Text(
        'Confirm',
        style: TextStyle(
          fontSize: 14.sp,
          height: 1.71,
          fontWeight: FontWeight.w600,
          color: AppColors.whiteColor,
        ),
      ),
    );
  }

  void _handleDeposit() async {
    // Show loading

    final raw = amountController.text.trim();
    final entered = double.tryParse(raw);
    if (entered == null || entered <= 0) {
      CustomToastService.showError(message: 'Please enter a valid amount');
      return;
    }

    final m = controller.depositMethod.value;
    if (m != null) {
      final minLimit = double.tryParse(m['min_limit']?.toString() ?? '');
      final maxLimit = double.tryParse(m['max_limit']?.toString() ?? '');
      final converted = _convertedAmount(entered);
      if (minLimit != null && converted < minLimit) {
        CustomToastService.showError(
          message: 'Amount cannot be less than minimum limit of ${_formatLimit(minLimit)}',
        );
        return;
      }
      if (maxLimit != null && converted > maxLimit) {
        CustomToastService.showError(
          message: 'Amount cannot be more than maximum limit of ${_formatLimit(maxLimit)}',
        );
        return;
      }
    }

    // `is_redirect` and `deposit_api` come on the methods list item; the
    // detail object does not carry them, so fall back to the list values.
    final methodDetail = controller.depositMethod.value!;
    final listItem = widget.object;
    final instructionObject = <String, dynamic>{
      ...methodDetail,
      if (!methodDetail.containsKey('is_redirect'))
        'is_redirect': listItem['is_redirect'],
      if (!methodDetail.containsKey('deposit_api'))
        'deposit_api': listItem['deposit_api'],
    };

    Get.to(
      () => DepositInstructionScreen(
        object: instructionObject,
        amountString: amountController.text,
        receiveAmountString: _redirectUsdAmount(entered),
        selectedMT5AccountID:
            controller.selectedTransferAccount.value!['meta_account_number']
                as String,
        currency: selectedCurrency,
        fromBonus: Get.arguments != null && Get.arguments is Map && Get.arguments['from'] == 'bonus',
      ),
    );

    // Call deposit API
    // controller.submitDepositForTopUpDemo({
    //   "amount": amountController.text,
    //   "accountId": widget.deposit_slug,
    //   // add other required fields
    // });
  }

  void _showAccountDropdown() {
    final controller = Get.find<DepositController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Obx(() {
          final accounts = controller.transferAccounts;

          if (accounts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "No accounts available",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            itemCount: accounts.length,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final account = accounts[index];

              return InkWell(
                onTap: () {
                  controller.selectedTransferAccount.value = account;
                  transferToController.text =
                      "${account['meta_account_number']} - ${_fmtMt5(account['balance'], account['meta_account_number']?.toString())}";
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      // Group label (Standard / Wallet)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          account['master_group_id'] ?? "N/A",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // Account number
                      Expanded(
                        child: Text(
                          account['meta_account_number'] ?? "-",
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      // Balance
                      Text(
                        _fmtMt5(account['balance'], account['meta_account_number']?.toString()),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
      },
    );
  }
}

/// Formatter that keeps digits and a single decimal point.
class _SingleDecimalTextFormatter extends TextInputFormatter {
  const _SingleDecimalTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sanitized = _sanitize(newValue.text);
    return TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  }

  String _sanitize(String value) {
    String clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (clean.contains('.')) {
      final parts = clean.split('.');
      clean =
          parts[0] + (parts.length > 1 ? '.${parts.sublist(1).join('')}' : '');
    }
    return clean;
  }
}
