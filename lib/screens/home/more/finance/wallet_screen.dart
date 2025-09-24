import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/utils/trl_helper.dart';

import '../../../../controllers/wallet_controller.dart';
import '../../../../controllers/wallet_controller.dart' show UserMT5Account;
import '../../../../services/language_service.dart';
import '../../../../widgets/currency_text_field.dart';
import '../../../../widgets/common_loading_widget.dart';
import 'internal_transfer_screen.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletController controller = Get.put(WalletController());

  @override
  void initState() {
    super.initState();
    controller.fetchWalletData();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
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
            onPressed: () => Get.back(),
          ),
        ),

        title: Text(languageService.tr('wallet'), style: AppTextStyles.screenTitle),
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
                        // Transfer Section
                        _buildTransferSection(),
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
                    ? OverlayLoadingWidget(
                      message: 'Processing...',
                      size: 60.0,
                      color: AppColors.primary,
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
                'Wallet ID',
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
                'Balance',
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
                child: Text("No accounts available"),
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

  Widget _buildTransferSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transfer From Field
        _buildTransferFromField(),

        SizedBox(height: 18.h),
        // Transfer To Field
        _buildTransferToField(),

        SizedBox(height: 18.h),

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
              child: RTLHelper.rtlIcon(Icons.arrow_drop_down, color: Colors.grey),
            ),
          ),
          decoration: InputDecoration(
            labelText: 'Transfer From',
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
        controller: TextEditingController(text: "Wallet"),
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Transfer to',
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
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: CurrencyTextField(
        controller: controller.amountController,
        currencySymbol: "\$",
        decoration: InputDecoration(
          labelText: 'Amount',
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
          height: 46.h,
          child: Obx(
            () => OutlinedButton(
              onPressed:
                  controller.isLoading.value ? null : controller.depositWallet,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  controller.isLoading.value
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                      : Text(
                        'Deposit Wallet',
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
        Container(
          width: double.infinity,
          height: 46.h,
          child: ElevatedButton(
            onPressed: _onInternalTransfer,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Internal Transfer',
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

  void _onInternalTransfer() {
    Get.to(() => InternalTransferScreen());
  }
}

class ExampleNavigationScreen extends StatelessWidget {
  const ExampleNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Get.to(() => WalletScreen()),
          child: Text('Open Wallet'),
        ),
      ),
    );
  }
}
