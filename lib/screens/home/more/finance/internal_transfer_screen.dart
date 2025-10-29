import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/controllers/wallet_controller.dart';

class InternalTransferScreen extends StatefulWidget {
  const InternalTransferScreen({Key? key}) : super(key: key);

  @override
  State<InternalTransferScreen> createState() => _InternalTransferScreenState();
}

class _InternalTransferScreenState extends State<InternalTransferScreen> {
  final WalletController controller = Get.put(WalletController());
  final TextEditingController _transferFromController = TextEditingController(
    text: 'MT5 Account Number',
  );
  final TextEditingController _transferToController = TextEditingController(
    text: 'MT5 Account Number',
  );
  final TextEditingController _amountController = TextEditingController(
    text: '\$500.00',
  );

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  bool _showOtpSection = false;
  String _selectedTransferFrom = 'MT5 Account Number';
  String _selectedTransferTo = 'MT5 Account Number';

  @override
  void dispose() {
    _transferFromController.dispose();
    _transferToController.dispose();
    _amountController.dispose();
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
          onPressed: () => Get.back(),
        ),
        title: Text('Internal Transfer', style: AppTextStyles.screenTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                // padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),

                    // Balance Information Section
                    _buildBalanceSection(),

                    SizedBox(height: 32.h),

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
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Column(
      children: [
        SizedBox(height: 10.h),

        // Wallet Balance
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wallet Balance',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.37,
                ),
              ),
              Text(
                '\$100.00',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.icongrey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),
        _buildDivider(),
        SizedBox(height: 20.h),

        // Pipze Account Balance
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pipze Account Balance',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$100.00',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.icongrey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),
        _buildDivider(),
        SizedBox(height: 20.h),

        // MT5 Account Balance
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MT5 Account Balance',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$100.00',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.icongrey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        _buildDivider(),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.grey[200]);
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
        onChanged: (value) => _selectedTransferTo = value,
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
        keyboardType: TextInputType.numberWithOptions(signed: true,decimal: true),
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
      child: ElevatedButton(
        onPressed: _onActionButtonPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          _showOtpSection ? 'Submit OTP' : 'Transfer Now',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showTransferFromDropdown() {
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
                    itemCount:
                        [
                          'MT5 Account Number',
                          'Pipze Account',
                          'Wallet',
                        ].length,
                    itemBuilder: (context, index) {
                      final option =
                          [
                            'MT5 Account Number',
                            'Pipze Account',
                            'Wallet',
                          ][index];
                      final isSelected = option == _selectedTransferFrom;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTransferFrom = option;
                            _transferFromController.text = option;
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

  void _onActionButtonPressed() {
    if (!_showOtpSection) {
      // Show OTP section when Transfer Now is clicked
      setState(() {
        _showOtpSection = true;
      });

      // Show success message - use controlled approach
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP has been sent to your registered mobile number'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } else {
      // Submit OTP
      final otp = _otpControllers.map((controller) => controller.text).join();
      if (otp.length == 4) {
        // Process OTP submission
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transfer is being processed'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
              margin: EdgeInsets.all(16),
            ),
          );
        }

        // Navigate back after successful submission
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            Get.back();
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enter a valid 4-digit OTP'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
              margin: EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }
}
