import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/finance/deposit_controller.dart';
import 'package:pipze/screens/home/more/finance/deposit_instruction_screen.dart';
import 'package:pipze/utils/trl_helper.dart';
import '../../../../routes/app_pages.dart';
import '../../../../services/api_service.dart';
import '../../../../services/language_service.dart';
import '../../../../widgets/custom_toast.dart';

class DepositRealScreen extends StatefulWidget {
  final Map<String, dynamic> object;

  const DepositRealScreen({
    super.key,
    required this.object,
  });

  @override
  State<DepositRealScreen> createState() => _DepositRealScreenState();
}

class _DepositRealScreenState extends State<DepositRealScreen> {
  final DepositController controller = Get.put(DepositController());
  final ApiService apiService = Get.put(ApiService());

  String selectedPaymentMode = 'UPI';
  String selectedAccount = '5013314';
  String selectedCurrency = 'USD';
  final TextEditingController amountController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController transferToController = TextEditingController(
    text: '',
  );
  final TextEditingController paymentModeController = TextEditingController(
    text: '',
  );
  final double fee = 20.00; // Fee in INR

  final List<String> accounts = ['5013314', '5013315', '5013316'];
  final List<String> currencies = ['USD', 'EUR', 'GBP'];

  late final LanguageService languageService;

  @override
  void initState() {
    super.initState();
    languageService = Get.find<LanguageService>();
    paymentModeController.text = widget.object['display_name']; // adjust field name per API
    selectedPaymentMode = widget.object['display_name'];

    controller.fetchAccountsForPaymentMethod(widget.object['deposit_slug']);

    ever(controller.selectedTransferAccount, (account) {
      if (account != null) {
        transferToController.text =
            "${account['meta_account_number']}   ${account['account_type'] ?? ''}   ${account['balance'] ?? '0.00'} USD";
        selectedAccount = account['meta_account_number'].toString();
      }
    });

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
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: true,
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

                SizedBox(height: 10.h),

                // To be deposited Section
                _buildToBeDepositedSection(),

                // Continue Button

                // Flexible space to push like button down
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                _buildContinueButton(),

                // Dynamic bottom padding based on keyboard visibility
              ],
            ),
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
      onTap: null,    // disable dropdown tap
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
            '${amountController.text.isEmpty ? "0.00" : amountController.text} $selectedCurrency',
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
          'Confirm',
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


  void _handleDeposit() async {
    // Show loading

    if (amountController.text.isEmpty || amountController.text == "0.00") {
      CustomToastService.showError(
        message: 'Please enter a valid amount',
      );
      return;
    }

      Get.toNamed(AppPages.DEPOSIT_INSTRUCTION_SCREEN,arguments: controller.depositMethod.value);


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
      backgroundColor: Colors.white,
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
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              final account = accounts[index];

              return InkWell(
                onTap: () {
                  controller.selectedTransferAccount.value = account;
                  transferToController.text =
                      "${account['meta_account_number']}  ${account['account_type'] ?? ''}  ${account['balance'] ?? '0.00'} USD";
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    children: [
                      // Group label (Standard / Wallet)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          account['master_group_id'] ?? "N/A",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple,
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
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // Balance
                      Text(
                        "\$ ${account['balance'] ?? '0.00'}",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
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
