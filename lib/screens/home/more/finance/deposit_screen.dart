import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/finance/deposit_controller.dart';
import 'package:pipze/utils/trl_helper.dart';
import '../../../../services/api_service.dart';
import '../../../../services/language_service.dart';
import '../../../../widgets/custom_toast.dart';

class DepositScreen extends StatefulWidget {
  final String accountNumber;

  const DepositScreen({
    super.key,
    required this.accountNumber,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final DepositController controller = Get.put(DepositController());
  final ApiService apiService = Get.put(ApiService());

  String selectedPaymentMode = 'UPI';
  String selectedAccount = '5013314';
  String selectedCurrency = 'USD';
  final TextEditingController amountController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController transferToController = TextEditingController(
    text: '5013314 MT5 0.00 USD',
  );
  final TextEditingController paymentModeController = TextEditingController(
    text: 'UPI',
  );
  final double fee = 20.00; // Fee in INR

  final List<String> paymentModes = ['UPI', 'Bank Transfer', 'Credit Card'];
  final List<String> accounts = ['5013314', '5013315', '5013316'];
  final List<String> currencies = ['USD', 'EUR', 'GBP'];

  late final LanguageService languageService;

  @override
  void initState() {
    super.initState();
    languageService = Get.find<LanguageService>();
  }

  @override
  void dispose() {
    amountController.dispose();
    transferToController.dispose();
    paymentModeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is visible
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 10.w),
          child: IconButton(
            icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
            onPressed: () => Get.back(),
          ),
        ),

        title: Text(
          languageService.tr('deposit'),
          style: AppTextStyles.screenTitle,
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300, // divider color
            width: 1, // divider thickness
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SizedBox(height: 24.h),
              // // Payment Mode Field
              // _buildPaymentModeField(),
              //
              // SizedBox(height: 24.h),
              //
              // // Transfer to Field
              // _buildTransferToField(),
              //
              SizedBox(height: 24.h),

              // Amount Field
              _buildAmountField(),

              // Fee Display
              // SizedBox(height: 16.h),
              // _buildFeeDisplay(),
              //
              // SizedBox(height: 10.h),
              //
              // // To be deposited Section
              // _buildToBeDepositedSection(),

              // Continue Button

              // Flexible space to push like button down
              SizedBox(height: MediaQuery.of(context).size.height * 0.6),
              _buildContinueButton(),

              // Dynamic bottom padding based on keyboard visibility
            ],
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
      readOnly: true,
      onTap: () => _showPaymentModeDropdown(),
      suffixIcon: InkWell(
        onTap: () => _showPaymentModeDropdown(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: RTLHelper.rtlIcon(Icons.arrow_drop_down, color: Colors.grey),
        ),
      ),
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
          child: RTLHelper.rtlIcon(Icons.arrow_drop_down, color: Colors.grey),
        ),
      ),
      decoration: InputDecoration(
        labelText: 'Transfer to',
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
    return RTLHelper.rtlTextField(
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
      controller: amountController,
      onChanged: (value) {
        setState(() {});
      },
      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.5.h),
      decoration: BoxDecoration(
        color: AppColors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To be deposited',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.icongrey,
            ),
          ),

          Text(
            '100.87 USD',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        onPressed: _handleDeposit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          languageService.tr('deposit_confirm_deposit'),
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.71,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLikeButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              // Handle like button tap - use a more controlled approach
              _showLikeFeedback();
            },
            icon: Icon(
              Icons.favorite_border,
              color: AppColors.primary,
              size: 24,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
        SizedBox(width: 16.w),
        Text(
          'Like this app?',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.icongrey,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  void _showLikeFeedback() {
    // Use a more controlled approach to avoid GlobalKey conflicts
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _handleDeposit() async {
    // Show loading

    if (amountController.text.isEmpty || amountController.text == "0.00") {
      CustomToastService.showError(
        message: 'Please enter a valid amount',
      );
      return;
    }

    // Call deposit API
    controller.submitDepositForTopUpDemo({
      "amount": amountController.text,
      "meta_account_number": widget.accountNumber,
      // add other required fields
    });

    // Simulate API call
    // await Future.delayed(const Duration(seconds: 2));

    // Hide loading

    // Show success message - use controlled approach
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(languageService.tr('deposit_deposit_successful')),
    //       backgroundColor: AppColors.primary,
    //       behavior: SnackBarBehavior.floating,
    //       duration: Duration(seconds: 3),
    //       margin: EdgeInsets.all(16),
    //     ),
    //   );
    // }
  }

  void _showPaymentModeDropdown() {
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
                  'Select Payment Mode',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  height: 200.h,
                  child: ListView.builder(
                    itemCount: paymentModes.length,
                    itemBuilder: (context, index) {
                      final mode = paymentModes[index];
                      final isSelected = mode == selectedPaymentMode;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedPaymentMode = mode;
                            paymentModeController.text = mode;
                          });
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
                                  mode,
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

  void _showAccountDropdown() {
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
                  'Select Account',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  height: 200.h,
                  child: ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final isSelected = account == selectedAccount;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedAccount = account;
                            transferToController.text = '$account MT5 0.00 USD';
                          });
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
                                  '$account MT5',
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
}
