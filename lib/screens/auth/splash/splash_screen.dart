import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import '../../../controllers/auth_controller.dart';
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

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await SecureStorageService.isUserLoggedIn();
      print('SplashScreen: User login status: $isLoggedIn');

      if (isLoggedIn) {
        // User is logged in, validate token before navigating
        print('SplashScreen: Validating authentication token...');
        await authController.checkAuthStatus();

        // Wait a moment to ensure auth state is updated
        await Future.delayed(const Duration(milliseconds: 100));

        // Only navigate to trading if token is valid
        if (authController.isAuthenticated) {
          print(
            'SplashScreen: User is authenticated, navigating to Trading screen (Home)',
          );
          // Navigate to trading screen (main home screen with bottom navigation)
          // Using offAllNamed to clear navigation stack and prevent back navigation to splash
          Get.offAllNamed(AppPages.TRADING);
        } else {
          // Token validation failed, navigate to get started
          print(
            'SplashScreen: Token validation failed, navigating to Get Started',
          );
          // Clear any stale auth data
          await SecureStorageService.clearAuthData();
          Get.offAllNamed(AppPages.GET_STARTED);
        }
      } else {
        // User is not logged in, navigate to get started screen
        print('SplashScreen: User is not logged in, navigating to Get Started');
        Get.offAllNamed(AppPages.GET_STARTED);
      }
    } catch (e) {
      print('SplashScreen: Error checking auth status: $e');
      // On error, navigate to get started screen
      // Clear any potentially corrupted auth data
      try {
        await SecureStorageService.clearAuthData();
      } catch (clearError) {
        print('SplashScreen: Error clearing storage: $clearError');
      }
      Get.offAllNamed(AppPages.GET_STARTED);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if it's ONSA flavor for gradient background
    final bool isONSA = FlavorConfig.isONSA();
    final bool isTenax = FlavorConfig.isTenax();
    final bool isProfx = FlavorConfig.isProfx();
    final bool isAFX = FlavorConfig.isAFX();

    return Scaffold(body: _buildBackground(isONSA, isTenax, isProfx, isAFX));
  }

  Widget _buildBackground(bool isONSA, bool isTenax, bool isProfx, bool isAFX) {
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
                child: SvgPicture.asset(
                  FlavorConfig.instance.splashLogoPath, // Dynamic splash logo
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
                child: SvgPicture.asset(
                  FlavorConfig.instance.splashLogoPath, // Dynamic splash logo
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
                child: SvgPicture.asset(
                  FlavorConfig.instance.splashLogoPath, // Dynamic splash logo
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
                child: SvgPicture.asset(
                  FlavorConfig.instance.splashLogoPath, // Dynamic splash logo
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
                glowColor: Colors.white,
                glowShape: BoxShape.circle,
                animate: true,
                curve: Curves.fastOutSlowIn,
                child: SizedBox(
                  height: 250,
                  width: 250,
                  child: _buildSplashLogo(
                    FlavorConfig.instance.splashLogoPath,
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
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, height: height, width: width);
    } else {
      return Image.asset(
        path,
        height: height,
        width: width,
        fit: BoxFit.contain,
      );
    }
  }
}
