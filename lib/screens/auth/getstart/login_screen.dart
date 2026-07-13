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
import '../../../controllers/tenax_broker_selection_controller.dart';
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

  // ── HOME-RESTORE SUPPORT ────────────────────────────────────────────
  // When the user is routed to this screen from a logged-in session (e.g.
  // MoreScreen → Switch Account → Add another account on the same broker),
  // we show a Home button at the top-left. Tapping it restores the previous
  // session from the snapshot embedded in route arguments, so the user can
  // bounce back to TRADING without losing their current login.
  //
  // The Home button shows whenever there is an active session: either
  // explicitly passed in via `cameFromLoggedInSession:true` (from the
  // broker selection flow with a shadow snapshot) OR detected at
  // initState time by checking secure storage. This covers both the
  // multi-account "add new broker" flow and edge cases where the user
  // lands on this screen directly while a session is alive in storage.
  bool _cameFromLoggedInSession = false;
  String? _shadowAuthToken;
  String? _shadowWsToken;
  String? _shadowUserDataJson;
  /// Branding (color, logo, app name, URLs) that was active *before* the
  /// user opened this screen. Captured in initState so the Home button
  /// can restore the previous broker's branding when the user changes
  /// their mind and goes back to the previously-logged-in session.
  FlavorConfig? _previousBranding;

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

    final args = Get.arguments;
    if (args is Map) {
      _cameFromLoggedInSession = args['cameFromLoggedInSession'] == true;
      _shadowAuthToken = args['shadowAuthToken'] as String?;
      _shadowWsToken = args['shadowWsToken'] as String?;
      _shadowUserDataJson = args['shadowUserDataJson'] as String?;
    }
    // If we were not explicitly told we came from a logged-in session,
    // still show the Home button if storage says the user is logged in.
    // The snapshot fields are populated by `_restoreSessionAndExit` on
    // demand (it reads storage directly).
    if (!_cameFromLoggedInSession) {
      SecureStorageService.isUserLoggedIn().then((loggedIn) {
        if (!mounted || !loggedIn) return;
        setState(() {
          _cameFromLoggedInSession = true;
        });
      });
    }
    // Do NOT auto-trigger biometric login when the user is intentionally
    // trying to add a new account from a logged-in session. The old token
    // is still in storage (we're using a shadow snapshot); biometric would
    // silently log them back into the previous session and discard the
    // staged broker.
    SecureStorageService.isUserLoggedIn().then((loggedIn) {
      if (!_cameFromLoggedInSession && !loggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryBiometricLogin();
        });
      }
    });
  }

  @override
  void dispose() {
    // Clear any staged broker so a system-back / cancel from this screen
    // does NOT leak branding across cold starts.
    try {
      TenaxBrokerSelectionController.clearPendingBroker();
    } catch (_) {}
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

      // 1) Restore branding FIRST so any reactive widget reading the old
      //    color / logo sees the rollback before we navigate.
      FlavorConfig.restoreBranding(_previousBranding);
      try {
        if (Get.isRegistered<LanguageService>()) {
          Get.find<LanguageService>().brandingUpdateIndex.value++;
        }
      } catch (_) {}

      // 2) Restore the previous session into secure storage so TRADING
      //    boots with the right user.
      await SecureStorageService.saveAuthToken(token);
      if (wsToken != null && wsToken.isNotEmpty) {
        await SecureStorageService.saveWebsocketToken(wsToken);
      }
      if (userJson != null && userJson.isNotEmpty) {
        await SecureStorageService.saveUserData(userJson);
        try {
          final decoded = jsonDecode(userJson);
          if (decoded is Map && decoded['user'] is Map<String, dynamic>) {
            await Get.find<AuthController>().getUserData();
          }
        } catch (_) {}
      }
      await SecureStorageService.saveLoginStatus(true);

      // 3) Clear the staged broker so a future broker pick doesn't see
      //    stale in-memory staging.
      try {
        TenaxBrokerSelectionController.clearPendingBroker();
      } catch (_) {}

      Get.offAllNamed(AppPages.TRADING);
    } catch (e) {
      print('LoginScreen: Failed to restore session: $e');
      Get.offAllNamed(AppPages.GET_STARTED);
    }
  }

  /// Forward the snapshot args to the next screen so the Home button stays
  /// visible when the user taps "Create Account" from here.
  Map<String, dynamic>? _forwardedShadowArgs() {
    if (!_cameFromLoggedInSession &&
        (_shadowAuthToken == null || _shadowAuthToken!.isEmpty) &&
        (_shadowWsToken == null || _shadowWsToken!.isEmpty) &&
        (_shadowUserDataJson == null || _shadowUserDataJson!.isEmpty)) {
      return null;
    }
    return <String, dynamic>{
      'cameFromLoggedInSession': _cameFromLoggedInSession,
      'shadowAuthToken': _shadowAuthToken,
      'shadowWsToken': _shadowWsToken,
      'shadowUserDataJson': _shadowUserDataJson,
    };
  }

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
      appBar: _cameFromLoggedInSession
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.home_outlined),
                color: AppColors.textPrimary,
                tooltip: 'Back to home',
                onPressed: _restoreSessionAndExit,
              ),
            )
          : null,
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
                                        color: AppColors.isDarkMode ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
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
                        Get.toNamed(
                          AppPages.CREATE_ACCOUNT,
                          arguments: _forwardedShadowArgs(),
                        );
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
