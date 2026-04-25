import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/utils/trl_helper.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../services/secure_storage_service.dart';
import '../../../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool obscureText = true;

  // Get the AuthController
  final AuthController authController = Get.find<AuthController>();

  // Get the LanguageService
  final LanguageService languageService = Get.find<LanguageService>();

  bool _biometricPrompted = false;

  // Validation states
  bool isEmailValid = false;
  bool isPasswordValid = false;
  bool _enableBiometricAfterLogin = false;

  // Validation methods
  bool _validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  void _handleLogin() {
    print("object is click on ${authController.isLoading}");
    if (_formKey.currentState!.validate()) {
      authController.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        enableBiometricAfterLogin: _enableBiometricAfterLogin,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricLogin();
    });
  }

  Future<void> _tryBiometricLogin() async {
    if (_biometricPrompted) return;
    _biometricPrompted = true;

    final enabled = await SecureStorageService.getBiometricEnabled();
    if (!enabled) return;

    final token = await SecureStorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    final bio = BiometricService.instance;
    final supported = await bio.isDeviceSupported();
    final enrolled = await bio.isEnrolled();
    if (!supported || !enrolled) {
      await SecureStorageService.setBiometricEnabled(false);
      if (mounted) {
        await _showBiometricNotEnrolledDialog();
      }
      return;
    }

    final ok = await bio.authenticate(
      reason: languageService.tr('biometric_auth_reason_login'),
    );
    if (!ok) return;

    await SecureStorageService.saveLoginStatus(true);
    await authController.checkAuthStatus();
    if (!mounted) return;
    Get.offAllNamed(AppPages.TRADING);
  }

  Future<void> _showBiometricNotEnrolledDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(languageService.tr('biometric_not_enabled_title')),
          content: Text(languageService.tr('biometric_not_enabled_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(languageService.tr('common_close')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await BiometricService.instance.openDeviceSecuritySettings();
              },
              child: Text(languageService.tr('biometric_open_settings')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnableBiometricAfterLoginCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _enableBiometricAfterLogin,
            onChanged: (v) async {
              final next = v ?? false;
              if (!next) {
                setState(() => _enableBiometricAfterLogin = false);
                return;
              }

              final supported =
                  await BiometricService.instance.isDeviceSupported();
              final enrolled = await BiometricService.instance.isEnrolled();
              if (!supported || !enrolled) {
                if (!mounted) return;
                await _showBiometricNotEnrolledDialog();
                setState(() => _enableBiometricAfterLogin = false);
                return;
              }

              if (!mounted) return;
              setState(() => _enableBiometricAfterLogin = true);
            },
            activeColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            languageService.tr('biometric_enable_on_register'),
            style: TextStyle(
              color: AppColors.textGrey,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: 16.h),
                                  Center(
                                    child: BrandLogo(
                                      source: FlavorConfig.effectiveLogo,
                                      color: FlavorConfig.isONSA() &&
                                              !FlavorConfig.hasRemoteLogo
                                          ? AppColors.primary
                                          : null,
                                      height: 100.h,
                                      width: 120.w,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 70.h),
                                    child: Text(
                                      languageService.tr("welcome_title"),
                                      style: AppTextStyles.welcomeTitle,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  RTLHelper.rtlTextField(
                                    controller: emailController,
                                    labelText: languageService.tr(
                                      "register_email",
                                    ),
                                    hintText: languageService.tr(
                                      "register_email",
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return languageService.tr(
                                          "validation_email_required",
                                        );
                                      }
                                      if (!_validateEmail(value)) {
                                        return languageService.tr(
                                          "validation_email_invalid",
                                        );
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        isEmailValid = _validateEmail(value);
                                      });
                                    },
                                  ),
                                  SizedBox(height: 16.h),
                                  RTLHelper.rtlTextField(
                                    controller: passwordController,
                                    hintText: languageService.tr(
                                      "register_password",
                                    ),
                                    obscureText: obscureText,
                                    labelText: languageService.tr(
                                      "register_password",
                                    ),
                                    suffixIcon: IconButton(
                                      icon: SvgPicture.asset(
                                        obscureText
                                            ? "assets/svg/eye-slash.svg"
                                            : "assets/svg/eye_icon.svg",
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          obscureText = !obscureText;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return languageService.tr(
                                          "validation_password_required",
                                        );
                                      }
                                      if (!_validatePassword(value)) {
                                        return languageService.tr(
                                          "validation_password_min_length",
                                        );
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        isPasswordValid =
                                            _validatePassword(value);
                                      });
                                    },
                                  ),
                                  SizedBox(height: 5.h),
                                  Align(
                                    alignment: languageService.isRTL()
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Get.toNamed(AppPages.FORGOT_PASSWORD);
                                      },
                                      child: Text(
                                        languageService.tr(
                                          "login_forgot_password",
                                        ),
                                        style: AppTextStyles.textButton,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 35.h),
                                  _buildEnableBiometricAfterLoginCheckbox(),
                                  SizedBox(height: 12.h),
                                  Obx(() {
                                    final isLoading = authController.isLoading;
                                    return ElevatedButton(
                                      onPressed:
                                          isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize:
                                            Size(double.infinity, 40.h),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        languageService.tr("login_button"),
                                        style: AppTextStyles.button,
                                      ),
                                    );
                                  }),
                                  SizedBox(height: 16.h),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        Get.toNamed(AppPages.CREATE_ACCOUNT);
                      },
                      child: Text.rich(
                        TextSpan(
                          text:
                              "${languageService.tr("login_no_account_login")} ",
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.textGrey,
                          ),
                          children: [
                            TextSpan(
                              text: languageService.tr("login_register"),
                              style: AppTextStyles.black14500.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Obx(
              () => authController.isLoading
                  ? Center(
                      child: CommonLoadingWidget(isFullScreen: true),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
