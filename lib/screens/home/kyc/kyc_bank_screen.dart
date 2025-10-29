import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/kyc/kyc_bank_controller.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/widgets/common_loading_widget.dart';

class KycBankScreen extends StatefulWidget {
  const KycBankScreen({Key? key}) : super(key: key);

  @override
  State<KycBankScreen> createState() => _KycBankScreenState();
}

class _KycBankScreenState extends State<KycBankScreen> {
  late final KycBankController controller;
  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _beneficiaryBankController =
      TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _confirmAccountNumberController =
      TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();
  final TextEditingController _cryptoAddressController =
      TextEditingController();
  final TextEditingController _upiAddressController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _ifscIbanCodeController = TextEditingController();

  // Get screen name from arguments
  String? screenName;

  // Account number validation state
  final RxBool _accountNumbersMatch = false.obs;
  final RxBool _showValidationError = false.obs;

  // Static variables for show/hide functionality
  bool _showAccountNumber1 = true;
  bool _showAccountNumber2 = true;

  @override
  void initState() {
    super.initState();
    try {
      // Initialize the controller
      controller = Get.put(KycBankController());
      // Get screen name from Get.arguments
      screenName = Get.arguments?['screen_name'] as String?;
      print('Screen name from arguments: $screenName');
      controller.setIsBankList(screenName == 'Bank List');
      print('✅ KycBankController initialized successfully');

      // Initialize IFSC/IBAN controller with current value
      _ifscIbanCodeController.text = controller.ifscIbanCode.value;
    } catch (e) {
      print('❌ Error initializing KycBankController: $e');
      // Fallback initialization
      try {
        controller = Get.put(KycBankController());
        print('✅ Fallback KycBankController initialization successful');
      } catch (fallbackError) {
        print('❌ Fallback initialization also failed: $fallbackError');
        // Create a minimal controller
        controller = KycBankController();
        Get.put(controller);
      }
    }
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _beneficiaryBankController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _swiftCodeController.dispose();
    _cryptoAddressController.dispose();
    _upiAddressController.dispose();
    _otpController.dispose();
    _ifscIbanCodeController.dispose();
    super.dispose();
  }

