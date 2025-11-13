import 'dart:convert';
import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/screens/auth/register/legal_documents_screen.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/widgets/common_loading_widget.dart';
import 'package:pipze/widgets/custom_toast.dart';
import '../../../controllers/auth_controller.dart';
import '../../../widgets/AppTextField.dart';
import '../../../widgets/otp_modal.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // ==================== CONTROLLERS ====================
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tradingExperienceController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ==================== STATE VARIABLES ====================
  DateTime? _selectedDate;
  String _selectedCountry = '';
  String _selectedCountryCode = '';
  String _selectedCountryFlag = '';
  String _selectedTradingExperience = '';
  bool _isUsResident = false;
  bool _isFormValid = false;
  final ValueNotifier<bool> _passwordVisible = ValueNotifier<bool>(false);

  // ==================== SERVICES ====================
  final AuthController _authController = Get.find<AuthController>();
  final LanguageService _languageService = Get.find<LanguageService>();

  // ==================== CONSTANTS ====================
  List<String> get _tradingExperienceOptions => [
    _languageService.tr('register_experience_none'),
    _languageService.tr('register_experience_less_1'),
    _languageService.tr('register_experience_1_2'),
    _languageService.tr('register_experience_more_2'),
  ];

  @override
  void initState() {
    super.initState();
    _addListeners();
    _setDeviceCountry();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _tradingExperienceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordVisible.dispose();
    super.dispose();
  }

  // ==================== LISTENERS & VALIDATION ====================
  void _addListeners() {
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    // _cityController.addListener(_validateForm);
    // _addressController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          // _selectedDate != null &&
          // _selectedCountry.isNotEmpty &&
          // _cityController.text.isNotEmpty &&
          // _addressController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          // _selectedTradingExperience.isNotEmpty &&
          // _isUsResident &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  // ==================== ACCOUNT CREATION FLOW ====================
  // Future<void> _createAccount() async {
  //   if (_formKey.currentState!.validate() && _isFormValid) {
  //     try {
  //       final registrationData = {
  //         "first_name": _firstNameController.text.trim(),
  //         "last_name": _lastNameController.text.trim(),
  //         "email": _emailController.text.trim(),
  //         "password": _passwordController.text.trim(),
  //         "mobile": _phoneController.text.trim(),
  //         "otp_verification_type": "email",
  //         "register_event_type": "register",
  //         "accept_terms": true,
  //         "register_country_code": _selectedCountryCode,
  //       };
  //
  //       // Step 1: Register user
  //       final registrationSuccess = await _authController.register(
  //         data: registrationData,
  //       );
  //
  //       if (registrationSuccess) {
  //         // Step 2: Send OTP for verification
  //         await _sendOTPForVerification();
  //       }
  //     } catch (e) {
  //       _hideLoadingDialog();
  //       _showError('Registration failed: $e');
  //     }
  //   }
  // }

  Future<void> _sendOTPForVerification() async {
    try {
      _showOtpVerificationBottomSheet();
    } catch (e) {
      _hideLoadingDialog();
      _showError('Failed to send OTP: $e');
    }
  }

  // ... existing code ...

  void _showOtpVerificationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent accidental dismissal
      enableDrag: false, // Prevent dragging down
      builder:
          (context) => OtpModal(
            email: _emailController.text.trim(),
            isEmailVerification: true,
            otpLength: 5,
            onOtpSubmitted: (otp) async {
              // Handle OTP verification
              await _verifyOtpAndCompleteRegistration(otp);
            },
            onResendOtp: () async {
              // Handle resending OTP
              await _sendOTPForVerification();
            },
          ),
    );
  }

  // ... existing code ...
  Future<void> _verifyOtpAndCompleteRegistration(String otp) async {
    try {
      _showLoadingDialog('Verifying OTP...');
      final registrationData = {
        "first_name": _firstNameController.text.trim(),
        "last_name": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
        "mobile": _phoneController.text.trim(),
        "otp_verification_type": "email",
        "register_event_type": "verifyOtp",
        // "register_event_type": "register",
        "accept_terms": true,
      };

      // Step 1: Register user
      final otpVerified = await _authController.register(
        data: registrationData,
      );

      _hideLoadingDialog();

      if (otpVerified) {
        // Close OTP modal
        Navigator.of(context).pop();

        // Show success message
        CustomToastService.showSuccess(
          title: 'Success',
          message: 'Account created successfully!',
        );

        // Navigate to next screen
        _navigateToNextScreen();
      }
    } catch (e) {
      _hideLoadingDialog();
      _showError('OTP verification failed: $e');
    }
  }

  void _navigateToNextScreen() {
    // if (_formKey.currentState!.validate()) {
    final registrationData = {
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "mobile": _phoneController.text.trim(),
      "otp_verification_type": "email",
      "register_event_type": "register",
      "accept_terms": true,
      "register_country_code": _selectedCountryCode,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                LegalDocumentsScreen(registrationData: registrationData),
      ),
    );
    // }
  }

  // ==================== UI HELPER METHODS ====================
  void _showLoadingDialog(String message) {
    CommonLoadingWidget(isFullScreen: true);
  }

  void _hideLoadingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void _showError(String message) {
    CustomToastService.showError(title: 'Error', message: message);
  }

  // ==================== DATE & COUNTRY SELECTION ====================
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 36500)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _validateForm();
      });
    }
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true, // ✅ important: show dial code
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, color: Colors.black),
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
          _selectedCountryCode = "+${country.phoneCode}";
          _selectedCountryFlag = "${country.flagEmoji} +${country.phoneCode}";
          _validateForm();
        });
      },
    );
  }

  void _setDeviceCountry() {
    try {
      final deviceLocale = ui.window.locale;
      final countryCode = deviceLocale.countryCode;

      if (countryCode != null && countryCode.isNotEmpty) {
        final countries = CountryService().getAll();
        final deviceCountry = countries.firstWhere(
          (country) => country.countryCode == countryCode,
          orElse: () => countries.first,
        );

        setState(() {
          _selectedCountry = "${deviceCountry.flagEmoji} ${deviceCountry.name}";
          _selectedCountryCode = "+${deviceCountry.phoneCode}";
          _selectedCountryFlag = deviceCountry.flagEmoji;
          _validateForm();
        });
      }
    } catch (e) {
      print("Error detecting device country: $e");
    }
  }

  // ==================== TRADING EXPERIENCE ====================
  void _showTradingExperiencePopup() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.backgroundLight,
            title: Text(_languageService.tr("register_trading_experience")),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _tradingExperienceOptions.map((option) {
                    return ListTile(
                      title: Text(option),
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedTradingExperience = option;
                          _tradingExperienceController.text = option;
                          _validateForm();
                        });
                      },
                      trailing:
                          _selectedTradingExperience == option
                              ? Icon(Icons.check, color: AppColors.primary)
                              : null,
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_languageService.tr("cancel")),
              ),
            ],
          ),
    );
  }

  // ==================== BUILD METHODS ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: RTLHelper.getRTLPadding(left: 24.w, right: 24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24.h),
                      _buildTitleSection(),
                      SizedBox(height: 24.h),
                      _buildFormFields(),
                      SizedBox(height: 24.h),
                      _buildCreateAccountButton(),
                      SizedBox(height: 12.h),
                      _buildLoginLink(),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _languageService.tr("register_title"),
          style: AppTextStyles.heading,
        ),
        SizedBox(height: 4.h),
        Text(
          _languageService.tr("register_personal_info"),
          style: AppTextStyles.subheading.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _firstNameController,
          label: _languageService.tr("register_first_name"),
          validator:
              (value) => _validateRequired(value, 'validation_name_required'),
        ),
        _buildTextField(
          controller: _lastNameController,
          label: _languageService.tr("register_last_name"),
          validator:
              (value) => _validateRequired(value, 'validation_name_required'),
        ),
        // _buildDateOfBirthField(),
        _buildCountryField(),
        // _buildTextField(
        //   controller: _cityController,
        //   label: _languageService.tr("register_city"),
        //   validator: (value) => _validateRequired(value, 'validation_required'),
        // ),
        // _buildTextField(
        //   controller: _addressController,
        //   label: _languageService.tr("register_address"),
        //   validator: (value) => _validateRequired(value, 'validation_required'),
        // ),
        // _buildTextField(
        //   controller: _phoneController,
        //   label: _languageService.tr("register_phone"),
        //   keyboardType: TextInputType.phone,
        //   validator: (value) => _validateRequired(value, 'validation_required'),
        // ),
        _buildTextField(
          controller: _emailController,
          label: _languageService.tr("register_email"),
          keyboardType: TextInputType.emailAddress,
          validator: (value) => _validateRequired(value, 'validation_required'),
        ),
        _buildPasswordField(),
        // _buildTradingExperienceField(),
        SizedBox(height: 12.h),
        // _buildCheckbox(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool? obscureText,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        obscureText: obscureText ?? false,
        controller: controller,
        labelText: label,
        keyboardType: keyboardType,
        validator: validator,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildPasswordField() {
    return ValueListenableBuilder<bool>(
      valueListenable: _passwordVisible,
      builder: (context, isVisible, child) {
        return _buildTextField(
          controller: _passwordController,
          label: _languageService.tr("register_password"),
          keyboardType: TextInputType.text,
          obscureText: !isVisible,
          suffixIcon: IconButton(
            onPressed: () => _passwordVisible.value = !isVisible,
            icon: SvgPicture.asset(
              isVisible
                  ? "assets/svg/eye_icon.svg"
                  : "assets/svg/eye-slash.svg",
            ),
          ),
          validator: (value) => _validatePassword(value),
        );
      },
    );
  }

  Widget _buildDateOfBirthField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        readOnly: true,
        onTap: _selectDate,
        controller: TextEditingController(
          text:
              _selectedDate == null
                  ? ''
                  : DateFormat('dd MMM yyyy').format(_selectedDate!),
        ),
        labelText: _languageService.tr("register_date_of_birth"),
        suffixIcon: InkWell(
          onTap: _selectDate,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: RTLHelper.rtlIcon(
              Icons.calendar_today,
              size: 20,
              color: Colors.grey,
            ),
          ),
        ),
        validator:
            (value) =>
                _selectedDate == null
                    ? _languageService.tr('validation_date_required')
                    : null,
      ),
    );
  }

  Widget _buildCountryField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          InkWell(
            onTap: _showCountryPicker,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _selectedCountryFlag.isNotEmpty
                    ? _selectedCountryFlag
                    : "🌐 +--",
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: _languageService.tr("register_phone"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return _languageService.tr('validation_required');
                }
                if (value.length != 10) {
                  return _languageService.tr('validation_phone_invalid');
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingExperienceField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        readOnly: true,
        onTap: _showTradingExperiencePopup,
        controller: _tradingExperienceController,
        labelText: _languageService.tr("register_trading_experience"),
        suffixIcon: InkWell(
          onTap: _showTradingExperiencePopup,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: RTLHelper.rtlIcon(Icons.arrow_drop_down, color: Colors.grey),
          ),
        ),
        validator:
            (value) =>
                _selectedTradingExperience.isEmpty
                    ? _languageService.tr('validation_experience_required')
                    : null,
      ),
    );
  }

  Widget _buildCheckbox() {
    return RTLHelper.rtlRow(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 5.h),
          child: SizedBox(
            width: 20.w,
            height: 20.h,
            child: Checkbox(
              value: _isUsResident,
              onChanged: (value) {
                setState(() {
                  _isUsResident = value ?? false;
                  _validateForm();
                });
              },
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 5.h, left: 5),
            child: Text(
              _languageService.tr("register_us_resident_confirm"),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textGrey,
                height: 22 / 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: RTLHelper.rtlButton(
        text: _languageService.tr("onboarding_next"),
        onPressed: _isFormValid ? _navigateToNextScreen : null,
        backgroundColor: AppColors.primary,
        foregroundColor: _isFormValid ? Colors.white : AppColors.textGrey,
      ),
    );
  }

  Widget _buildLoginLink() {
    return Align(
      alignment: RTLHelper.getRTLAlignment(Alignment.center),
      child: RichText(
        text: TextSpan(
          text: "${_languageService.tr("register_already_have_account")} ",
          style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp),
          children: [
            TextSpan(
              text: _languageService.tr("register_log_in"),
              style: AppTextStyles.link,
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () => Get.toNamed(AppPages.LOGIN),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: RTLHelper.getRTLPadding(
        left: 24.w,
        right: 24.w,
        top: 16.h,
        bottom: 16.h,
      ),
      child: RTLHelper.rtlRow(
        children: [
          _buildBackButton(),
          SizedBox(width: 16.w),
          Expanded(child: _buildProgressBar()),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      height: 40.h,
      width: 40.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: RTLHelper.rtlIcon(Icons.arrow_back_ios, color: Colors.black),
        iconSize: 17.h,
        padding: RTLHelper.getRTLPadding(left: 5.w),
      ),
    );
  }

  Widget _buildProgressBar() {
    return RTLHelper.rtlRow(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _progressBar(active: true),
        SizedBox(width: 8.w),
        _progressBar(),
        SizedBox(width: 8.w),
        _progressBar(),
      ],
    );
  }

  Widget _progressBar({bool active = false}) {
    return Container(
      width: 60.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ==================== VALIDATION METHODS ====================
  String? _validateRequired(String? value, String errorKey) {
    if (value == null || value.isEmpty) {
      return _languageService.tr(errorKey);
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return _languageService.tr('validation_required');
    }
    if (value.length < 6) {
      return _languageService.tr('validation_password_min_length');
    }
    return null;
  }
}
