import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:phone_numbers_parser/metadata.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/screens/auth/register/legal_documents_screen.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/utils/trl_helper.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/tenax_broker_selection_controller.dart';
import '../../../services/deep_link_service.dart';
import '../../../services/secure_storage_service.dart';
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
  final _referrerController = TextEditingController();
  DeepLinkIntent? _inviteIntent;

  // ==================== STATE VARIABLES ====================
  DateTime? _selectedDate;
  String _selectedCountry = '';
  String _selectedCountryCode = '';
  String _selectedCountryFlag = '';
  IsoCode? _selectedIsoCode;
  int _maxPhoneDigits = 15;
  String _selectedTradingExperience = '';
  bool _isUsResident = false;
  bool _isFormValid = false;
  bool _enableBiometricLogin = true;
  final ValueNotifier<bool> _passwordVisible = ValueNotifier<bool>(false);

  // Live tracking of whether first/last name has invalid characters
  bool _firstNameHasInvalidChars = false;
  bool _lastNameHasInvalidChars = false;

  // ==================== SERVICES ====================
  final AuthController _authController = Get.find<AuthController>();
  final LanguageService _languageService = Get.find<LanguageService>();

  // ── HOME-RESTORE SUPPORT ────────────────────────────────────────────
  // When this screen is opened from a logged-in session via the broker
  // selection flow, we show a Home button in the header. Tapping it
  // restores the snapshot session and bounces the user back to TRADING.
  bool _cameFromLoggedInSession = false;
  String? _shadowAuthToken;
  String? _shadowWsToken;
  String? _shadowUserDataJson;
  /// Branding (color, logo, app name, URLs) that was active *before* the
  /// user opened this screen. Captured in initState so the Home button
  /// can restore the previous broker's branding when the user changes
  /// their mind and goes back to the previously-logged-in session.
  FlavorConfig? _previousBranding;

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
    // Capture the branding that was active BEFORE this screen mounted.
    // The new broker's branding has already been applied by the time
    // we get here, so FlavorConfig.snapshotBranding() would return the
    // NEW branding (a no-op on restore). Use the snapshot the broker
    // selection controller captured BEFORE flipping branding — that
    // holds the OLD broker's branding.
    _previousBranding =
        TenaxBrokerSelectionController.pendingBrandingSnapshot ??
        FlavorConfig.snapshotBranding();
    _prefillInviteReferral();

    final args = Get.arguments;
    if (args is Map) {
      _cameFromLoggedInSession = args['cameFromLoggedInSession'] == true;
      _shadowAuthToken = args['shadowAuthToken'] as String?;
      _shadowWsToken = args['shadowWsToken'] as String?;
      _shadowUserDataJson = args['shadowUserDataJson'] as String?;
    }
    // If we were not explicitly told we came from a logged-in session,
    // still show the Home button if storage says the user is logged in.
    if (!_cameFromLoggedInSession) {
      SecureStorageService.isUserLoggedIn().then((loggedIn) {
        if (!mounted || !loggedIn) return;
        setState(() {
          _cameFromLoggedInSession = true;
        });
      });
    }
    _addListeners();
    _setDeviceCountry();
  }

  /// Fills the referrer code from a Tenax invite link, unless the user already
  /// typed one.
  Future<void> _prefillInviteReferral() async {
    final intent = await DeepLinkService.instance.getPendingReferral();
    if (!mounted) return;
    _inviteIntent = intent;
    final code = intent?.referralCode;
    if (code == null || _referrerController.text.isNotEmpty) return;
    _referrerController.text = code;
    debugPrint('DeepLinkService: referral prefilled on register: $code');
  }

  @override
  void dispose() {
    try {
      TenaxBrokerSelectionController.clearPendingBroker();
    } catch (_) {}
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _tradingExperienceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referrerController.dispose();
    _passwordVisible.dispose();
    super.dispose();
  }

  /// Restore the previously-logged-in session (and branding) from the
  /// in-memory snapshot (preferred) or fallback to secure storage.
  Future<void> _restoreSessionAndExit() async {
    try {
      String? token = _shadowAuthToken;
      String? wsToken = _shadowWsToken;
      String? userJson = _shadowUserDataJson;
      if ((token == null || token.isEmpty) &&
          (wsToken == null || wsToken.isEmpty) &&
          (userJson == null || userJson.isEmpty)) {
        token = await SecureStorageService.getAuthToken();
        wsToken = await SecureStorageService.getWebsocketToken();
        userJson = await SecureStorageService.getUserDataRawJson();
      }
      if (token == null || token.isEmpty) {
        Get.offAllNamed(AppPages.GET_STARTED);
        return;
      }

      // 1) Restore branding FIRST.
      FlavorConfig.restoreBranding(_previousBranding);
      try {
        if (Get.isRegistered<LanguageService>()) {
          Get.find<LanguageService>().brandingUpdateIndex.value++;
        }
      } catch (_) {}

      // 2) Restore the previous session.
      await SecureStorageService.saveAuthToken(token);
      if (wsToken != null && wsToken.isNotEmpty) {
        await SecureStorageService.saveWebsocketToken(wsToken);
      }
      if (userJson != null && userJson.isNotEmpty) {
        await SecureStorageService.saveUserData(userJson);
        try {
          await Get.find<AuthController>().getUserData();
        } catch (_) {}
      }
      await SecureStorageService.saveLoginStatus(true);
      Get.find<AuthController>().markSessionRestored();

      // 3) Clear the staged broker.
      try {
        TenaxBrokerSelectionController.clearPendingBroker();
      } catch (_) {}

      Get.offAllNamed(AppPages.TRADING);
    } catch (e) {
      print('CreateAccountScreen: Failed to restore session: $e');
      Get.offAllNamed(AppPages.GET_STARTED);
    }
  }

  // ==================== LISTENERS & VALIDATION ====================
  void _addListeners() {
    _firstNameController.addListener(_onFirstNameChanged);
    _lastNameController.addListener(_onLastNameChanged);
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    // _cityController.addListener(_validateForm);
    // _addressController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _onFirstNameChanged() {
    final text = _firstNameController.text;
    final hasInvalid = text.isNotEmpty && _hasInvalidNameCharacters(text);
    if (hasInvalid != _firstNameHasInvalidChars) {
      setState(() {
        _firstNameHasInvalidChars = hasInvalid;
      });
    }
  }

  void _onLastNameChanged() {
    final text = _lastNameController.text;
    final hasInvalid = text.isNotEmpty && _hasInvalidNameCharacters(text);
    if (hasInvalid != _lastNameHasInvalidChars) {
      setState(() {
        _lastNameHasInvalidChars = hasInvalid;
      });
    }
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _isPhoneValid() &&
          _isValidEmail(_emailController.text.trim()) &&
          _passwordController.text.isNotEmpty;
    });
  }

  // ---- Country-aware phone helpers --------------------------------------

  /// Maps a 2-letter ISO country code (from country_picker) to an [IsoCode].
  IsoCode? _isoFromCountryCode(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return null;
    final upper = countryCode.toUpperCase();
    for (final iso in IsoCode.values) {
      if (iso.name == upper) return iso;
    }
    return null;
  }

  /// Computes the max number of national digits for the given country so the
  /// input can be capped per-country (e.g. 10 for IN, 9 for many others).
  int _maxDigitsForIso(IsoCode? iso) {
    if (iso == null) return 15;
    final lengths = metadataLenghtsByIsoCode[iso];
    if (lengths == null) return 15;
    final all = <int>[
      ...lengths.general,
      ...lengths.mobile,
      ...lengths.fixedLine,
    ];
    if (all.isEmpty) return 15;
    return all.reduce((a, b) => a > b ? a : b);
  }

  /// Returns only the digits currently entered in the phone field.
  String get _phoneDigits =>
      _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

  /// Country-aware validity of the entered phone number.
  bool _isPhoneValid() {
    final digits = _phoneDigits;
    if (digits.isEmpty) return false;
    final iso = _selectedIsoCode;
    if (iso == null) return digits.length >= 6 && digits.length <= 15;
    try {
      final number = PhoneNumber.parse(digits, destinationCountry: iso);
      if (number.isValid(type: PhoneNumberType.mobile) || number.isValid()) {
        return true;
      }
    } catch (_) {}
    // Fallback: If library parsing fails or says it is invalid (e.g. mock/test numbers or unassigned area codes),
    // we accept it if the length of the digits is reasonable (e.g., between 7 and 15 digits).
    return digits.length >= 7 && digits.length <= 15;
  }

  /// Formats the entered national number for display (country specific).
  void _formatPhoneInput() {
    final iso = _selectedIsoCode;
    final digits = _phoneDigits;
    if (iso == null || digits.isEmpty) return;
    try {
      final formatted =
          PhoneNumber.parse(digits, destinationCountry: iso).formatNsn();
      if (formatted.isNotEmpty && formatted != _phoneController.text) {
        _phoneController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    } catch (_) {
      // Keep raw input if it cannot be formatted yet.
    }
  }

  void _applyCountry({
    required String phoneCode,
    required String flagEmoji,
    required String countryIso2,
    String? countryName,
  }) {
    final iso = _isoFromCountryCode(countryIso2);
    setState(() {
      if (countryName != null) {
        _selectedCountry = countryName;
      }
      _selectedCountryCode = "+$phoneCode";
      _selectedCountryFlag = "$flagEmoji +$phoneCode";
      _selectedIsoCode = iso;
      _maxPhoneDigits = _maxDigitsForIso(iso);
    });
    // Re-trim/format any existing input to the newly selected country.
    final digits = _phoneDigits;
    if (digits.length > _maxPhoneDigits) {
      _phoneController.text = digits.substring(0, _maxPhoneDigits);
    }
    _formatPhoneInput();
    _validateForm();
  }

  // -----------------------------------------------------------------------

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
        "mobile": _phoneDigits,
        "otp_verification_type": "email",
        "register_event_type": "verifyOtp",
        // "register_event_type": "register",
        "accept_terms": true,
      };

      // Add referrer code if provided (optional)
      final referrerCode = _referrerController.text.trim();
      if (referrerCode.isNotEmpty) {
        registrationData["ib_affiliate_refcode"] = referrerCode;
        registrationData.addAll(
          DeepLinkService.registrationFieldsFor(_inviteIntent, referrerCode),
        );
      }

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
    // Validate email before proceeding
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Please enter your email address',
      );
      return;
    }

    if (!_isValidEmail(email)) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Please check email, email is not valid',
      );
      return;
    }

    // Validate form before proceeding
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    final registrationData = {
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "email": email,
      "password": _passwordController.text.trim(),
      "mobile": _phoneDigits,
      "otp_verification_type": "email",
      "register_event_type": "register",
      "accept_terms": true,
      "register_country_code": _selectedCountryCode,
      "enable_biometric": _enableBiometricLogin,
    };

    // Add referrer code if provided (optional)
    final referrerCode = _referrerController.text.trim();
    if (referrerCode.isNotEmpty) {
      registrationData["ib_affiliate_refcode"] = referrerCode;
      registrationData.addAll(
        DeepLinkService.registrationFieldsFor(_inviteIntent, referrerCode),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                LegalDocumentsScreen(registrationData: registrationData),
      ),
    );
  }

  // ==================== NAME VALIDATION HELPERS ====================
  /// Returns true when [value] contains any character other than letters or
  /// spaces. Catches emojis, numbers, punctuation and other special characters.
  bool _hasInvalidNameCharacters(String value) {
    if (value.isEmpty) return false;
    // Allow Unicode letters (covers accented chars) plus spaces.
    // Reject anything else: digits, emojis, punctuation, symbols.
    final allowed = RegExp(r"^[\p{L}\s]+$", unicode: true);
    return !allowed.hasMatch(value);
  }


  void _showLoadingDialog(String message) {
    CommonLoadingWidget(isFullScreen: true);
  }

  void _hideLoadingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back(closeOverlays: true);
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
        backgroundColor: AppColors.cardBackground,
        textStyle: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
      onSelect: (Country country) {
        _applyCountry(
          phoneCode: country.phoneCode,
          flagEmoji: country.flagEmoji,
          countryIso2: country.countryCode,
          countryName: country.name,
        );
      },
    );
  }

  void _setDeviceCountry() {
    try {
      final deviceLocale = ui.PlatformDispatcher.instance.locale;
      final countryCode = deviceLocale.countryCode;

      if (countryCode != null && countryCode.isNotEmpty) {
        final countries = CountryService().getAll();
        final deviceCountry = countries.firstWhere(
          (country) =>
              country.countryCode.toUpperCase() == countryCode.toUpperCase(),
          orElse: () => countries.first,
        );

        _applyCountry(
          phoneCode: deviceCountry.phoneCode,
          flagEmoji: deviceCountry.flagEmoji,
          countryIso2: deviceCountry.countryCode,
          countryName: deviceCountry.name,
        );
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
            backgroundColor: AppColors.cardBackground,
            title: Text(
              _languageService.tr("register_trading_experience"),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _tradingExperienceOptions.map((option) {
                    return ListTile(
                      title: Text(
                        option,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
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
                child: Text(
                  _languageService.tr("cancel"),
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
    );
  }

  // ==================== BUILD METHODS ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
        _buildNameTextField(
          controller: _firstNameController,
          label: _languageService.tr("register_first_name"),
          showInvalidCharsError: _firstNameHasInvalidChars,
          validator:
              (value) => _validateRequired(value, 'validation_name_required'),
        ),
        _buildNameTextField(
          controller: _lastNameController,
          label: _languageService.tr("register_last_name"),
          showInvalidCharsError: _lastNameHasInvalidChars,
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
          validator: (value) => _validateEmail(value),
        ),
        _buildPasswordField(),
        // _buildTextField(
        //   controller: _referrerController,
        //   label: 'Referrer Code',
        //   keyboardType: TextInputType.text,
        //   maxLength: 30,
        // ),
        _buildBiometricCheckbox(),
        // _buildTradingExperienceField(),
        SizedBox(height: 12.h),
        // _buildCheckbox(),
      ],
    );
  }

  Widget _buildBiometricCheckbox() {
    return RTLHelper.rtlRow(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 5.h),
          child: SizedBox(
            width: 20.w,
            height: 20.h,
            child: Checkbox(
              value: _enableBiometricLogin,
              onChanged: (value) {
                setState(() {
                  _enableBiometricLogin = value ?? true;
                });
              },
              activeColor: AppColors.primary,
              checkColor: AppColors.whiteColor,
              side: BorderSide(color: AppColors.textGrey, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 5.h, left: 6.w),
            child: Text(
              _languageService.tr('biometric_enable_on_register'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool? obscureText,
    int? maxLength,
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
        inputFormatters:
            maxLength != null
                ? [LengthLimitingTextInputFormatter(maxLength)]
                : null,
      ),
    );
  }

  /// Wraps [RTLHelper.rtlTextField] with a live-updating error banner
  /// shown above the field. The error message reads "Only letters and spaces
  /// are allowed. Special characters, emojis and numbers are not allowed."
  /// and is rendered whenever [showInvalidCharsError] is true.
  Widget _buildNameTextField({
    required TextEditingController controller,
    required String label,
    required bool showInvalidCharsError,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showInvalidCharsError)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(
                _languageService.tr('validation_name_invalid_characters'),
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          RTLHelper.rtlTextField(
            obscureText: false,
            controller: controller,
            labelText: label,
            keyboardType: keyboardType ?? TextInputType.text,
            validator: validator,
            inputFormatters:
                maxLength != null
                    ? [LengthLimitingTextInputFormatter(maxLength)]
                    : null,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: AppColors.textGrey),
              floatingLabelStyle:
                  showInvalidCharsError
                      ? TextStyle(color: AppColors.error)
                      : TextStyle(color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      showInvalidCharsError
                          ? AppColors.error
                          : AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      showInvalidCharsError
                          ? AppColors.error
                          : AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      showInvalidCharsError
                          ? AppColors.error
                          : AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
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
              color: AppColors.textGrey,
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
              height: 44.h,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _selectedCountryFlag.isNotEmpty
                    ? _selectedCountryFlag
                    : "🌐 +--",
                style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: RTLHelper.rtlTextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              labelText: _languageService.tr("register_phone"),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-()]')),
                _PhoneDigitsLimitFormatter(() => _maxPhoneDigits),
              ],
              onChanged: (_) => _formatPhoneInput(),
              decoration: InputDecoration(
                labelText: _languageService.tr("register_phone"),
                labelStyle: TextStyle(color: AppColors.textGrey),
                floatingLabelStyle: TextStyle(color: AppColors.textGrey),
                hintStyle: TextStyle(color: AppColors.textGrey),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) {
                  return _languageService.tr('validation_required');
                }
                if (!_isPhoneValid()) {
                  return _languageService.tr('create_account_validation_phone');
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
            child: RTLHelper.rtlIcon(
              Icons.arrow_drop_down,
              color: AppColors.textGrey,
            ),
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
              checkColor: AppColors.whiteColor,
              side: BorderSide(color: AppColors.textGrey, width: 1.5),
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
        height: 46.h,
        text: _languageService.tr("onboarding_next"),
        onPressed: _isFormValid ? _navigateToNextScreen : null,
        backgroundColor:
            AppColors.isDarkMode ? AppColors.primary : AppColors.primary,
        foregroundColor:
            _isFormValid ? AppColors.whiteColor : AppColors.textGrey,
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
          if (_cameFromLoggedInSession) ...[
            SizedBox(width: 12.w),
            _buildHomeButton(),
          ],
          SizedBox(width: 16.w),
          Expanded(child: _buildProgressBar()),
        ],
      ),
    );
  }

  Widget _buildHomeButton() {
    return Container(
      height: 40.h,
      width: 40.w,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: _restoreSessionAndExit,
        icon: const Icon(Icons.home_outlined),
        color: AppColors.textPrimary,
        iconSize: 20.h,
        padding: EdgeInsets.zero,
        tooltip: 'Back to home',
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      height: 40.h,
      width: 40.w,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: RTLHelper.rtlIcon(
          Icons.arrow_back_ios,
          color: AppColors.textPrimary,
        ),
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return _languageService.tr('validation_required');
    }
    if (!_isValidEmail(value)) {
      return 'Please check email, email is not valid';
    }
    return null;
  }

  bool _isValidEmail(String email) {
    // Basic email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
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

/// Limits the phone field to a country-specific number of DIGITS while still
/// allowing separator characters (space, dash, parentheses) added by formatting.
class _PhoneDigitsLimitFormatter extends TextInputFormatter {
  _PhoneDigitsLimitFormatter(this.maxDigits);

  final int Function() maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= maxDigits()) {
      return newValue;
    }
    return oldValue;
  }
}
