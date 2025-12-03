import 'package:flutter/material.dart';
import 'flavor_config.dart';

/// Brand Switcher Utility
///
/// This class provides easy methods to switch between different brands
/// and get their configurations.
class BrandSwitcher {
  /// Switch to Pipze brand (Purple theme)
  static void switchToPipze() {
    FlavorConfig.pipze;
    debugPrint('🎨 Switched to Pipze brand (Purple theme)');
    debugPrint('   Primary Color: ${FlavorConfig.instance.primaryColor}');
    debugPrint('   App Name: ${FlavorConfig.instance.appName}');
    debugPrint(
      '   🟣 Colors: Purple #5A2DD8, Secondary #F8F3FF, Accent #9C27B0',
    );
  }

  /// Switch to Octa brand (Orange theme)
  static void switchToOcta() {
    FlavorConfig.octa;
    debugPrint('🎨 Switched to Octa brand (Orange theme)');
    debugPrint('   Primary Color: ${FlavorConfig.instance.primaryColor}');
    debugPrint('   App Name: ${FlavorConfig.instance.appName}');
    debugPrint(
      '   🟠 Colors: Orange #FF6B35, Secondary #FFF3E0, Accent #E65100',
    );
  }

  /// Switch to Fleza brand (Green theme)
  static void switchToFleza() {
    FlavorConfig.tenax;
    debugPrint('🎨 Switched to Fleza brand (Green theme)');
    debugPrint('   Primary Color: ${FlavorConfig.instance.primaryColor}');
    debugPrint('   App Name: ${FlavorConfig.instance.appName}');
    debugPrint(
      '   🟢 Colors: Green #4A0C54 , Secondary #E8F5E8, Accent #2E7D32',
    );
  }

  /// Switch to ONSA brand (Blue theme)
  static void switchToONSA() {
    FlavorConfig.onsa;
    debugPrint('🎨 Switched to ONSA brand (Blue theme)');
    debugPrint('   Primary Color: ${FlavorConfig.instance.primaryColor}');
    debugPrint('   App Name: ${FlavorConfig.instance.appName}');
    debugPrint('   🔵 Colors: Blue #193FAD, Secondary #1E2244, Accent #193FAD');
  }

  /// Switch to AFX brand (Navy theme)
  static void switchToAFX() {
    FlavorConfig.afx;
    debugPrint('🎨 Switched to AFX brand (Navy theme)');
    debugPrint('   Primary Color: ${FlavorConfig.instance.primaryColor}');
    debugPrint('   App Name: ${FlavorConfig.instance.appName}');
    debugPrint('   🔷 Colors: Navy #182430, Secondary #E8F0F5, Accent #182430');
  }

  /// Get current brand info
  static void printCurrentBrand() {
    debugPrint('🎯 Current Brand: ${FlavorConfig.instance.appName}');
    debugPrint('   Primary Color: ${FlavorConfig.instance.primaryColor}');
    debugPrint('   Secondary Color: ${FlavorConfig.instance.secondaryColor}');
    debugPrint('   Accent Color: ${FlavorConfig.instance.accentColor}');
    debugPrint('   App Title: ${FlavorConfig.instance.appTitle}');
  }

  /// Check if current brand is Pipze
  static bool get isPipze => FlavorConfig.instance.flavor == Flavor.pipze;

  /// Check if current brand is Octa
  static bool get isOcta => FlavorConfig.instance.flavor == Flavor.octa;

  /// Check if current brand is Fleza
  static bool get isTenax => FlavorConfig.instance.flavor == Flavor.tenax;

  /// Check if current brand is ONSA
  static bool get isONSA => FlavorConfig.instance.flavor == Flavor.onsa;

  /// Check if current brand is AFX
  static bool get isAFX => FlavorConfig.instance.flavor == Flavor.afx;

  /// Get current brand name
  static String get currentBrandName => FlavorConfig.instance.appName;

  /// Get current brand color
  static Color get currentBrandColor => FlavorConfig.instance.primaryColor;

  /// Get all brand colors for current brand
  static Map<String, Color> get currentBrandColors => {
    'primary': FlavorConfig.instance.primaryColor,
    'secondary': FlavorConfig.instance.secondaryColor,
    'accent': FlavorConfig.instance.accentColor,
  };

  /// Quick brand switching with hot reload
  static void quickSwitchBrand() {
    if (isPipze) {
      switchToOcta();
    } else if (isOcta) {
      switchToFleza();
    } else if (isTenax) {
      switchToONSA();
    } else if (isONSA) {
      switchToAFX();
    } else {
      switchToPipze();
    }
    debugPrint('🔄 Quick switched to next brand!');
  }
}
