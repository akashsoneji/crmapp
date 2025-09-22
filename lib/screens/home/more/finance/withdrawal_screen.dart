import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/widgets/currency_text_field.dart';
import '../../../../controllers/finance/withdrawal_controller.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final WithdrawalController controller = Get.put(WithdrawalController());
  final TextEditingController amountController = TextEditingController();
  bool isAmountConfirmed = true; // Checkbox state

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 10.w),
          child: IconButton(
            icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
            onPressed: () => Get.back(),
          ),
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300, // divider color
            width: 1, // divider thickness
          ),
        ),

        title: Text('Withdrawal', style: AppTextStyles.screenTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
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
                if (controller.selectedPaymentMethod.value.toLowerCase() == 'bank') {
                  return Column(
                    children: [
                      SizedBox(height: 32.h),
                      _buildBankFromField(),
                    ],
                  );
                } else if (controller.selectedPaymentMethod.value.toLowerCase() == 'crypto') {
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

              SizedBox(height: 32.h),

              // Confirmation Checkbox
              _buildConfirmationCheckbox(),

              Spacer(),

              // Send OTP Button
              _buildSendOtpButton(),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawalMethodField() {
    return Obx(() => RTLHelper.rtlTextField(
      controller: TextEditingController(text: controller.selectedPaymentMethod.value ?? ''),
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
    ));
  }

  Widget _buildWithdrawFromField() {
    return Obx(() => RTLHelper.rtlTextField(
      controller: TextEditingController(
        text: controller.selectedAccount.value ?? '',
      ),
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
    ));
  }

  Widget _buildBankFromField() {
    return Obx(() => RTLHelper.rtlTextField(
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
    ));
  }


  Widget _buildCryptoFromField() {
    return Obx(() => RTLHelper.rtlTextField(
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
    ));
  }

  Widget _buildAmountField() {
    return CurrencyTextField(
      controller: amountController,
      currencySymbol: "\$",
      decoration: InputDecoration(
        labelText: 'Amount',
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

  Widget _buildSendOtpButton() {
    return Container(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        onPressed: isAmountConfirmed
            ? () {
                controller.withdrawalAmount.value = amountController.text;
                controller.submitWithdrawal();
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
        child: Text(
          'Send OTP',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
      builder: (context) => Container(
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
              child: Obx(() => ListView.builder(
                itemCount: controller.withdrawalMethods.length,
                itemBuilder: (context, index) {
                  final method = controller.withdrawalMethods[index];
                  final isSelected = method == controller.selectedPaymentMethod.value;
                  return InkWell(
                    onTap: () {
                      controller.selectedPaymentMethod.value = method.methodName!;
                      controller.fetchWithdrawalMethodDetails(method.methodSlug ?? '');
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 16.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
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
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
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
              )),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
                        account.metaAccountNumber == controller.selectedAccount.value;

                    return InkWell(
                      onTap: () {
                        controller.selectedAccount.value = account.metaAccountNumber ?? '';
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
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
                                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          account.masterGroupId ?? '',
                                          style: AppTextStyles.label,
                                        ),
                                      ),
                                    ),

                                    TextSpan(
                                      text: ' ${account.metaAccountNumber} ',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check, color: AppColors.primary, size: 20),
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

  void _showBankDropDown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
                        account.metaAccountNumber == controller.selectedAccount.value;

                    return InkWell(
                      onTap: () {
                        controller.selectedBankAccount.value = account.metaAccountNumber ?? '';
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
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
                                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          account.masterGroupId ?? '',
                                          style: AppTextStyles.label,
                                        ),
                                      ),
                                    ),

                                    TextSpan(
                                      text: ' ${account.metaAccountNumber} ',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check, color: AppColors.primary, size: 20),
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


  void _showCryptoDropDown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
                        account.metaAccountNumber == controller.selectedCryptoAccount.value;

                    return InkWell(
                      onTap: () {
                        controller.selectedCryptoAccount.value = account.metaAccountNumber ?? '';
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
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
                                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          account.masterGroupId ?? '',
                                          style: AppTextStyles.label,
                                        ),
                                      ),
                                    ),

                                    TextSpan(
                                      text: ' ${account.metaAccountNumber} ',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check, color: AppColors.primary, size: 20),
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
