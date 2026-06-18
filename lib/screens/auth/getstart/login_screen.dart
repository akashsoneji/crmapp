import 'dart:convert';

import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/utils/trl_helper.dart';
import 'package:crm_app/widgets/adaptive/adaptive_app_button.dart';
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

  // Multibroker: other saved profiles for "Back to previous account"
  List<Map<String, dynamic>> _otherProfiles = [];
  bool _multibrokerEnabled = false;

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
      _loadOtherProfiles();
    });
  }

  /// Loads all saved Tenax profiles except the currently active one.
  /// These are shown as "Back to previous account" options.
  Future<void> _loadOtherProfiles() async {
    if (!FlavorConfig.isMultiBrokerEnabled) return;
    final isEnabled = await SecureStorageService.getTenaxBrokerSelectionFlag();
    if (!isEnabled) return;

    final allProfiles = await SecureStorageService.getTenaxUserBrokerProfiles();
    final currentKey = await SecureStorageService.getTenaxCurrentProfileKey();

    // Keep every profile whose key differs from the current one.
    final others = allProfiles
        .where((p) => (p['profile_key'] ?? '').toString() != (currentKey ?? ''))
        .toList();

    if (!mounted) return;
    setState(() {
      _multibrokerEnabled = true;
      _otherProfiles = others;
    });
  }

  /// Restores a saved profile's auth token + broker config and navigates to TRADING.
  Future<void> _switchToProfile(Map<String, dynamic> profile) async {
    final brokerData = profile['broker_data'];
    if (brokerData is! Map<String, dynamic>) return;

    // 1. Apply broker config (URL, colors, logo)
    final runtimeConfig =
        (brokerData['broker_runtime_config'] is Map<String, dynamic>
            ? brokerData['broker_runtime_config'] as Map<String, dynamic>
            : brokerData);
    final selectedName = (brokerData['selected_name'] ?? '').toString();
    final selectedLogo = (brokerData['selected_logo_local_path'] ??
            brokerData['selected_logo_url'] ??
            '')
        .toString();
    FlavorConfig.applyTenaxBrokerRuntimeConfig(
      config: runtimeConfig,
      brokerName: selectedName.isNotEmpty ? selectedName : null,
      brokerLogoUrl: selectedLogo.isNotEmpty ? selectedLogo : null,
      brokerData: brokerData,
    );

    // 2. Save broker selection
    await SecureStorageService.saveTenaxBrokerSelection(brokerData);

    // 3. Restore this profile's auth token
    final loginData = profile['login_data'];
    if (loginData is Map) {
      final token = (loginData['token'] ?? '').toString();
      final wsToken = (loginData['websocket_token'] ?? '').toString();
      final userData = loginData['user'];
      if (token.isNotEmpty) {
        await SecureStorageService.saveAuthToken(token);
        await SecureStorageService.saveWebsocketToken(wsToken);
        if (userData is Map<String, dynamic>) {
          await SecureStorageService.saveUserData(
            jsonEncode({
              'token': token,
              'websocket_token': wsToken,
              'user': userData,
              'is_logged_in': true,
            }),
          );
        }
        await SecureStorageService.saveLoginStatus(true);
      }
    }

    // 4. Mark this as current profile
    await SecureStorageService.setTenaxCurrentProfileKey(
      (profile['profile_key'] ?? '').toString(),
    );

    // 5. Refresh branding
    Get.find<LanguageService>().brandingUpdateIndex.value++;

    // 6. Navigate to trading
    Get.offAllNamed(AppPages.TRADING);
  }

  /// Shows a bottom sheet listing all other saved profiles to switch to.
  void _showProfilePickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Switch to saved account',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.border,
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
            Divider(height: 20.h, color: AppColors.border),
            ..._otherProfiles.map(
              (profile) => InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 120));
                  await _switchToProfile(profile);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18.r,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.person,
                          size: 18.r,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (profile['user_name'] ?? '').toString(),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              (profile['user_email'] ?? '').toString(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textGrey,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Broker: ${(profile['broker_name'] ?? '').toString()}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textGrey.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14.sp,
                        color: AppColors.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  /// Builds the "Back to previous account" button/link shown below the login button.
  Widget _buildBackToPreviousAccountButton() {
    if (!_multibrokerEnabled || _otherProfiles.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_otherProfiles.length == 1) {
      final p = _otherProfiles.first;
      final name = (p['user_name'] ?? '').toString();
      final broker = (p['broker_name'] ?? '').toString();
      final label = name.isNotEmpty
          ? '← Back to $name${broker.isNotEmpty ? ' ($broker)' : ''}'
          : '← Back to previous account';
      return TextButton(
        onPressed: () => _switchToProfile(p),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      );
    }

    // Multiple profiles → show picker sheet
    return TextButton(
      onPressed: _showProfilePickerSheet,
      child: Text(
        '← Back to previous account',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
    );
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
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            languageService.tr('biometric_not_enabled_title'),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            languageService.tr('biometric_not_enabled_message'),
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                languageService.tr('common_close'),
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await BiometricService.instance.openDeviceSecuritySettings();
              },
              child: Text(
                languageService.tr('biometric_open_settings'),
                style: TextStyle(color: AppColors.primary),
              ),
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
            checkColor: AppColors.whiteColor,
            side: BorderSide(color: AppColors.textGrey, width: 1.5),
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
      backgroundColor: AppColors.background,
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
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
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
                                        color: AppColors.textGrey,
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
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 35.h),
                                  _buildEnableBiometricAfterLoginCheckbox(),
                                  SizedBox(height: 12.h),
                                  Obx(() {
                                    final isLoading = authController.isLoading;
                                    return AdaptiveAppButton(
                                      label: languageService.tr("login_button"),
                                      onPressed: _handleLogin,
                                      isLoading: isLoading,
                                      height: 40.h,
                                      borderRadius: BorderRadius.circular(10.r),
                                      textStyle: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.whiteColor,
                                      ),
                                    );
                                  }),
                                  SizedBox(height: 8.h),
                                  _buildBackToPreviousAccountButton(),
                                  SizedBox(height: 8.h),
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
                          style: TextStyle(
                            color: AppColors.textGrey,
                          ),
                          children: [
                            TextSpan(
                              text: languageService.tr("login_register"),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
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