  // Handle back navigation - go to Settings screen
  void _handleBackNavigation() {
    // Always go to Settings screen when back button is pressed
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: IconButton(
            onPressed: () => _handleBackNavigation(),
            icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
          ),
          title: Text(
            'Add Bank',
            style: AppTextStyles.heading.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          color: Colors.white, // Ensure white background
          child: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15.h),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Obx(
                            () => Column(
                              children: [
                                SizedBox(height: 8.h),
                                // Account Type field
                                _buildAccountTypeField(),
                                SizedBox(height: 8.h),
                                  _buildRelationShipTypeField(),
                                // Currency field
                                _buildCurrencyField(),
                                // SizedBox(height: 8.h),

                                // Account Holder Name (common field)
                                _buildFormField(
                                  "Account Holder Name *",
                                  _accountHolderController,
                                  onChanged:
                                      (value) =>
                                          controller.accountHolderName.value =
                                              value,
                                ),

                                // Dynamic fields based on account type
                                ..._buildDynamicFields(),

                                // SizedBox(height: 8.h),

                                // Proof upload section
                                _buildProofUploadSection(),

                                // OTP section
                                if (controller.isOtpSent.value) ...[
                                  SizedBox(height: 20.h),
                                  _buildOtpField(),
                                ],

                                SizedBox(height: 40.h),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Proof upload section (required for all account types)
                      // _buildProofUploadSection(),

                      // Action buttons
                      _buildActionButtons(),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              // Loading overlay
              Obx(
                () =>
                    controller.isLoading.value
                        ? OverlayLoadingWidget(
                          message: 'Submitting withdrawal request...',
                          backgroundColor: Colors.black.withOpacity(0.5),
                        )
                        : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error in KycBankScreen: $e');
      // Fallback UI in case of error
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Withdrawal'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading withdrawal screen',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Account Type field
  Widget _buildAccountTypeField() {
    try {
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: RTLHelper.rtlTextField(
          readOnly: true,
          onTap: _showAccountTypeOptions,
          controller: TextEditingController(
            text: controller.selectedAccountType.value,
          ),
          labelText: 'Account Type *',
          suffixIcon: InkWell(
            onTap: _showAccountTypeOptions,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: RTLHelper.rtlIcon(
                Icons.keyboard_arrow_down,
                color: AppColors.icongrey,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error in _buildAccountTypeField: $e');
      return Container(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Error loading account type field',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  // Currency field
  Widget _buildCurrencyField() {
    try {
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: RTLHelper.rtlTextField(
          readOnly: true,
          onTap: _showCurrencyOptions,
          controller: TextEditingController(
            text: controller.selectedCurrency.value,
          ),
          labelText: 'Currency *',
          suffixIcon: InkWell(
            onTap: _showCurrencyOptions,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: RTLHelper.rtlIcon(
                Icons.keyboard_arrow_down,
                color: AppColors.icongrey,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error in _buildCurrencyField: $e');
      return Container(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Error loading currency field',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  // Dynamic fields based on account type
  List<Widget> _buildDynamicFields() {
    try {
      return [
        // Animated container for smooth transitions
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(children: _getFieldsForAccountType()),
        ),
      ];
    } catch (e) {
      print('Error in _buildDynamicFields: $e');
      return [
        Container(
          padding: EdgeInsets.all(20.w),
          child: Text(
            'Error loading form fields',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.red,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }
  }

  // Get fields based on selected account type
  List<Widget> _getFieldsForAccountType() {
    switch (controller.selectedAccountType.value.toLowerCase()) {
      case 'bank':
        return _buildBankFields();
      case 'crypto':
        return _buildCryptoFields();
      case 'upi':
        return _buildUpiFields();
      default:
        return [
          Container(
            padding: EdgeInsets.all(20.w),
            child: Text(
              'Please select an account type to see relevant fields',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ];
    }
  }

  // Bank fields
  List<Widget> _buildBankFields() {
    return [
      // Bank section header
      // _buildSectionHeader("Bank Details", Icons.account_balance),
      _buildFormField(
        "Bank Name *",
        _beneficiaryBankController,
        onChanged: (value) => controller.bankName.value = value,
        // icon: Icons.account_balance,
      ),
      // IFSC/IBAN Radio Selection
      // _buildIfscIbanRadioSelection(),
      // SizedBox(height: 16.h),
      _buildIfscIbanField(),
      _buildAccountNumberField(
        "Bank Account Number *",
        _accountNumberController,
        onChanged: (value) => controller.bankAccountNumber.value = value,
        isFirstField: true,
      ),
      _buildAccountNumberField(
        "Confirm Bank Account Number *",
        _confirmAccountNumberController,
        onChanged: (value) => controller.confirmBankAccountNumber.value = value,
        isFirstField: false,
      ),
      _buildFormField(
        "Bank Swift Code",
        _swiftCodeController,
        onChanged: (value) => controller.bankSwiftCode.value = value,
        // icon: Icons.code,
      ),
    ];
  }

  // Crypto fields
  List<Widget> _buildCryptoFields() {
    return [
      // Crypto section header
      // _buildSectionHeader("Crypto Details", Icons.currency_bitcoin),
      _buildFormField(
        "Crypto Address *",
        _cryptoAddressController,
        onChanged: (value) => controller.cryptoAddress.value = value,
        // icon: Icons.currency_bitcoin,
        keyboardType: TextInputType.text,
      ),
    ];
  }

  // UPI fields
  List<Widget> _buildUpiFields() {
    return [
      // UPI section header
      _buildFormField(
        "UPI Address *",
        _upiAddressController,
        onChanged: (value) => controller.upiAddress.value = value,
        // icon: Icons.payment,
        keyboardType: TextInputType.text,
      ),
    ];
  }

  // Proof upload section
  Widget _buildProofUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Add Proof *",
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _showProofOptions,
          child: Obx(
            () => Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                border: Border.all(
                  color: AppColors.primary,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child:
                  controller.proofFile.value == null
                      ? Center(
                        child: Icon(
                          Icons.add,
                          size: 32.sp,
                          color: AppColors.primary,
                        ),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.file(
                          controller.proofFile.value!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }

  // OTP field
  Widget _buildOtpField() {
    return Column(
      children: [
        // OTP Information Message
        _buildFormField(
          "Enter OTP *",
          _otpController,
          onChanged: (value) => controller.otp.value = value,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
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
                  "An OTP has been sent to your email.",
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

        // Resend OTP Button
        SizedBox(height: 12.h),
        Align(
          alignment: Alignment.centerRight,
          child: Obx(
            () => TextButton(
              onPressed:
                  controller.canResendOtp
                      ? () {
                        // Resend OTP functionality
                        controller.sendOtp();
                      }
                      : null,
              child: Text(
                controller.isOtpLoading.value
                    ? 'Sending...'
                    : controller.isOtpCountdownActive.value
                    ? 'Resend OTP in ${controller.getFormattedCountdown()}'
                    : 'Resend OTP',
                style: TextStyle(
                  fontSize: 14.sp,
                  color:
                      controller.canResendOtp
                          ? AppColors.primary
                          : AppColors.textGrey,
                  fontWeight: FontWeight.w600,
                  decoration:
                      controller.canResendOtp
                          ? TextDecoration.underline
                          : TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Action buttons
  Widget _buildActionButtons() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 46.h,
        child: ElevatedButton(
          onPressed:
              controller.isOtpLoading.value || controller.isLoading.value
                  ? null
                  : () {
                    if (controller.isOtpSent.value) {
                      controller.submitWithdrawal();
                    } else {
                      // Validate account numbers before sending OTP
                      if (controller.selectedAccountType.value.toLowerCase() ==
                          'bank') {
                        if (_validateAccountNumbers()) {
                          controller.sendOtp();
                        } else {
                          // Show error message
                          Get.snackbar(
                            'Validation Error',
                            'Bank account numbers do not match',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      } else {
                        controller.sendOtp();
                      }
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.zero,
          ),
          child:
              controller.isOtpLoading.value || controller.isLoading.value
                  ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
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

  // Helper for Account Type bottom sheet
  void _showAccountTypeOptions() {
    showModalBottomSheet(
      backgroundColor: AppColors.whiteColor,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Select Account Type',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...controller.accountTypes.map((type) {
                return ListTile(
                  title: Text(type),
                  trailing:
                      controller.selectedAccountType.value == type
                          ? Icon(Icons.check, color: AppColors.primary)
                          : null,
                  onTap: () {
                    controller.setAccountType(type);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelationShipTypeField() {
    try {
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: RTLHelper.rtlTextField(
          readOnly: true,
          onTap: _showRelationShipBottomSheet,
          controller: TextEditingController(
            text: controller.selectedRelationship.value,
          ),
          labelText: 'Relationship *',
          suffixIcon: InkWell(
            onTap: _showRelationShipBottomSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: RTLHelper.rtlIcon(
                Icons.keyboard_arrow_down,
                color: AppColors.icongrey,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error in _buildAccountTypeField: $e');
      return Container(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Error loading fields',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  void _showRelationShipBottomSheet() {
    showModalBottomSheet(
      backgroundColor: AppColors.whiteColor,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Select RelationShip',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...controller.relationShips.map((type) {
                return ListTile(
                  title: Text(type),
                  trailing:
                  controller.selectedRelationship.value == type
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    controller.setRelationShip(type);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Helper for Currency bottom sheet
  void _showCurrencyOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Select Currency',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.currencies.length,
                  itemBuilder: (context, index) {
                    final currency = controller.currencies[index];
                    return ListTile(
                      title: Text(currency),
                      trailing:
                          controller.selectedCurrency.value == currency
                              ? Icon(Icons.check, color: AppColors.primary)
                              : null,
                      onTap: () {
                        controller.setCurrency(currency);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper for IFSC/IBAN type selection only
  void _showIfscIbanTypeSelection() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Code Type',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),

                // IBAN Option
                ListTile(
                  title: Text(
                    'IBAN',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  onTap: () {
                    controller.setOptRadio('IBAN');
                    Navigator.pop(context);
                  },
                ),

                // IFSC Option
                ListTile(
                  title: Text(
                    'IFSC',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  onTap: () {
                    controller.setOptRadio('IFSC');
                    Navigator.pop(context);
                  },
                ),

                SizedBox(height: 10.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProofOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );
                  if (picked != null) {
                    controller.setProofFile(File(picked.path));
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Select from Gallery'),
                onTap: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    controller.setProofFile(File(picked.path));
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file),
                title: Text('Attach from Documents'),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                  );
                  if (result != null && result.files.single.path != null) {
                    controller.setProofFile(File(result.files.single.path!));
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // IFSC/IBAN Field with two separate fields
  Widget _buildIfscIbanField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        children: [
          // Left field - IBAN/IFSC selection
          Obx(
            () => RTLHelper.rtlTextField(
              readOnly: true,
              onTap: _showIfscIbanTypeSelection,
              controller: TextEditingController(
                text: controller.optRadio.value,
              ),
              labelText: 'IBAN/IFSC',
              suffixIcon: InkWell(
                onTap: _showIfscIbanTypeSelection,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: RTLHelper.rtlIcon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.icongrey,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Right field - Code input
          RTLHelper.rtlTextField(
            controller: _ifscIbanCodeController,
            onChanged: (value) => controller.ifscIbanCode.value = value,
            labelText: 'Code',
            hintText:
                controller.optRadio.value == 'IFSC'
                    ? 'Enter IFSC code'
                    : 'Enter IBAN code',
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    Function(String)? onChanged,
    TextInputType? keyboardType,
    int? maxLength,
    IconData? icon,
    bool obscureText = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        labelText: label,
        obscureText: obscureText,
        prefixIcon:
            icon != null
                ? RTLHelper.rtlIcon(
                  icon,
                  color: AppColors.primary.withOpacity(0.7),
                  size: 20,
                )
                : null,
      ),
    );
  }

  // Custom account number field with validation
  Widget _buildAccountNumberField(
    String label,
    TextEditingController controller, {
    Function(String)? onChanged,
    bool isFirstField = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Obx(
        () => RTLHelper.rtlTextField(
          controller: controller,
          onChanged: (value) {
            onChanged?.call(value);
            _validateAccountNumbers();
          },
          keyboardType: TextInputType.number,
          labelText: label,
          obscureText: isFirstField ? _showAccountNumber1 : _showAccountNumber2,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                if (isFirstField) {
                  _showAccountNumber1 = !_showAccountNumber1;
                } else {
                  _showAccountNumber2 = !_showAccountNumber2;
                }
              });
            },
            icon: Icon(
              (isFirstField ? _showAccountNumber1 : _showAccountNumber2)
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: AppColors.primary.withOpacity(0.7),
            ),
          ),
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _showValidationError.value ? Colors.red : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _showValidationError.value ? Colors.red : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _showValidationError.value ? Colors.red : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  // Validate account numbers when Send OTP is clicked
  bool _validateAccountNumbers() {
    final accountNumber = _accountNumberController.text.trim();
    final confirmAccountNumber = _confirmAccountNumberController.text.trim();

    if (accountNumber.isEmpty || confirmAccountNumber.isEmpty) {
      _showValidationError.value = true;
      _accountNumbersMatch.value = false;
      return false;
    }

    if (accountNumber == confirmAccountNumber) {
      _showValidationError.value = false;
      _accountNumbersMatch.value = true;
      return true;
    } else {
      _showValidationError.value = true;
      _accountNumbersMatch.value = false;
      return false;
    }
  }
}
