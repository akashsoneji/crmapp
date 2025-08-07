import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pipze/services/secure_storage_service.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';

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

    Future.delayed(const Duration(seconds: 3), () {
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
    return Scaffold(
      backgroundColor: const Color(0xFF692EAF),
      body: Column(
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
        ],
      ),
    );
  }
}
