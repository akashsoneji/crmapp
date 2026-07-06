import 'package:avatar_glow/avatar_glow.dart';
import 'package:crm_app/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/widgets/brand_logo.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../flavor_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 1), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _restoreBrokerConfig() async {
    if (!FlavorConfig.isMultiBrokerEnabled) return;
    try {
      final saved = await SecureStorageService.getTenaxBrokerSelection();
      if (saved == null) return;
      final runtimeConfig =
          (saved['broker_runtime_config'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final logoLocalPath = saved['selected_logo_local_path'] as String?;
      final brokerName = (saved['selected_name'] ?? '').toString();
      FlavorConfig.applyTenaxBrokerRuntimeConfig(
        config: runtimeConfig,
        brokerName: brokerName.isNotEmpty ? brokerName : null,
        brokerLogoUrl:
            logoLocalPath?.isNotEmpty == true
                ? logoLocalPath
                : (saved['selected_logo_url'] ?? '').toString(),
        brokerData: saved,
      );
      print(
        'SplashScreen: Broker config restored → API: ${ApiConstants.baseUrl}',
      );
    } catch (e) {
      print('SplashScreen: Error restoring broker config: $e');
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // ── Tenax flavor: show broker selection only when user is NOT logged in ─
      if (FlavorConfig.isMultiBrokerEnabled &&
          await SecureStorageService.getTenaxBrokerSelectionFlag()) {
        final isLoggedIn = await SecureStorageService.isUserLoggedIn();
        final hasBrokerSelection =
            await SecureStorageService.hasTenaxBrokerSelection();

        // ✅ FIX: Never show broker selection if the user is logged in.
        // Use isLoggedIn as primary check. Even if the marker was reset after
        // an app update, a logged-in user should go straight to their app.
        final shouldShowBrokerSelection =
            !isLoggedIn &&
            !(FlavorConfig.isTenaxBrokerDemoEnabled && hasBrokerSelection);

        if (shouldShowBrokerSelection) {
          print(
            'SplashScreen: Tenax – user not logged in, showing broker selection',
          );
          Get.offAllNamed(
            AppPages.TENAX_BROKER_SELECTION,
            arguments: {'allowBack': false},
          );
          return;
        }
        // Logged in → restore broker config so URLs/colors are correct
        await _restoreBrokerConfig();
      }

      // ── Normal auth flow ─────────────────────────────────────────────────
      final isLoggedIn = await SecureStorageService.isUserLoggedIn();
      print('SplashScreen: User login status: $isLoggedIn');

      if (isLoggedIn) {
        print('SplashScreen: Validating authentication token...');
        await authController.checkAuthStatus();
        await Future.delayed(const Duration(milliseconds: 100));

        if (authController.isAuthenticated) {
          // ✅ Step 6: Log the active Tenax profile_key for debugging the
          // multi-user (email+slug) identity layer.
          try {
            final activeKey =
                await SecureStorageService.getTenaxCurrentProfileKey();
            print('SplashScreen: Active Tenax profile_key = $activeKey');
          } catch (_) {}
          print('SplashScreen: User authenticated → Trading screen');
          // ✅ Fetch MT5 accounts in background immediately at app launch.
          // Don't await — let navigation proceed instantly while data loads.
          Future.microtask(() async {
            try {
              final DashboardController dc;
              if (Get.isRegistered<DashboardController>()) {
                dc = Get.find<DashboardController>();
              } else {
                dc = Get.put<DashboardController>(
                  DashboardController(),
                  permanent: true,
                );
              }
              await dc.forceCheckMT5Accounts();
              print('SplashScreen: MT5 accounts prefetched at launch');
            } catch (e) {
              print('SplashScreen: Error prefetching MT5 accounts: $e');
            }
          });
          Get.offAllNamed(AppPages.TRADING);
        } else {
          print('SplashScreen: Token invalid → auth entry screen');
          await SecureStorageService.clearAuthData();
          final shouldGoToLogin =
              FlavorConfig.isTenaxBrokerDemoEnabled &&
              await SecureStorageService.hasTenaxBrokerSelection();
          Get.offAllNamed(
            shouldGoToLogin ? AppPages.LOGIN : AppPages.GET_STARTED,
          );
        }
      } else {
        print('SplashScreen: Not logged in → auth entry screen');
        final shouldGoToLogin =
            FlavorConfig.isTenaxBrokerDemoEnabled &&
            await SecureStorageService.hasTenaxBrokerSelection();
        Get.offAllNamed(
          shouldGoToLogin ? AppPages.LOGIN : AppPages.GET_STARTED,
        );
      }
    } catch (e) {
      print('SplashScreen: Error checking auth status: $e');
      try {
        await SecureStorageService.clearAuthData();
      } catch (clearError) {
        print('SplashScreen: Error clearing storage: $clearError');
      }
      final shouldGoToLogin =
          FlavorConfig.isTenaxBrokerDemoEnabled &&
          await SecureStorageService.hasTenaxBrokerSelection();
      Get.offAllNamed(shouldGoToLogin ? AppPages.LOGIN : AppPages.GET_STARTED);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if it's ONSA flavor for gradient background
    final bool isONSA = FlavorConfig.isONSA();
    final bool isTenax = FlavorConfig.isTenax();
    final bool isProfx = FlavorConfig.isProfx();
    final bool isAFX = FlavorConfig.isAFX();

    final splashLogoSource =
        FlavorConfig.hasRemoteLogo
            ? FlavorConfig.effectiveLogo
            : FlavorConfig.instance.splashLogoPath;
    return Scaffold(
      body: _buildBackground(isONSA, isTenax, isProfx, isAFX, splashLogoSource),
    );
  }

  Widget _buildBackground(
    bool isONSA,
    bool isTenax,
    bool isProfx,
    bool isAFX,
    String splashLogoSource,
  ) {
    if (isONSA) {
      // ONSA uses gradient background
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF193FAD), // Top Left
              const Color(0xFF1E2244), // Bottom Right
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: _buildSplashLogo(
                  splashLogoSource,
                  height: 30,
                  width: 60,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isTenax) {
      // Tenax uses gradient background
      return Container(
        decoration: BoxDecoration(
          //
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: _buildSplashLogo(
                  splashLogoSource,
                  height: 30,
                  width: 60,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isProfx) {
      // ProFX uses gradient background
      return Container(
        // color: FlavorConfig.instance.,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: _buildSplashLogo(
                  splashLogoSource,
                  height: 30,
                  width: 60,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isAFX) {
      // AFX uses solid background with brand color
      return Container(
        color: FlavorConfig.instance.primaryColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: _buildSplashLogo(
                  splashLogoSource,
                  height: 60,
                  width: 90,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Other flavors (app, etc.) use solid background with brand color and glow effect
      return Container(
        color: FlavorConfig.instance.primaryColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: AvatarGlow(
                startDelay: const Duration(milliseconds: 1000),
                glowColor: AppColors.whiteColor,
                glowShape: BoxShape.circle,
                animate: true,
                curve: Curves.fastOutSlowIn,
                child: SizedBox(
                  height: 250,
                  width: 250,
                  child: _buildSplashLogo(
                    splashLogoSource,
                    height: 60,
                    width: 90,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSplashLogo(String path, {double? height, double? width}) {
    return BrandLogo(source: path, height: height, width: width);
  }
}
