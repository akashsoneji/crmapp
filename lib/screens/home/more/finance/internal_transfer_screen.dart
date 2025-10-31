import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/flavor_config.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/utils/navigation_helper.dart';
import 'package:pipze/controllers/wallet_controller.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/widgets/common_loading_widget.dart';

class InternalTransferScreen extends StatefulWidget {
  const InternalTransferScreen({Key? key}) : super(key: key);

  @override
  State<InternalTransferScreen> createState() => _InternalTransferScreenState();
}

class _InternalTransferScreenState extends State<InternalTransferScreen> {
  final WalletController controller = Get.put(WalletController());
  final TextEditingController _transferFromController = TextEditingController();
  final TextEditingController _transferToController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  bool _showOtpSection = false;
  String? _selectedTransferFrom;
  String? _selectedTransferFromType; // 'mt5', 'wallet', 'ib'
  String? _selectedTransferTo;
  String? _selectedTransferToType; // 'mt5', 'wallet', 'ib'
  dynamic _selectedTransferFromAccount; // UserMT5Account, Wallet, or null
  dynamic _selectedTransferToAccount; // UserMT5Account, Wallet, or null
  // Reactive submitting flag (GetX)
  final RxBool _isSubmitting = false.obs;

  @override
  void initState() {
    super.initState();
    // Fetch wallet data when screen loads
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Fetch wallet data which includes MT5 accounts
    await controller.fetchWalletData();

    // Set default values if available
    if (controller.mt5Accounts.isNotEmpty && _selectedTransferFrom == null) {
      final firstAccount = controller.mt5Accounts.first;
      setState(() {
        _selectedTransferFrom = firstAccount.metaAccountNumber;
        _selectedTransferFromType = 'mt5';
        _selectedTransferFromAccount = firstAccount;
        _transferFromController.text = _selectedTransferFrom!;
        controller.selectedFromAccount.value = firstAccount;
        controller.selectedFromAccountType.value = 'mt5';
      });
    }
    if (controller.wallet.value != null &&
        _selectedTransferTo == null &&
        _selectedTransferFromType != 'wallet') {
      setState(() {
        _selectedTransferTo = 'Wallet';
        _selectedTransferToType = 'wallet';
        _selectedTransferToAccount = controller.wallet.value;
        _transferToController.text = 'Wallet';
        controller.selectedToAccount.value = controller.wallet.value;
        controller.selectedToAccountType.value = 'wallet';
      });
    }
  }

  // Get account identifier for API request
  String _getAccountIdentifier(String? accountType, dynamic account) {
    if (accountType == 'wallet' && account is Wallet) {
      return account.walletId;
    } else if (accountType == 'mt5' && account is UserMT5Account) {
      return account.metaAccountNumber;
    } else if (accountType == 'ib' && account is UserMT5Account) {
      return account.metaAccountNumber;
    }
    return '';
  }

  @override
  void dispose() {
    _transferFromController.dispose();
    _transferToController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
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
        backgroundColor: AppColors.backgroundLight,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.grey, // divider color
            width: 1, // divider thickness
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
          onPressed: () => NavigationHelper.safeBack(context: context),
        ),
        title: Text('Internal Transfer', style: AppTextStyles.screenTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10.h),

                        // Transfer Form Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Transfer Fields
                              _buildTransferFields(),

                              SizedBox(height: 32.h),

                              // OTP Section (Conditionally Visible)
                              if (_showOtpSection) _buildOtpSection(),

                              SizedBox(height: 50.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Fixed bottom section with button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      // Action Button
                      _buildActionButton(),

                      // Dynamic bottom padding based on keyboard visibility
                      SizedBox(
                        height:
                            isKeyboardVisible
                                ? 20.h
                                : kBottomNavigationBarHeight - 20.h,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Center overlay loader while submitting (reactive)
            Obx(
              () =>
                  _isSubmitting.value
                      ? Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.15),
                          alignment: Alignment.center,
                          child: const OverlayLoadingWidget(),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferFields() {
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

        SizedBox(height: 18.h),

        // Comment Field
        _buildCommentField(),
      ],
    );
  }

