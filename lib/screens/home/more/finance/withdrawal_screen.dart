import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/utils/navigation_helper.dart';
import 'package:pipze/widgets/currency_text_field.dart';
import 'package:pipze/services/language_service.dart';
import '../../../../controllers/finance/withdrawal_controller.dart';
import '../../../../widgets/common_loading_widget.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final WithdrawalController controller = Get.put(WithdrawalController());
  final TextEditingController amountController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final LanguageService languageService = Get.find<LanguageService>();
  bool isAmountConfirmed = true; // Checkbox state

  // Validation state
  final RxString _validationMessage = ''.obs;
  final RxBool _showValidationError = false.obs;

  @override
  void dispose() {
    amountController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 10.w),
          child: IconButton(
            icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
            onPressed: () => NavigationHelper.safeBack(context: context),
          ),
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300, // divider color
            width: 1, // divider thickness
          ),
        ),

        title: Text(
          languageService.tr('withdrawal'),
          style: AppTextStyles.screenTitle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          // Show loading indicator while fetching data OR until we've received initial response
          if (controller.isLoading ||
              !controller.hasReceivedInitialResponse.value) {
            return Center(
              child: CommonLoadingWidget(
                message: languageService.tr('withdrawal_loading_details'),
                size: 50.0,
                color: AppColors.primary,
              ),
            );
          }

          // Show no data view when API returns status: false with message
          final showNoData = controller.showNoDataView.value;
          print("WithdrawalScreen: showNoDataView = $showNoData");

          if (showNoData) {
            return _buildNoDataView();
          }

          // Show normal form view
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32.h),

                // Withdrawal Method Field
                _buildWithdrawalMethodField(),

                SizedBox(height: 24.h),

                // Withdraw From Field
                _buildWithdrawFromField(),

                Obx(() {
                  if (controller.selectedPaymentMethod.value.toLowerCase() ==
                      'bank') {
                    return Column(
                      children: [SizedBox(height: 32.h), _buildBankFromField()],
                    );
                  } else if (controller.selectedPaymentMethod.value
                          .toLowerCase() ==
                      'crypto') {
                    return Column(
                      children: [
                        SizedBox(height: 32.h),
                        _buildCryptoFromField(),
                      ],
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                }),

                SizedBox(height: 24.h),

                // Amount Field
                _buildAmountField(),

                // OTP Field (shown only when OTP is sent)
                Obx(() {
                  if (controller.isOtpSent.value) {
                    return Column(
                      children: [SizedBox(height: 24.h), _buildOtpField()],
                    );
                  }
                  return SizedBox.shrink();
                }),

                Obx(() {
                  if (controller.isOtpSent.value) {
                    return SizedBox.shrink();
                  }
                  return SizedBox(height: 16.h);
                }),

                // Confirmation Checkbox
                _buildConfirmationCheckbox(),

                // Validation message
                _buildValidationMessage(),

                SizedBox(
                  height:
                      controller.isOtpSent.value
                          ? MediaQuery.of(context).size.height * 0.15
                          : MediaQuery.of(context).size.height * 0.3,
                ),

                // Send OTP Button
                _buildSendOtpButton(),

                SizedBox(height: 32.h),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWithdrawalMethodField() {
    return Obx(
      () => RTLHelper.rtlTextField(
        controller: TextEditingController(
          text:
              controller.selectedWithdrawalMethod.value != null
                  ? '${controller.selectedWithdrawalMethod.value!.methodName ?? ''}'
                  : controller.selectedPaymentMethod.value ?? '',
        ),
        readOnly: true,
        onTap: () => _showWithdrawalMethodDropdown(),
        suffixIcon: InkWell(
          onTap: () => _showWithdrawalMethodDropdown(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: RTLHelper.rtlIcon(
              Icons.keyboard_arrow_down_outlined,
              color: Colors.grey,
            ),
          ),
        ),
        decoration: InputDecoration(
          labelText: 'Withdrawal Method',
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
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
      ),
    );
  }

  Widget _buildWithdrawFromField() {
    return Obx(() {
      // Get display text with account number and balance
      final displayText = _getAccountDisplayText();

      return RTLHelper.rtlTextField(
        controller: TextEditingController(text: displayText),
        readOnly: true,
        onTap: () => _showAccountDropdown(),
        suffixIcon: InkWell(
          onTap: () => _showAccountDropdown(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: RTLHelper.rtlIcon(
              Icons.keyboard_arrow_down_outlined,
              color: Colors.grey,
            ),
          ),
        ),
        decoration: InputDecoration(
          labelText: 'Withdraw From',
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
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
    });
  }

  // Helper method to format account display text with balance
  String _getAccountDisplayText() {
    final selectedAccountId = controller.selectedAccount.value;

    if (selectedAccountId == null || selectedAccountId.isEmpty) {
      return '';
    }

    // Check if it's a wallet
    final wallet = controller.wallet.value;
    if (wallet != null && wallet.walletId == selectedAccountId) {
      return '${wallet.walletId ?? ''} - \$ ${wallet.walletBalance ?? '0.00'}';
    }

    // Check if it's an MT5 account
    final accounts = controller.userMT5Accounts;
    try {
      final selectedAccount = accounts.firstWhere(
        (account) => account.metaAccountNumber == selectedAccountId,
      );
      return '${selectedAccount.metaAccountNumber ?? ''} - \$ ${selectedAccount.balance ?? '0.00'}';
    } catch (e) {
      // Account not found, return just the ID
      return selectedAccountId;
    }
  }

  Widget _buildBankFromField() {
    return Obx(
      () => RTLHelper.rtlTextField(
        controller: TextEditingController(
          text: controller.selectedBankAccount.value ?? '',
        ),
        readOnly: true,
        onTap: () => _showBankDropDown(),
        suffixIcon: InkWell(
          onTap: () => _showBankDropDown(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: RTLHelper.rtlIcon(
              Icons.keyboard_arrow_down_outlined,
              color: Colors.grey,
            ),
          ),
        ),
        decoration: InputDecoration(
          labelText: 'Bank Account',
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
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
      ),
    );
  }

  Widget _buildCryptoFromField() {
    return Obx(
      () => RTLHelper.rtlTextField(
        controller: TextEditingController(
          text: controller.selectedCryptoAccount.value ?? '',
        ),
        readOnly: true,
        onTap: () => _showBankDropDown(),
        suffixIcon: InkWell(
          onTap: () => _showBankDropDown(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: RTLHelper.rtlIcon(
              Icons.keyboard_arrow_down_outlined,
              color: Colors.grey,
            ),
          ),
        ),
        decoration: InputDecoration(
          labelText: 'Crypto Type',
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
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
      ),
    );
  }

  Widget _buildAmountField() {
    return CurrencyTextField(
      controller: amountController,
      currencySymbol: "\$",
      decoration: InputDecoration(
        labelText: 'Amount',
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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

  Widget _buildConfirmationCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isAmountConfirmed = !isAmountConfirmed;
            });
          },
          child: Container(
            width: 20.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: isAmountConfirmed ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color:
                    isAmountConfirmed ? AppColors.primary : Colors.grey[400]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child:
                isAmountConfirmed
                    ? Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'I confirm the amount is correct. ',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: 'Term & Condition.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpField() {
    return Column(
      children: [
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: InputDecoration(
            labelText: 'Enter OTP',
            hintText: 'Enter 4-digit OTP',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 10.h,
            ),
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
            counterText: '', // Hide character counter
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.email_outlined, color: AppColors.primary, size: 20.w),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  // 'OTP has been sent to your registered email address. Please check your inbox and enter the code below.',
                  languageService.tr('withdrawal_otp_sent'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Validation method
  bool _validateForm() {
    _showValidationError.value = false;
    _validationMessage.value = '';

    // Check withdrawal method
    if (controller.selectedWithdrawalMethod.value == null ||
        controller.selectedPaymentMethod.value.isEmpty) {
      _validationMessage.value = 'Please select a withdrawal method';
      _showValidationError.value = true;
      return false;
    }

    // Check withdraw from account
    if (controller.selectedAccount.value == null ||
        controller.selectedAccount.value!.isEmpty) {
      _validationMessage.value = 'Please select an account to withdraw from';
      _showValidationError.value = true;
      return false;
    }

    // Check bank account (if bank method selected)
    if (controller.selectedPaymentMethod.value.toLowerCase() == 'bank') {
      if (controller.selectedBankAccount.value == null ||
          controller.selectedBankAccount.value!.isEmpty) {
        _validationMessage.value = 'Please select a bank account';
        _showValidationError.value = true;
        return false;
      }
    }

    // Check crypto account (if crypto method selected)
    if (controller.selectedPaymentMethod.value.toLowerCase() == 'crypto') {
      if (controller.selectedCryptoAccount.value == null ||
          controller.selectedCryptoAccount.value!.isEmpty) {
        _validationMessage.value = 'Please select a crypto account';
        _showValidationError.value = true;
        return false;
      }
    }

    // Check amount
    String amountText = amountController.text.trim();
    if (amountText.isEmpty || amountText == '\$' || amountText == '\$ ') {
      _validationMessage.value = 'Please enter withdrawal amount';
      _showValidationError.value = true;
      return false;
    }

    // Remove $ symbol and space, then check if amount is valid
    String cleanAmount =
        amountText.replaceFirst('\$', '').replaceFirst(' ', '').trim();
    if (cleanAmount.isEmpty) {
      _validationMessage.value = 'Please enter a valid amount';
      _showValidationError.value = true;
      return false;
    }

    // Check if amount is greater than 0
    double? amount = double.tryParse(cleanAmount);
    if (amount == null || amount <= 0) {
      _validationMessage.value = 'Amount must be greater than 0';
      _showValidationError.value = true;
      return false;
    }

    // Check OTP if OTP is sent
    if (controller.isOtpSent.value) {
      if (otpController.text.trim().isEmpty) {
        _validationMessage.value = 'Please enter OTP';
        _showValidationError.value = true;
        return false;
      }
      if (otpController.text.trim().length != 4) {
        _validationMessage.value = 'OTP must be 4 digits';
        _showValidationError.value = true;
        return false;
      }
    }

    return true;
  }

  // Show validation message
  Widget _buildValidationMessage() {
    return Obx(() {
      if (!_showValidationError.value || _validationMessage.value.isEmpty) {
        return SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 20.w),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _validationMessage.value,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSendOtpButton() {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 40.h,
        child: ElevatedButton(
          onPressed:
              isAmountConfirmed
                  ? () {
                    // Validate form before proceeding
                    if (!_validateForm()) {
                      return;
                    }

                    if (controller.isOtpSent.value) {
                      // Submit withdrawal with OTP
                      controller.submitWithdrawalWithOtp(otpController.text);
                    } else {
                      // Send OTP
                      controller.withdrawalAmount.value = amountController.text;
                      controller.submitWithdrawal();
                    }
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child:
              controller.isOtpLoading.value
                  ? ButtonLoadingWidget(size: 20.0, color: Colors.white)
                  : Text(
                    controller.isOtpSent.value
                        ? 'Submit Withdrawal'
                        : 'Send OTP',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }

  void _showWithdrawalMethodDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Select Withdrawal Method',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  height: 200.h,
                  child: Obx(
                    () => ListView.builder(
                      itemCount: controller.withdrawalMethods.length,
                      itemBuilder: (context, index) {
                        final method = controller.withdrawalMethods[index];
                        final isSelected =
                            method == controller.selectedPaymentMethod.value;
                        return InkWell(
                          onTap: () {
                            controller.selectedPaymentMethod.value =
                                method.methodName!;
                            controller.selectedWithdrawalMethod.value =
                                method; // Set the complete withdrawal method object
                            controller.fetchWithdrawalMethodDetails(
                              method.methodSlug ?? '',
                            );
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 16.h,
                              horizontal: 16.w,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    method.methodName!.camelCase ?? '',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showAccountDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Obx(() {
          final accounts = controller.userMT5Accounts;
          final wallet = controller.wallet.value;

          // Check if we have any accounts (MT5 or Wallet)
          final bool hasMT5Accounts = accounts.isNotEmpty;
          final bool hasWallet =
              wallet != null &&
              wallet.walletId != null &&
              wallet.walletId!.isNotEmpty &&
              wallet.walletStatus?.toLowerCase() == 'active';

          if (!hasMT5Accounts && !hasWallet) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  languageService.tr('common_no_accounts'),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }

          // Calculate total items (MT5 accounts + wallet if exists)
          final int totalItems = accounts.length + (hasWallet ? 1 : 0);

          return ListView.separated(
            shrinkWrap: true,
            itemCount: totalItems,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              // Check if this is the wallet item (last item if wallet exists)
              final bool isWalletItem = hasWallet && index == accounts.length;

              if (isWalletItem && wallet != null) {
                // Render Wallet item
                final isSelected =
                    wallet.walletId == controller.selectedAccount.value;

                return InkWell(
                  onTap: () {
                    controller.selectedAccount.value = wallet.walletId ?? '';
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : null,
                    ),
                    child: Row(
                      children: [
                        // Wallet badge (orange color to distinguish from MT5)
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
                            'Wallet',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Wallet ID
                        Expanded(
                          child: Text(
                            wallet.walletId ?? "-",
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.black87,
                            ),
                          ),
                        ),
                        // Wallet Balance
                        Text(
                          "\$ ${wallet.walletBalance ?? '0.00'}",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade700,
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: 8.w),
                          Icon(Icons.check, color: AppColors.primary, size: 20),
                        ],
                      ],
                    ),
                  ),
                );
              } else {
                // Render MT5 Account item
                final account = accounts[index];
                final isSelected =
                    account.metaAccountNumber ==
                    controller.selectedAccount.value;

                return InkWell(
                  onTap: () {
                    controller.selectedAccount.value =
                        account.metaAccountNumber ?? '';
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : null,
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
                            account.masterGroupId ?? "N/A",
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
                            account.metaAccountNumber ?? "-",
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.black87,
                            ),
                          ),
                        ),

                        // Balance
                        Text(
                          "\$ ${account.balance ?? '0.00'}",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade700,
                          ),
                        ),

                        if (isSelected) ...[
                          SizedBox(width: 8.w),
                          Icon(Icons.check, color: AppColors.primary, size: 20),
                        ],
                      ],
                    ),
                  ),
                );
              }
            },
          );
        });
      },
    );
  }

  void _showBankDropDown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 53, 38, 38),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 200.h,
                  child: Obx(() {
                    if (controller.userMT5Accounts.isEmpty) {
                      return Center(
                        child: Text(
                          languageService.tr('withdrawal_no_accounts_found'),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: controller.userMT5Accounts.length,
                      itemBuilder: (context, index) {
                        final account = controller.userMT5Accounts[index];
                        final isSelected =
                            account.metaAccountNumber ==
                            controller.selectedAccount.value;

                        return InkWell(
                          onTap: () {
                            controller.selectedBankAccount.value =
                                account.metaAccountNumber ?? '';
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 16.h,
                              horizontal: 16.w,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        WidgetSpan(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              account.masterGroupId ?? '',
                                              style: AppTextStyles.label,
                                            ),
                                          ),
                                        ),

                                        TextSpan(
                                          text:
                                              ' ${account.metaAccountNumber} ',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$ ${account.balance ?? "0"} ',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64.w,
              color: AppColors.primary.withOpacity(0.6),
            ),
            SizedBox(height: 24.h),
            Text(
              controller.noDataMessage.value.isNotEmpty
                  ? controller.noDataMessage.value
                  : 'No data available',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'Please complete the required verification or contact support for assistance.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.icongrey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCryptoDropDown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 200.h,
                  child: Obx(() {
                    return ListView.builder(
                      itemCount: controller.userMT5Accounts.length,
                      itemBuilder: (context, index) {
                        final account = controller.userMT5Accounts[index];
                        final isSelected =
                            account.metaAccountNumber ==
                            controller.selectedCryptoAccount.value;

                        return InkWell(
                          onTap: () {
                            controller.selectedCryptoAccount.value =
                                account.metaAccountNumber ?? '';
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 16.h,
                              horizontal: 16.w,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        WidgetSpan(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              account.masterGroupId ?? '',
                                              style: AppTextStyles.label,
                                            ),
                                          ),
                                        ),

                                        TextSpan(
                                          text:
                                              ' ${account.metaAccountNumber} ',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$ ${account.balance ?? "0"} ',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
    );
  }
}
