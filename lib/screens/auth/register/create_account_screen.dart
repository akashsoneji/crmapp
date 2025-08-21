import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/screens/auth/register/legal_documents_screen.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/utils/trl_helper.dart';
import '../../../controllers/auth_controller.dart';
import '../../../widgets/AppTextField.dart';

class CreateAccountScreen1 extends StatefulWidget {
  const CreateAccountScreen1({super.key});

  @override
  State<CreateAccountScreen1> createState() => _CreateAccountScreen1State();
}

class _CreateAccountScreen1State extends State<CreateAccountScreen1> {
  final AuthController authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();

  bool acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      RTLHelper.rtlTextField(
                        controller: firstNameController,
                        labelText: 'First Name',
                        hintText: 'Enter your first name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      RTLHelper.rtlTextField(
                        controller: lastNameController,
                        labelText: 'Last Name',
                        hintText: 'Enter your last name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      RTLHelper.rtlTextField(
                        controller: emailController,
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      RTLHelper.rtlTextField(
                        controller: passwordController,
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      RTLHelper.rtlTextField(
                        controller: mobileController,
                        labelText: 'Mobile',
                        hintText: 'Enter your mobile number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mobile number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      RTLHelper.rtlTextField(
                        controller: otpController,
                        labelText: 'OTP',
                        hintText: 'Enter OTP',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'OTP is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            acceptTerms = value ?? false;
                          });
                        },
                        title: const Text('I accept the terms and conditions'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              Obx(() {
                final isLoading = authController.isLoading;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isLoading || !acceptTerms ? null : _handleRegister,
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Create Account'),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate() && acceptTerms) {
      authController.register(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        mobile: mobileController.text.trim(),
        otp: otpController.text.trim(),
        registerEventType: 'email',
        acceptTerms: acceptTerms,
      );
    }
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tradingExperienceController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedCountry = '';
  String _selectedCountryFlag = '';
  String _selectedTradingExperience = '';
  bool _isUsResident = false;
  bool _isFormValid = false;
  final AuthController authController = Get.find<AuthController>();
  final LanguageService languageService = Get.find<LanguageService>();

  List<String> get _tradingExperienceOptions => [
    languageService.tr('register_experience_none'),
    languageService.tr('register_experience_less_1'),
    languageService.tr('register_experience_1_2'),
    languageService.tr('register_experience_more_2'),
  ];

  @override
  void initState() {
    super.initState();
    _addListeners();
    _setDeviceCountry();
  }

  void _addListeners() {
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _cityController.addListener(_validateForm);
    _addressController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _selectedDate != null &&
          _selectedCountry.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _addressController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _selectedTradingExperience.isNotEmpty &&
          _isUsResident;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _tradingExperienceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime.now().subtract(
        const Duration(days: 36500),
      ), // 100 years ago
      lastDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
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
      showPhoneCode: false,
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
          _selectedCountry = "${country.flagEmoji} ${country.name}";
          _selectedCountryFlag = country.flagEmoji;
          _validateForm();
        });
      },
    );
  }

  void _clearCountrySelection() {
    setState(() {
      _selectedCountry = '';
      _selectedCountryFlag = '';
      _validateForm();
    });
  }

  void _setDeviceCountry() {
    try {
      // Get device locale
      final deviceLocale = ui.window.locale;
      final countryCode = deviceLocale.countryCode;

      print(
        "Device locale: ${deviceLocale.languageCode}_${deviceLocale.countryCode}",
      );

      if (countryCode != null && countryCode.isNotEmpty) {
        // Find the country by country code
        final countries = CountryService().getAll();
        final deviceCountry = countries.firstWhere(
          (country) => country.countryCode == countryCode,
          orElse:
              () => countries.first, // Default to first country if not found
        );

        setState(() {
          _selectedCountry = "${deviceCountry.flagEmoji} ${deviceCountry.name}";
          _selectedCountryFlag = deviceCountry.flagEmoji;
          _validateForm();
        });

        print(
          "Device country detected: ${deviceCountry.name} (${deviceCountry.countryCode})",
        );
      } else {
        print("No country code found in device locale");
      }
    } catch (e) {
      print("Error detecting device country: $e");
      // If detection fails, leave it empty for user to select
    }
  }

  // Method to manually set a specific country (for testing or fallback)
  void _setSpecificCountry(String countryCode) {
    try {
      final countries = CountryService().getAll();
      final country = countries.firstWhere(
        (country) => country.countryCode == countryCode,
        orElse: () => countries.first,
      );

      setState(() {
        _selectedCountry = "${country.flagEmoji} ${country.name}";
        _selectedCountryFlag = country.flagEmoji;
        _validateForm();
      });

      print(
        "Country manually set to: ${country.name} (${country.countryCode})",
      );
    } catch (e) {
      print("Error setting specific country: $e");
    }
  }

  void _showTradingExperiencePopup() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.backgroundLight,
            title: Text(languageService.tr("register_trading_experience")),
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
                child: Text(languageService.tr("cancel")),
              ),
            ],
          ),
    );
  }

  void _createAccount() {
    if (_formKey.currentState!.validate() && _isFormValid) {
      // Prepare registration data
      final registrationData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': '', // This will be filled in later steps
        'password': '', // This will be filled in later steps
        'mobile': _phoneController.text.trim(),
        'otp': '', // This will be filled in later steps
        'registerEventType': _selectedTradingExperience,
        'acceptTerms': false, // This will be set in legal documents screen
      };

      // Navigate to legal documents screen with registration data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  LegalDocumentsScreen(registrationData: registrationData),
        ),
      );
    }
  }

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
                      Text(
                        languageService.tr("register_title"),
                        style: AppTextStyles.heading,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        languageService.tr("register_personal_info"),
                        style: AppTextStyles.subheading.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildTextField(
                        controller: _firstNameController,
                        label: languageService.tr("register_first_name"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageService.tr(
                              'validation_name_required',
                            );
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _lastNameController,
                        label: languageService.tr("register_last_name"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageService.tr(
                              'validation_name_required',
                            );
                          }
                          return null;
                        },
                      ),
                      _buildDateOfBirthField(),
                      _buildCountryField(),
                      _buildTextField(
                        controller: _cityController,
                        label: languageService.tr("register_city"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageService.tr('validation_required');
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _addressController,
                        label: languageService.tr("register_address"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageService.tr('validation_required');
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: languageService.tr("register_phone"),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageService.tr('validation_required');
                          }
                          return null;
                        },
                      ),
                      _buildTradingExperienceField(),
                      SizedBox(height: 12.h),
                      _buildCheckbox(),
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
          // Back button container
          Container(
            height: 40.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: RTLHelper.rtlIcon(
                Icons.arrow_back_ios,
                color: Colors.black,
              ),
              iconSize: 17.h,
              padding: RTLHelper.getRTLPadding(left: 5.w),
            ),
          ),
          SizedBox(width: 16.w),
          // Progress bar row
          Expanded(
            child: RTLHelper.rtlRow(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _progressBar(active: true),
                SizedBox(width: 8.w),
                _progressBar(),
                SizedBox(width: 8.w),
                _progressBar(),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        controller: controller,
        labelText: label,
        keyboardType: keyboardType,
        validator: validator,
      ),
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
        labelText: languageService.tr("register_date_of_birth"),
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
        validator: (value) {
          if (_selectedDate == null) {
            return 'validation_date_required'.tr;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCountryField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: RTLHelper.rtlTextField(
        controller: TextEditingController(text: _selectedCountry),
        readOnly: true,
        onTap: _showCountryPicker,
        // textDirection: RTLHelper.textDirection,
        // textAlign: RTLHelper.isRTL ? TextAlign.right : TextAlign.left,
        decoration: InputDecoration(
          labelText: languageService.tr("register_country"),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          // prefixIcon:
          //     (_selectedCountry.isNotEmpty && _selectedCountryFlag.isNotEmpty)
          //         ? Padding(
          //           padding: const EdgeInsets.symmetric(
          //             horizontal: 8,
          //             vertical: 0,
          //           ),
          //           child: Text(
          //             _selectedCountryFlag,
          //             style: TextStyle(fontSize: 20.sp),
          //           ),
          //         )
          //         : null,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _showCountryPicker,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: RTLHelper.rtlIcon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
        validator: (value) {
          if (_selectedCountry.isEmpty) {
            return languageService.tr('validation_country_required');
          }
          return null;
        },
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
        labelText: languageService.tr("register_trading_experience"),
        suffixIcon: InkWell(
          onTap: _showTradingExperiencePopup,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: RTLHelper.rtlIcon(Icons.arrow_drop_down, color: Colors.grey),
          ),
        ),
        validator: (value) {
          if (_selectedTradingExperience.isEmpty) {
            return languageService.tr('validation_experience_required');
          }
          return null;
        },
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
              languageService.tr("register_us_resident_confirm"),
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
        text: languageService.tr("register_create_account"),
        onPressed: _isFormValid ? _createAccount : null,
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
          text: "${languageService.tr("register_already_have_account")} ",
          style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp),
          children: [
            TextSpan(
              text: languageService.tr("register_log_in"),
              style: AppTextStyles.link,
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      Get.toNamed(AppPages.LOGIN);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
