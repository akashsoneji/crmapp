import 'package:flutter/material.dart';

enum Flavor { pipze, octa, fleza, onsa }

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String appTitle;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String apiBaseUrl;
  final String appIconPath;

  static FlavorConfig? _instance;

  factory FlavorConfig({
    required Flavor flavor,
    required String appName,
    required String appTitle,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
    required String apiBaseUrl,
    required String appIconPath,
  }) {
    _instance ??= FlavorConfig._internal(
      flavor: flavor,
      appName: appName,
      title: appTitle,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      accentColor: accentColor,
      apiBaseUrl: apiBaseUrl,
      appIconPath: appIconPath,
    );
    return _instance!;
  }

  FlavorConfig._internal({
    required this.flavor,
    required String title,
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.apiBaseUrl,
    required this.appIconPath,
  }) : appTitle = title;

  static FlavorConfig get instance {
    return _instance ?? FlavorConfig.pipze;
  }

  static bool isProduction() => _instance?.flavor == Flavor.pipze;
  static bool isDevelopment() => _instance?.flavor == Flavor.octa;
  static bool isStaging() => _instance?.flavor == Flavor.fleza;
  static bool isONSA() => _instance?.flavor == Flavor.onsa;

  // Predefined configurations for each flavor
  static FlavorConfig get pipze => FlavorConfig(
    flavor: Flavor.pipze,
    appName: 'Pipze',
    appTitle: 'Pipze Trading',
    primaryColor: const Color(0xff5F259E),
    secondaryColor: const Color(0xFFF8F3FF),
    accentColor: const Color(0xFFFFC93C),
    apiBaseUrl: 'https://api.pipze.com',
    appIconPath: 'assets/image/splash_logo.png',
  );

  static FlavorConfig get octa => FlavorConfig(
    flavor: Flavor.octa,
    appName: 'Octa',
    appTitle: 'Octa Trading',
    primaryColor: const Color(0xFFFF6B35),
    secondaryColor: const Color(0xFFFFF3E0),
    accentColor: const Color(0xFFE65100),
    apiBaseUrl: 'https://api.octa.com',
    appIconPath: 'assets/image/octa_launcher.png',
  );

  static FlavorConfig get fleza => FlavorConfig(
    flavor: Flavor.fleza,
    appName: 'Fleza',
    appTitle: 'Fleza Trading',
    primaryColor: const Color(0xFF4CAF50),
    secondaryColor: const Color(0xFFE8F5E8),
    accentColor: const Color(0xFF2E7D32),
    apiBaseUrl: 'https://api.fleza.com',
    appIconPath: 'assets/image/fleza_launcher.png',
  );

  static FlavorConfig get onsa => FlavorConfig(
    flavor: Flavor.onsa,
    appName: 'ONSA',
    appTitle: 'ONSA Trading',
    primaryColor: const Color(0xFF193FAD),
    secondaryColor: const Color(0xFFE8F5E8),
    accentColor: const Color(0xFF193FAD),
    apiBaseUrl: 'https://demo.procrm.live/api/',
    appIconPath: 'assets/image/onsa_logo.png',
  );
}
