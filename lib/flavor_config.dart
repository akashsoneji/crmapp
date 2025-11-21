import 'package:flutter/material.dart';

enum Flavor { pipze, octa, tenax, onsa, profx }

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String appTitle;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String apiBaseUrl;
  final String chartBaseUrl;
  final String websocketUrl;
  final String appIconPath;
  final String svgLogoPath;

  static FlavorConfig? _instance;
  static Flavor? _selectedFlavor;

  factory FlavorConfig({
    required Flavor flavor,
    required String appName,
    required String appTitle,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
    required String apiBaseUrl,
    required String websocketUrl,
    required String chartBaseUrl,
    required String appIconPath,
    required String svgLogoPath,
  }) {
    // If no flavor is selected yet, or if the flavor matches the selected one, initialize it
    if (_selectedFlavor == null || _selectedFlavor == flavor) {
      _instance = FlavorConfig._internal(
        flavor: flavor,
        appName: appName,
        title: appTitle,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        accentColor: accentColor,
        apiBaseUrl: apiBaseUrl,
        websocketUrl: websocketUrl,
        chartBaseUrl: chartBaseUrl,
        appIconPath: appIconPath,
        svgLogoPath: svgLogoPath,
      );
      _selectedFlavor = flavor;
    }
    return _instance!;
  }

  /// Reset the flavor configuration (useful for testing or switching flavors)
  static void reset() {
    _instance = null;
    _selectedFlavor = null;
  }

  FlavorConfig._internal({
    required this.flavor,
    required String title,
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.apiBaseUrl,
    required this.websocketUrl,
    required this.chartBaseUrl,
    required this.appIconPath,
    required this.svgLogoPath,
  }) : appTitle = title;

  static FlavorConfig get instance {
    return _instance ?? FlavorConfig.pipze;
  }

  static bool isProduction() => _instance?.flavor == Flavor.pipze;
  static bool isDevelopment() => _instance?.flavor == Flavor.octa;
  static bool isTenax() => _instance?.flavor == Flavor.tenax;
  static bool isONSA() => _instance?.flavor == Flavor.onsa;
  static bool isProfx() => _instance?.flavor == Flavor.profx;
  static String get svgLogoAsset => instance.svgLogoPath;

  // Predefined configurations for each flavor
  // These getters will initialize the flavor when called
  static FlavorConfig get pipze {
    _selectedFlavor = Flavor.pipze;
    return FlavorConfig(
      flavor: Flavor.pipze,
      appName: 'Pipze',
      appTitle: 'Pipze Trading',
      primaryColor: const Color(0xff5F259E),
      secondaryColor: const Color(0xFFF8F3FF),
      accentColor: const Color(0xFFFFC93C),
      apiBaseUrl: 'https://my.pipze.com/api/',
      websocketUrl: 'wss://my.pipze.com:8080',
      chartBaseUrl: 'https://my.pipze.com',
      // websocketUrl: 'ws://136.243.230.187:6001/?api_key=MT5_Broker1_Key_2024_01',
      appIconPath: 'assets/image/splash_logo.png',
      svgLogoPath: 'assets/svg/splash_logo.svg',
    );
  }

  static FlavorConfig get octa {
    _selectedFlavor = Flavor.octa;
    return FlavorConfig(
      flavor: Flavor.octa,
      appName: 'Octa',
      appTitle: 'Octa Trading',
      primaryColor: const Color(0xFFFF6B35),
      secondaryColor: const Color(0xFFFFF3E0),
      accentColor: const Color(0xFFE65100),
      apiBaseUrl: 'https://api.octa.com',
      websocketUrl: 'wss://api.octa.com',
      chartBaseUrl: 'https://api.octa.com',
      appIconPath: 'assets/image/octa_launcher.png',
      svgLogoPath: 'assets/svg/octa_logo.svg',
    );
  }

  static FlavorConfig get tenax {
    _selectedFlavor = Flavor.tenax;
    return FlavorConfig(
      flavor: Flavor.tenax,
      appName: 'Tenax',
      appTitle: 'Tenax Code',
      primaryColor: const Color(0xFF4A0C54),
      secondaryColor: const Color(0xFFE8F5E8),
      accentColor: const Color(0xFF4A0C54),
      // websocketUrl: 'wss://demo.tenaxcode.com:3001',
      websocketUrl: 'wss://demo.tenaxcode.com/trade-engine',
      chartBaseUrl: 'https://demo.tenaxcode.com',
      apiBaseUrl: 'https://demo.tenaxcode.com/api/',

      // websocketUrl: 'wss://demo.procrm.live:8080',
      appIconPath: 'assets/tenaxCode/splash_tenax.svg',
      svgLogoPath: 'assets/svg/tenax_logo.svg',
    );
  }

  static FlavorConfig get onsa {
    _selectedFlavor = Flavor.onsa;
    return FlavorConfig(
      flavor: Flavor.onsa,
      appName: 'ONSA',
      appTitle: 'ONSA Trading',
      primaryColor: const Color(0xFF193FAD),
      secondaryColor: const Color(0xFFE8F5E8),
      accentColor: const Color(0xFF193FAD),
      // apiBaseUrl: 'https://my.pipze.com/api/',
      // websocketUrl: 'wss://my.pipze.com:8080',
      // websocketUrl: 'ws://136.243.230.187:6001/?api_key=MT5_Broker1_Key_2024_01',
      websocketUrl: 'ws://136.243.230.187:6002/?api_key=Onsa@Master@1234',
      chartBaseUrl: 'https://demo.procrm.live',
      apiBaseUrl: 'https://demo.procrm.live/api/',

      // websocketUrl: 'wss://demo.procrm.live:8080',
      appIconPath: 'assets/image/onsa_logo.png',
      svgLogoPath: 'assets/svg/onsa_logo.svg',
    );
  }

  static FlavorConfig get profx {
    _selectedFlavor = Flavor.profx;
    return FlavorConfig(
      flavor: Flavor.profx,
      appName: 'ProFX',
      appTitle: 'ProFX Trading',
      primaryColor: const Color(0xFF0D7064),
      secondaryColor: const Color(0xFFE6F5F2),
      accentColor: const Color(0xFF132E37),
      apiBaseUrl: 'https://demo.tenaxcode.com/api/',
      websocketUrl: 'wss://demo.tenaxcode.com/trade-engine',
      chartBaseUrl: 'https://demo.tenaxcode.com',
      appIconPath: 'assets/profx/profx.svg',
      svgLogoPath: 'assets/profx/profx.svg',
    );
  }
}
