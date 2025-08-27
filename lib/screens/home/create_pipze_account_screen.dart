import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/create_trading_account_controller.dart';
import 'package:pipze/widgets/congratulations_dialog.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pipze/widgets/currency_text_field.dart';

class CreatePipzeAccountScreen extends StatefulWidget {
  final String accountType;

  const CreatePipzeAccountScreen({Key? key, required this.accountType})
    : super(key: key);

  @override
  State<CreatePipzeAccountScreen> createState() =>
      _CreatePipzeAccountScreenState();
}

class _CreatePipzeAccountScreenState extends State<CreatePipzeAccountScreen> {
  late final CreateTradingAccountController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CreateTradingAccountController());
    // Set account type based on what was passed from previous screen
    controller.setAccountType(widget.accountType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
        ),
        title: Text(
          'Create new ${widget.accountType} Account',
          style: AppTextStyles.heading,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: RTLHelper.getRTLPadding(left: 24.w, right: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 32.h),

              // Leverage Field
              _buildDropdownField(
                label: 'Leverage',
                value: '1:500',
                options: [
                  '1:100',
                  '1:200',
                  '1:300',
                  '1:400',
                  '1:500',
                  '1:600',
                  '1:700',
                  '1:800',
                  '1:900',
                  '1:1000',
                ],
                onChanged: (value) {
                  // Handle leverage selection
                },
              ),

              SizedBox(height: 10.h),

              // Currency Field
              // _buildDropdownField(
              //   label: 'Currency',
              //   value: 'USD',
              //   options: [
              //     'USD',
              //     'EUR',
              //     'GBP',
              //     'JPY',
              //     'AUD',
              //     'CAD',
              //     'CHF',
              //     'NZD',
              //   ],
              //   onChanged: (value) {
              //     // Handle currency selection
              //   },
              // ),
              SizedBox(height: 10.h),
              Obx(
                () => _buildPasswordField(
                  label: 'Currency',
                  controller: controller.currencyController,
                  showPassword: true,
                  onTogglePassword: null,
                ),
              ),

              SizedBox(height: 10.h),
              // MT5 Password Field
              Obx(
                () => _buildPasswordField(
                  label: 'Create MT5 Password',
                  controller: controller.tradingPasswordController,
                  showPassword: controller.showTradingPassword.value,
                  onTogglePassword: controller.toggleTradingPasswordVisibility,
                ),
              ),
              SizedBox(height: 10.h),

              // MT5 Password Field

              // Investor Password Field
              Obx(
                () => _buildPasswordField(
                  label: 'Investor Password',
                  controller: controller.investorPasswordController,
                  showPassword: controller.showInvestorPassword.value,
                  onTogglePassword: controller.toggleInvestorPasswordVisibility,
                ),
              ),

              // Create Account Button
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10,
          left: 24.w,
          right: 24.w,
        ),
        child: _buildCreateAccountButton(),
      ),
    );
  }

  Widget _buildDepositAmountField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: CurrencyTextField(
        controller: controller.depositAmountController,
        currencySymbol: "\$",
        decoration: InputDecoration(
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        controller: TextEditingController(text: value),
        readOnly: true,
        onTap:
            () =>
                _showDropdownPicker(context, label, value, options, onChanged),
        suffixIcon: InkWell(
          onTap:
              () => _showDropdownPicker(
                context,
                label,
                value,
                options,
                onChanged,
              ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: RTLHelper.rtlIcon(
              Icons.keyboard_arrow_down_outlined,
              color: Colors.grey,
            ),
          ),
        ),
        decoration: InputDecoration(
          labelText: label,
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool showPassword,
    VoidCallback? onTogglePassword,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        controller: controller,
        obscureText: !showPassword,
        suffixIcon:
            onTogglePassword != null
                ? InkWell(
                  onTap: onTogglePassword,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                )
                : null,
        decoration: InputDecoration(
          labelText: label,
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
        onChanged: (value) {
          if (controller == this.controller.tradingPasswordController) {
            this.controller.updateTradingPassword(value);
          } else {
            this.controller.updateInvestorPassword(value);
          }
        },
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 46.h,
        child: ElevatedButton(
          onPressed:
              controller.isLoading.value ? null : controller.createAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                controller.isLoading.value ? Colors.grey : AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.zero,
            elevation: 0,
          ),
          child:
              controller.isLoading.value
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                    'Create Account',
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

  void _showDropdownPicker(
    BuildContext context,
    String label,
    String currentValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Select $label',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  height: 300.h,
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option == currentValue;

                      return InkWell(
                        onTap: () {
                          onChanged(option);
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
                                  option,
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
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
