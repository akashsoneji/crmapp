import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pipze/services/secure_storage_service.dart';
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
        // User is logged in, trigger auth check in controller
        await authController.checkAuthStatus();

        // Navigate to trading screen
        Get.offAllNamed(AppPages.TRADING);
      } else {
        // User is not logged in, navigate to get started screen
        Get.offAllNamed(AppPages.GET_STARTED);
      }
    } catch (e) {
      print('SplashScreen: Error checking auth status: $e');
      // On error, navigate to get started screen
      Get.offAllNamed(AppPages.GET_STARTED);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if it's ONSA flavor for gradient background
    final bool isONSA = FlavorConfig.isONSA();

    return Scaffold(body: _buildBackground(isONSA));
  }

  Widget _buildBackground(bool isONSA) {
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
                  'assets/svg/onsa/splash_onsa.svg',
                  height: 30,
                  width: 60,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Other flavors use solid background with brand color
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
                  child: SvgPicture.asset(
                    'assets/svg/splash_logo.svg',
                    height: 60,
                    width: 90,
                  ),
                ),
              ),
            ),

            // Brand Test Button (for development)
            //   const SizedBox(height: 20),
            //   ElevatedButton(
            //     onPressed: () {
            //       Get.toNamed(AppPages.BRAND_TEST);
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.white,
            //       foregroundColor: const Color(0xFF692EAF),
            //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //     ),
            //     child: const Text('🎨 Test Brand Colors'),
            //   ),
          ],
        ),
      );
    }
  }
}
