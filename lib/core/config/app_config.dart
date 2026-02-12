import 'package:flutter/material.dart';

// ========================================
// CHANGE ONLY THIS VALUE TO SWITCH BRANDS
// ========================================
enum AppBrand { pipze, octa, fleza, onsa }

const AppBrand currentBrand = AppBrand.octa;
// ========================================

class AppConfig {
  // Brand-specific configurations
  static const Map<AppBrand, Map<String, dynamic>> brandConfigs = {
    AppBrand.pipze: {
      'name': 'Pipze',
      'displayName': 'Pipze',
      'primaryColor': Color(0xFF5F259E), // Purple
      'secondaryColor': Color(0xFFF8F3FF), // Light Purple
      'accentColor': Color(0xFF9C27B0), // Dark Purple
      'launcherIcon': 'assets/image/splash_logo.png',
      'splashLogo': 'assets/image/splash_logo.png',
    },
    AppBrand.octa: {
      'name': 'octa',
      'displayName': 'Octa',
      'primaryColor': Color(0xFFFF6B35), // Orange
      'secondaryColor': Color(0xFFFFF3E0), // Light Orange
      'accentColor': Color(0xFFE65100), // Dark Orange
      'launcherIcon': 'assets/image/octa_launcher.png',
      'splashLogo': 'assets/image/octa_splash.png',
    },
    AppBrand.fleza: {
      'name': 'fleza',
      'displayName': 'Fleza',
      'primaryColor': Color(0xFF4CAF50), // Green
      'secondaryColor': Color(0xFFE8F5E8), // Light Green
      'accentColor': Color(0xFF2E7D32), // Dark Green
      'launcherIcon': 'assets/image/fleza_launcher.png',
      'splashLogo': 'assets/image/fleza_splash.png',
    },
    AppBrand.onsa: {
      'name': 'onsa',
      'displayName': 'ONSA',
      'primaryColor': Color(0xFF193FAD), // Blue
      'secondaryColor': Color(0xFF1E2244), // Dark Blue
      'accentColor': Color(0xFF193FAD), // Blue
      'launcherIcon': 'assets/image/onsa_logo.png',
      'splashLogo': 'assets/image/onsa_splash.png',
      'gradientStart': Color(0xFF193FAD), // Top Left
      'gradientEnd': Color(0xFF1E2244), // Bottom Right
    },
  };

  // Get current brand configuration
  static Map<String, dynamic> get currentBrandConfig =>
      brandConfigs[currentBrand] ?? brandConfigs[AppBrand.pipze]!;

  // Easy access to current brand properties
  static String get appName => currentBrandConfig['name'] as String;
  static String get displayName => currentBrandConfig['displayName'] as String;
  static Color get primaryColor => currentBrandConfig['primaryColor'] as Color;
  static Color get secondaryColor =>
      currentBrandConfig['secondaryColor'] as Color;
  static Color get accentColor => currentBrandConfig['accentColor'] as Color;
  static String get launcherIcon =>
      currentBrandConfig['launcherIcon'] as String;
  static String get splashLogo => currentBrandConfig['splashLogo'] as String;

  // Helper methods for colors with opacity
  static Color getPrimaryColorWithOpacity(double opacity) =>
      primaryColor.withOpacity(opacity);
  static Color getSecondaryColorWithOpacity(double opacity) =>
      secondaryColor.withOpacity(opacity);
}
