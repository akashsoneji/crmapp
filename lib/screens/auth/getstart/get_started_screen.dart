import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/utils/agreement_launcher.dart';
import 'package:crm_app/widgets/brand_logo.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/tenax_broker_selection_controller.dart';
import '../../../routes/app_pages.dart';

class GetStartedScreen extends StatefulWidget {
  GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final LanguageService languageService = Get.find<LanguageService>();

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
    if (!_cameFromLoggedInSession) {
      SecureStorageService.isUserLoggedIn().then((loggedIn) {
        if (!mounted || !loggedIn) return;
        setState(() {
          _cameFromLoggedInSession = true;
        });
      });
    }
  }

  @override
  void dispose() {
    try {
      TenaxBrokerSelectionController.clearPendingBroker();
    } catch (_) {}
    super.dispose();
  }

  Future<bool> _isTenaxBrokerFlowEnabled() async {
    if (!FlavorConfig.isMultiBrokerEnabled) return false;
    return await SecureStorageService.getTenaxBrokerSelectionFlag();
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
      print('GetStartedScreen: Failed to restore session: $e');
      Get.offAllNamed(AppPages.GET_STARTED);
    }
  }

  /// Forward the snapshot args to the next screen so the Home button stays
  /// visible when the user goes LOGIN or CREATE_ACCOUNT from here.
  Map<String, dynamic>? _forwardedArgs() {
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
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // SizedBox(height: 105.h),
                      Center(
                        child: BrandLogo(
                          source: FlavorConfig.effectiveLogo,
                          color:
                              FlavorConfig.isONSA() &&
                                      !FlavorConfig.hasRemoteLogo
                                  ? AppColors.primary
                                  : null,
                          height: 100.h,
                          width: 180.w,
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Text(
                        languageService.tr("onboarding_slide1_description"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 50.h),
                      SizedBox(
                        width: double.infinity,
                        height: 46.h,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.toNamed(
                              AppPages.LOGIN,
                              arguments: _forwardedArgs(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            // padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            languageService.tr("onboarding_get_started"),
                            style: TextStyle(color: AppColors.whiteColor),
                          ),
                        ),
                      ),
                      SizedBox(height: 15.h),
                      SizedBox(
                        width: double.infinity,
                        height: 46.h,
                        child: OutlinedButton(
                          onPressed: () {
                            Get.toNamed(
                              AppPages.CREATE_ACCOUNT,
                              arguments: _forwardedArgs(),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // padding: const EdgeInsets.all(14),
                          ),
                          child: Text(
                            languageService.tr("register_title"),
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      FutureBuilder<bool>(
                        future: _isTenaxBrokerFlowEnabled(),
                        builder: (context, snapshot) {
                          if (snapshot.data != true) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              TextButton(
                                onPressed: () {
                                  // if (Get.previousRoute ==
                                  //     AppPages.TENAX_BROKER_SELECTION) {
                                  //   Get.back();
                                  // } else {
                                  //   Get.offAllNamed(
                                  //     AppPages.TENAX_BROKER_SELECTION,
                                  //     arguments: {'allowBack': false},
                                  //   );
                                  // }
                                   Get.offAllNamed(
                                    AppPages.TENAX_BROKER_SELECTION,
                                    arguments: {'allowBack': false},
                                  );
                                },
                                child: Text(
                                  "Back to search",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: AppColors.textGrey),
                  text: "${languageService.tr("register_terms").tr}\n",
                  children: [
                    TextSpan(
                      text:
                          "${languageService.tr("register_terms_condition").tr}",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () => AgreementLauncher.openTerms(),
                    ),
                    const TextSpan(text: " and "),
                    TextSpan(
                      text: "${languageService.tr("privacy_policy_title").tr}",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () => AgreementLauncher.openPrivacy(),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
