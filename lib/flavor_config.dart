import 'package:flutter/material.dart';

enum Flavor { pipze, octa, tenax, onsa }

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

  static FlavorConfig? _instance;

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
  }) {
    _instance ??= FlavorConfig._internal(
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
    required this.websocketUrl,
    required this.chartBaseUrl,
    required this.appIconPath,
  }) : appTitle = title;

  static FlavorConfig get instance {
    return _instance ?? FlavorConfig.pipze;
  }

  static bool isProduction() => _instance?.flavor == Flavor.pipze;
  static bool isDevelopment() => _instance?.flavor == Flavor.octa;
  static bool isTenax() => _instance?.flavor == Flavor.tenax;
  static bool isONSA() => _instance?.flavor == Flavor.onsa;

  // Predefined configurations for each flavor
  static FlavorConfig get pipze => FlavorConfig(
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
  );

  static FlavorConfig get octa => FlavorConfig(
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
  );

  static FlavorConfig get tenax => FlavorConfig(
    flavor: Flavor.tenax,
    appName: 'Tenax',
    appTitle: 'Tenax Code',
    primaryColor: const Color(0xFF4A0C54),
    secondaryColor: const Color(0xFFE8F5E8),
    accentColor: const Color(0xFF4A0C54),
    websocketUrl: 'ws://136.243.230.187:6002/?api_key=Onsa@Master@1234',
    chartBaseUrl: 'https://demo.tenaxcode.com',
    apiBaseUrl: 'https://demo.tenaxcode.com/api/',

    // websocketUrl: 'wss://demo.procrm.live:8080',
    appIconPath: 'assets/tenaxCode/splash_tenax.svg',
  );

  static FlavorConfig get onsa => FlavorConfig(
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
  );
}