  Widget _buildTransferFromField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
        controller: _transferFromController,
        readOnly: true,
        onTap: () => _showTransferFromDropdown(),
        suffixIcon: InkWell(
          onTap: () => _showTransferFromDropdown(),
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
      ),
    );
  }

  Widget _buildTransferToField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
        controller: _transferToController,
        readOnly: true,
        onTap: () => _showTransferToDropdown(),
        suffixIcon: InkWell(
          onTap: () => _showTransferToDropdown(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: RTLHelper.rtlIcon(Icons.arrow_drop_down, color: Colors.grey),
          ),
        ),
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
      child: RTLHelper.rtlTextField(
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
        controller: _amountController,
        onChanged: (value) {},
        keyboardType: TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
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

  Widget _buildCommentField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
        controller: _commentController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Comment',
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

  Widget _buildOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter OTP', style: AppTextStyles.heading),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            return Container(
              width: 60.w,
              height: 60.h,
              child: TextField(
                controller: _otpControllers[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                focusNode: _otpFocusNodes[index],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  _handleOtpInput(index, value);
                },
                onTap: () {
                  // When user taps on a box, select all text for easy replacement
                  if (_otpControllers[index].text.isNotEmpty) {
                    _otpControllers[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _otpControllers[index].text.length,
                    );
                  }
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 46.h,
      child: Obx(
        () => ElevatedButton(
          onPressed: _isSubmitting.value ? null : _onActionButtonPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child:
              _isSubmitting.value
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        _showOtpSection ? 'Submitting...' : 'Sending OTP...',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                  : Text(
                    _showOtpSection ? 'Submit OTP' : 'Transfer Now',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }

  void _showTransferFromDropdown() {
    // Build account options dynamically from API data
    final List<Map<String, String>> accountOptions = [];

    // Add MT5 accounts from API
    for (var account in controller.mt5Accounts) {
      accountOptions.add({
        'type': 'mt5',
        'display': 'MT5#${account.metaAccountNumber} - \$${account.balance}',
        'value': account.metaAccountNumber,
      });
    }

    // Add Wallet option
    if (controller.wallet.value != null) {
      accountOptions.add({
        'type': 'wallet',
        'display':
            'Wallet (${controller.wallet.value!.walletId}) - \$${controller.wallet.value!.walletBalance}',
        'value': 'Wallet',
      });
    }

    // Add App Account option (IB Account if available)
    if (controller.ibAccount.value != null &&
        controller.ibAccount.value!.status.isNotEmpty) {
      // IB account uses meta_account_number - find it from MT5 accounts
      final ibAccountNumber = controller.ibAccount.value?.referenceLinkId ?? '';
      if (ibAccountNumber.isNotEmpty) {
        final ibAccount = controller.mt5Accounts.firstWhere(
          (acc) => acc.metaAccountNumber == ibAccountNumber,
          orElse: () => controller.mt5Accounts.first,
        );
        accountOptions.add({
          'type': 'ib',
          'display':
              '${FlavorConfig.instance.appName} Account (${ibAccount.metaAccountNumber}) - \$${ibAccount.balance}',
          'value': ibAccount.metaAccountNumber,
        });
      }
    }

    if (accountOptions.isEmpty) {
      // Show loading or no data message
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
                  if (controller.isLoading.value)
                    CircularProgressIndicator()
                  else
                    Text(
                      'No accounts available',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                ],
              ),
            ),
      );
      return;
    }

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
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: accountOptions.length,
                    itemBuilder: (context, index) {
                      final option = accountOptions[index];
                      final displayText = option['display'] ?? '';
                      final value = option['value'] ?? '';
                      final isSelected = value == _selectedTransferFrom;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTransferFrom = value;
                            _transferFromController.text = displayText;
                            final accountType = option['type'] ?? '';

                            // Store selected account in controller for transfer
                            if (accountType == 'mt5') {
                              final account = controller.mt5Accounts.firstWhere(
                                (acc) => acc.metaAccountNumber == value,
                              );
                              _selectedTransferFromAccount = account;
                              _selectedTransferFromType = 'mt5';
                              controller.selectedFromAccount.value = account;
                              controller.selectedFromAccountType.value = 'mt5';
                            } else if (accountType == 'wallet') {
                              _selectedTransferFromAccount =
                                  controller.wallet.value;
                              _selectedTransferFromType = 'wallet';
                              controller.selectedFromAccount.value = null;
                              controller.selectedFromAccountType.value =
                                  'wallet';
                            } else if (accountType == 'ib') {
                              // IB account uses same structure as MT5
                              final account = controller.mt5Accounts.firstWhere(
                                (acc) => acc.metaAccountNumber == value,
                              );
                              _selectedTransferFromAccount = account;
                              _selectedTransferFromType = 'ib';
                              controller.selectedFromAccount.value = account;
                              controller.selectedFromAccountType.value = 'ib';
                            }

                            // Reset Transfer To if it was the same account
                            if (_selectedTransferTo == value) {
                              _selectedTransferTo = null;
                              _selectedTransferToType = null;
                              _selectedTransferToAccount = null;
                              _transferToController.clear();
                              controller.selectedToAccount.value = null;
                              controller.selectedToAccountType.value = null;
                            }
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayText,
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

  void _showTransferToDropdown() {
    // Build account options dynamically from API data, excluding selected From account
    final List<Map<String, String>> accountOptions = [];

    // Add MT5 accounts from API (exclude if selected as From)
    for (var account in controller.mt5Accounts) {
      final accountId = account.metaAccountNumber;
      if (_selectedTransferFrom != accountId) {
        accountOptions.add({
          'type': 'mt5',
          'display': 'MT5#$accountId - \$${account.balance}',
          'value': accountId,
          'accountId': accountId,
          'balance': account.balance,
        });
      }
    }

    // Add Wallet option (exclude if selected as From)
    if (controller.wallet.value != null &&
        _selectedTransferFromType != 'wallet') {
      accountOptions.add({
        'type': 'wallet',
        'display':
            'Wallet (${controller.wallet.value!.walletId}) - \$${controller.wallet.value!.walletBalance}',
        'value': controller.wallet.value!.walletId,
        'accountId': controller.wallet.value!.walletId,
        'balance': controller.wallet.value!.walletBalance,
      });
    }

    // Add IB Account option (exclude if selected as From and if exists)
    if (controller.ibAccount.value != null &&
        controller.ibAccount.value!.status.isNotEmpty &&
        _selectedTransferFromType != 'ib') {
      // IB account uses meta_account_number - find it from MT5 accounts
      final ibAccountNumber = controller.ibAccount.value?.referenceLinkId ?? '';
      if (ibAccountNumber.isNotEmpty) {
        final ibAccount = controller.mt5Accounts.firstWhere(
          (acc) => acc.metaAccountNumber == ibAccountNumber,
          orElse: () => controller.mt5Accounts.first,
        );
        accountOptions.add({
          'type': 'ib',
          'display':
              '${FlavorConfig.instance.appName} Account (${ibAccount.metaAccountNumber}) - \$${ibAccount.balance}',
          'value': ibAccount.metaAccountNumber,
          'accountId': ibAccount.metaAccountNumber,
          'balance': ibAccount.balance,
        });
      }
    }

    if (accountOptions.isEmpty) {
      // Show loading or no data message
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
                  if (controller.isLoading.value)
                    CircularProgressIndicator()
                  else
                    Text(
                      'No accounts available',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                ],
              ),
            ),
      );
      return;
    }

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
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: accountOptions.length,
                    itemBuilder: (context, index) {
                      final option = accountOptions[index];
                      final displayText = option['display'] ?? '';
                      final value = option['value'] ?? '';
                      final isSelected =
                          value == _selectedTransferTo ||
                          (option['type'] == 'wallet' &&
                              _selectedTransferTo == 'Wallet');

                      return InkWell(
                        onTap: () {
                          setState(() {
                            final accountType = option['type'] ?? '';
                            _selectedTransferTo = displayText;
                            _transferToController.text = displayText;

                            // Store selected account for transfer
                            if (accountType == 'mt5') {
                              final account = controller.mt5Accounts.firstWhere(
                                (acc) => acc.metaAccountNumber == value,
                              );
                              _selectedTransferToAccount = account;
                              _selectedTransferToType = 'mt5';
                              controller.selectedToAccount.value = account;
                              controller.selectedToAccountType.value = 'mt5';
                            } else if (accountType == 'wallet') {
                              _selectedTransferToAccount =
                                  controller.wallet.value;
                              _selectedTransferToType = 'wallet';
                              controller.selectedToAccount.value =
                                  controller.wallet.value;
                              controller.selectedToAccountType.value = 'wallet';
                            } else if (accountType == 'ib') {
                              final account = controller.mt5Accounts.firstWhere(
                                (acc) => acc.metaAccountNumber == value,
                                orElse: () => controller.mt5Accounts.first,
                              );
                              _selectedTransferToAccount = account;
                              _selectedTransferToType = 'ib';
                              controller.selectedToAccount.value = account;
                              controller.selectedToAccountType.value = 'ib';
                            }
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayText,
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

  void _handleOtpInput(int index, String value) {
    if (value.length == 1) {
      // User typed a character, move to next box
      if (index < 3) {
        // Small delay to ensure smooth transition
        Future.delayed(Duration(milliseconds: 50), () {
          if (_otpFocusNodes[index + 1].canRequestFocus) {
            _otpFocusNodes[index + 1].requestFocus();
          }
        });
      }
    } else if (value.isEmpty) {
      // User deleted/backspaced - only go back if we're not at the first box
      if (index > 0) {
        // Small delay to ensure smooth transition
        Future.delayed(Duration(milliseconds: 50), () {
          if (_otpFocusNodes[index - 1].canRequestFocus) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        });
      }
    }
  }

  void _onActionButtonPressed() async {
    if (!_showOtpSection) {
      // Transfer Now button clicked - validate and start flow

      // 1. Validate inputs
      if (_selectedTransferFrom == null || _selectedTransferFrom!.isEmpty) {
        CustomToastService.showError(
          message: 'Please select Transfer From account',
        );
        return;
      }

      if (_selectedTransferTo == null || _selectedTransferTo!.isEmpty) {
        CustomToastService.showError(
          message: 'Please select Transfer To account',
        );
        return;
      }

      final rawText = _amountController.text.trim();
      if (rawText.isEmpty) {
        CustomToastService.showError(message: 'Please enter amount');
        return;
      }

      // 2. Parse amount (remove $, commas)
      final cleanedText = rawText.replaceAll(RegExp(r'[^0-9.]'), '');
      final parsedAmount = double.tryParse(cleanedText);
      if (parsedAmount == null || parsedAmount <= 0.0) {
        CustomToastService.showError(
          message: 'Please enter a valid amount greater than 0',
        );
        return;
      }

      // 3. Get account identifier for balance check
      final fromAccountId = _getAccountIdentifier(
        _selectedTransferFromType,
        _selectedTransferFromAccount,
      );

      if (fromAccountId.isEmpty) {
        CustomToastService.showError(message: 'Invalid from account selected');
        return;
      }

      // 4. Check balance
      final isValid = await controller.checkBalance(
        fromAccountId,
        parsedAmount,
      );
      if (!isValid) {
        // Error already shown in checkBalance method
        return;
      }

      // 5. Send OTP
      _isSubmitting.value = true;
      final otpSent = await controller.sendOTP(fromAccountId);
      _isSubmitting.value = false;
      if (otpSent) {
        setState(() {
          _showOtpSection = true;
        });
      }
    } else {
      // Submit OTP
      final otp = _otpControllers.map((controller) => controller.text).join();
      if (otp.length != 4) {
        CustomToastService.showError(
          message: 'Please enter a valid 4-digit OTP',
        );
        return;
      }

      // Validate accounts are still selected
      if (_selectedTransferFrom == null || _selectedTransferTo == null) {
        CustomToastService.showError(
          message: 'Please select both From and To accounts',
        );
        return;
      }

      // Get account identifiers
      final fromAccountId = _getAccountIdentifier(
        _selectedTransferFromType,
        _selectedTransferFromAccount,
      );
      final toAccountId = _getAccountIdentifier(
        _selectedTransferToType,
        _selectedTransferToAccount,
      );

      if (fromAccountId.isEmpty || toAccountId.isEmpty) {
        CustomToastService.showError(message: 'Invalid account selection');
        return;
      }

      // Parse amount
      final rawText = _amountController.text.trim();
      final cleanedText = rawText.replaceAll(RegExp(r'[^0-9.]'), '');

      // Get comment
      final comment = _commentController.text.trim();

      // Submit transfer
      _isSubmitting.value = true;
      final success = await controller.submitInternalTransfer(
        otp,
        comment,
        fromAccountId,
        toAccountId,
        cleanedText,
      );

      if (success && mounted) {
        // Keep submitting state true until we navigate away to avoid
        // a brief enabled/disabled flicker on the button during transition.
        // Navigate back to More screen with bottom navigation after successful transfer
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            // Navigate back to main trading screen (which has bottom navigation)
            // This will clear the navigation stack and return to TradingMainScreen
            // The user can then access the More tab from bottom navigation
            Get.offAllNamed(AppPages.TRADING);
          }
        });
      }
      if (!success && mounted) {
        _isSubmitting.value = false;
      }
    }
  }
}
