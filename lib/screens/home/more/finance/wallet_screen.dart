import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/screens/home/more/finance/internal_transfer_screen.dart';
import 'package:pipze/screens/home/more/finance/payment_methods_screen.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/utils/navigation_helper.dart';

import '../../../../controllers/wallet_controller.dart';
import '../../../../services/language_service.dart';
import '../../../../widgets/common_loading_widget.dart';
import '../../../../widgets/custom_toast.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletController controller = Get.put(WalletController());
  final LanguageService languageService = Get.find<LanguageService>();

  @override
  void initState() {
    super.initState();
    controller.fetchWalletData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 10.w),
          child: IconButton(
            icon: SvgPicture.asset(
              "assets/svg/trade/arro_back.svg",
              height: 24.h,
              width: 24.w,
            ),
            onPressed: () => NavigationHelper.safeBack(context: context),
          ),
        ),

        title: Text(
          languageService.tr('wallet_title'),
          style: AppTextStyles.screenTitle,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SizedBox(height: 10.h),

                  // Wallet Information Section
                  _buildWalletInfoSection(),

                  SizedBox(height: 10.h),

                  // Divider
                  _buildDivider(),

                  SizedBox(height: 32.h),

                  Padding(
                    padding: RTLHelper.getRTLPadding(left: 24.w, right: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Transfer Section
                        // _buildTransferSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay - Center of Screen
          Obx(
            () =>
                controller.isLoading.value
                    ? CommonLoadingWidget(
                      message: languageService.tr('wallet_processing'),
                      size: 60.0,
                      color: AppColors.primary,
                      isFullScreen: true,
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10,
          left: 24.w,
          right: 24.w,
        ),
        child: _buildActionButtons(),
      ),
    );
  }

  Widget _buildWalletInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wallet ID
        _buildDivider(),
        SizedBox(height: 10.h),
        Padding(
          padding: RTLHelper.getRTLPadding(left: 24.w, right: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageService.tr('wallet_wallet_id'),
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.375,
                ),
              ),
              Obx(
                () => Text(
                  controller.wallet.value?.walletId ?? '',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.icongrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),
        _buildDivider(),
        SizedBox(height: 10.h),
        // Balance
        Padding(
          padding: RTLHelper.getRTLPadding(left: 24.w, right: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageService.tr('wallet_balance'),
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Obx(
                () => Text(
                  '\$${controller.balance.value}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.icongrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.grey[200]);
  }

  void _showAccountSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Obx(() {
          if (controller.mt5Accounts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(languageService.tr('common_no_accounts')),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: controller.mt5Accounts.length,
            itemBuilder: (context, index) {
              final account = controller.mt5Accounts[index];
              return ListTile(
                title: Text(
                  "${account.metaAccountName} (${account.metaAccountNumber})",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text("\$ ${account.balance}"),
                onTap: () {
                  controller.selectedFromAccount.value = account;
                  controller.transferFromAccount.value =
                      "${account.metaAccountName} (${account.metaAccountNumber})  \$ ${account.balance}";
                  Navigator.pop(context);
                },
              );
            },
          );
        });
      },
    );
  }

  void _showOTPBottomSheet() {
    final otpController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageService.tr('wallet_enter_otp'),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppColors.textPrimary),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                SizedBox(height: 16.h),

                // OTP Input Field
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: languageService.tr('wallet_enter_otp'),
                    hintText: '123456',
                    counterText: '',
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
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.error),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 40.h,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed:
                          controller.isTransferLoading.value
                              ? null
                              : () async {
                                if (otpController.text.isEmpty) {
                                  CustomToastService.show(
                                    message: languageService.tr(
                                      'wallet_validation_otp',
                                    ),
                                    type: ToastType.error,
                                  );
                                  return;
                                }

                                // Get account identifiers for transfer
                                final fromAccountId =
                                    controller
                                        .selectedFromAccount
                                        .value
                                        ?.metaAccountNumber ??
                                    '';
                                final toAccountId =
                                    controller.wallet.value?.walletId ?? '';

                                // Parse amount
                                final rawAmountText =
                                    controller.amountController.text.trim();
                                final cleanedAmount = rawAmountText.replaceAll(
                                  RegExp(r'[^0-9.]'),
                                  '',
                                );

                                // Submit transfer with all required parameters
                                final success = await controller
                                    .submitInternalTransfer(
                                      otpController.text,
                                      '', // comment - empty for wallet screen
                                      fromAccountId,
                                      toAccountId,
                                      cleanedAmount,
                                    );

                                if (success) {
                                  Navigator.pop(context);
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child:
                          controller.isTransferLoading.value
                              ? ButtonLoadingWidget(
                                size: 20.0,
                                color: Colors.white,
                              )
                              : Text(
                                languageService.tr('wallet_submit_transfer'),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ),

                SizedBox(height: kBottomNavigationBarHeight),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransferSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transfer From Field
        _buildTransferFromField(),

        SizedBox(height: 18.h),
        // Transfer To Field
        _buildTransferToField(),

        SizedBox(height: 10.h),

        // Amount Field
        _buildAmountField(),
      ],
    );
  }

  Widget _buildTransferFromField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Obx(() {
        return RTLHelper.rtlTextField(
          controller: TextEditingController(
            text: controller.transferFromAccount.value,
          ),
          readOnly: true,
          onTap: _showAccountSelectionSheet,
          suffixIcon: InkWell(
            onTap: _showAccountSelectionSheet,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: RTLHelper.rtlIcon(
                Icons.arrow_drop_down,
                color: Colors.grey,
              ),
            ),
          ),
          decoration: InputDecoration(
            labelText: languageService.tr('wallet_transfer_from'),
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
      }),
    );
  }

  Widget _buildTransferToField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextField(
        controller: TextEditingController(
          text: languageService.tr('wallet_title'),
        ),
        readOnly: true,
        decoration: InputDecoration(
          labelText: languageService.tr('wallet_transfer_to'),
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
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Text(
            "\$",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
            // Icons.done_all_sharp,
            // color: AppColors.primary,
          ),
        ),
        controller: controller.amountController,
        // currencySymbol: "\$",
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: languageService.tr('wallet_amount_label'),
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

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Deposit Wallet Button
        Container(
          width: double.infinity,
          height: 40.h,
          child: Obx(
            () => OutlinedButton(
              onPressed: () {
                Get.to(() => PaymentMethodsScreen(accountNumber: ''));
              },

              // controller.isOtpLoading.value ? null : _onInternalTransfer,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  controller.isOtpLoading.value
                      ? ButtonLoadingWidget(
                        size: 20.0,
                        color: AppColors.primary,
                      )
                      : Text(
                        languageService.tr('wallet_deposit_wallet'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Internal Transfer Button
        Obx(
          () => ElevatedButton(
            onPressed: () {
              Get.to(() => InternalTransferScreen());
            },
            // controller.isLoading.value ? null : _onInternalTransfer,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child:
                controller.isLoading.value
                    ? ButtonLoadingWidget(size: 20.0, color: Colors.white)
                    : Text(
                      languageService.tr('internal_transfer'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  void _onInternalTransfer() async {
    // Validate required fields
    if (controller.selectedFromAccount.value == null) {
      CustomToastService.show(
        message: languageService.tr('wallet_validation_account'),
        type: ToastType.error,
      );
      return;
    }

    final rawText = controller.amountController.text.trim();
    if (rawText.isEmpty) {
      CustomToastService.show(
        message: languageService.tr('wallet_validation_amount'),
        type: ToastType.error,
      );
      return;
    }

    // Clean currency symbols and commas
    final cleanedText = rawText.replaceAll(RegExp(r'[^0-9.]'), '');
    final parsedAmount = double.tryParse(cleanedText);
    if (parsedAmount == null || parsedAmount <= 0.0) {
      CustomToastService.show(
        message: languageService.tr('wallet_validation_amount_positive'),
        type: ToastType.error,
      );
      return;
    }

    // Get account identifier for balance check
    final accountNumber =
        controller.selectedFromAccount.value?.metaAccountNumber ?? '';
    if (accountNumber.isEmpty) {
      CustomToastService.show(
        message: languageService.tr('wallet_validation_account_invalid'),
        type: ToastType.error,
      );
      return;
    }

    // Check balance via API
    final isValid = await controller.checkBalance(accountNumber, parsedAmount);
    if (!isValid) {
      // Error already shown in checkBalance method
      return;
    }

    // Send OTP with account number
    await controller.sendOTP(accountNumber);

    // If OTP was sent successfully, show OTP bottom sheet
    if (controller.isOtpSent.value) {
      _showOTPBottomSheet();
    }
  }
}

class ExampleNavigationScreen extends StatelessWidget {
  const ExampleNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Get.to(() => WalletScreen()),
          child: Text(languageService.tr('wallet_open_wallet')),
        ),
      ),
    );
  }
}
