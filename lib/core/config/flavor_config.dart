import 'package:crm_app/core/clients/afx/config.dart';
import 'package:crm_app/core/clients/octa/config.dart';
import 'package:crm_app/core/clients/onsa/config.dart';
import 'package:crm_app/core/clients/pipze/config.dart';
import 'package:crm_app/core/clients/profx/config.dart';
import 'package:crm_app/core/clients/tenax/config.dart';
import 'package:crm_app/core/clients/tradoxy/config.dart';
import 'package:flutter/material.dart';
// import 'clients/afx/config.dart';
// import 'clients/pipze/config.dart';
// import 'clients/octa/config.dart';
// import 'clients/tenax/config.dart';
// import 'clients/onsa/config.dart';
// import 'clients/profx/config.dart';
// import 'clients/tradoxy/config.dart';

enum Flavor { pipze, octa, tenax, onsa, profx, afx, tradoxy }

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
  final String splashLogoPath; // Splash screen logo path

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
    required String splashLogoPath,
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
        splashLogoPath: splashLogoPath,
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
    required this.splashLogoPath,
  }) : appTitle = title;

  static FlavorConfig get instance {
    return _instance ?? FlavorConfig.pipze;
  }

  static bool isProduction() => _instance?.flavor == Flavor.pipze;
  static bool isDevelopment() => _instance?.flavor == Flavor.octa;
  static bool isTenax() => _instance?.flavor == Flavor.tenax;
  static bool isONSA() => _instance?.flavor == Flavor.onsa;
  static bool isProfx() => _instance?.flavor == Flavor.profx;
  static bool isAFX() => _instance?.flavor == Flavor.afx;
  static bool isTradoxy() => _instance?.flavor == Flavor.tradoxy;
  static String get svgLogoAsset => instance.svgLogoPath;
  static String get appNameDisplay => instance.appName;

  // Predefined configurations for each flavor
  // These getters will initialize the flavor when called
  static FlavorConfig get pipze {
    _selectedFlavor = Flavor.pipze;
    const config = PipzeConfig(); // Load centralized config
    return FlavorConfig(
      flavor: Flavor.pipze,
      appName: config.brandName,
      appTitle: config.appTitle,
      primaryColor: config.primaryColor,
      secondaryColor: config.secondaryColor,
      accentColor: config.accentColor,
      apiBaseUrl: config.apiBaseUrl,
      websocketUrl: config.websocketUrl,
      chartBaseUrl: config.chartBaseUrl,
      // websocketUrl: 'ws://136.243.230.187:6001/?api_key=MT5_Broker1_Key_2024_01',
      appIconPath: config.getAssetPath('pipze', config.appIconPath),
      svgLogoPath: config.getAssetPath('pipze', config.logoSvgPath),
      splashLogoPath: config.getAssetPath('pipze', config.splashLogoPath),
    );
  }

  static FlavorConfig get octa {
    _selectedFlavor = Flavor.octa;
    const config = OctaConfig(); // Load centralized config
    return FlavorConfig(
      flavor: Flavor.octa,
      appName: config.brandName,
      appTitle: config.appTitle,
      primaryColor: config.primaryColor,
      secondaryColor: config.secondaryColor,
      accentColor: config.accentColor,
      apiBaseUrl: config.apiBaseUrl,
      websocketUrl: config.websocketUrl,
      chartBaseUrl: config.chartBaseUrl,
      appIconPath:
          'assets/image/octa_launcher.png', // TODO: Move to centralized
      svgLogoPath: config.getAssetPath('octa', config.logoSvgPath),
      splashLogoPath: config.getAssetPath('octa', config.splashLogoPath),
    );
  }

  static FlavorConfig get tenax {
    _selectedFlavor = Flavor.tenax;
    const config = TenaxConfig(); // Load centralized config
    return FlavorConfig(
      flavor: Flavor.tenax,
      appName: config.brandName,
      appTitle: config.appTitle,
      primaryColor: config.primaryColor,
      secondaryColor: config.secondaryColor,
      accentColor: config.accentColor,
      websocketUrl: config.websocketUrl,
      chartBaseUrl: config.chartBaseUrl,
      apiBaseUrl: config.apiBaseUrl,
      appIconPath: config.getAssetPath('tenax', config.appIconPath),
      svgLogoPath: config.getAssetPath('tenax', config.logoSvgPath),
      splashLogoPath: config.getAssetPath('tenax', config.splashLogoPath),
    );
  }

  static FlavorConfig get onsa {
    _selectedFlavor = Flavor.onsa;
    const config = OnsaConfig(); // Load centralized config
    return FlavorConfig(
      flavor: Flavor.onsa,
      appName: config.brandName,
      appTitle: config.appTitle,
      primaryColor: config.primaryColor,
      secondaryColor: config.secondaryColor,
      accentColor: config.accentColor,
      websocketUrl: config.websocketUrl,
      chartBaseUrl: config.chartBaseUrl,
      apiBaseUrl: config.apiBaseUrl,
      appIconPath: 'assets/image/onsa_logo.png', // TODO: Move to centralized
      svgLogoPath: config.getAssetPath('onsa', config.logoSvgPath),
      splashLogoPath:
          'assets/svg/onsa/splash_onsa.svg', // TODO: Move to centralized
    );
  }

  static FlavorConfig get profx {
    _selectedFlavor = Flavor.profx;
    const config = ProfxConfig(); // Load centralized config
    return FlavorConfig(
      flavor: Flavor.profx,
      appName: config.brandName,
      appTitle: config.appTitle,
      primaryColor: config.primaryColor,
      secondaryColor: config.secondaryColor,
      accentColor: config.accentColor,
      apiBaseUrl: config.apiBaseUrl,
      websocketUrl: config.websocketUrl,
      chartBaseUrl: config.chartBaseUrl,
      appIconPath: 'assets/profx/profx.svg', // TODO: Move to centralized
      svgLogoPath: config.getAssetPath('profx', config.logoSvgPath),
      splashLogoPath: config.getAssetPath('profx', config.splashLogoPath),
    );
  }

  static FlavorConfig get afx {
    _selectedFlavor = Flavor.afx;
    const config = AfxConfig(); // Load centralized config
    return FlavorConfig(
      flavor: Flavor.afx,
      appName: config.brandName,
      appTitle: config.appTitle,
      primaryColor: config.primaryColor,
      secondaryColor: config.secondaryColor,
      accentColor: config.accentColor,
      apiBaseUrl: config.apiBaseUrl,
      websocketUrl: config.websocketUrl,
      chartBaseUrl: config.chartBaseUrl,
      appIconPath: config.getAssetPath('afx', config.appIconPath),
      svgLogoPath: config.getAssetPath('afx', config.logoSvgPath),
      splashLogoPath: config.getAssetPath('afx', config.splashLogoPath),
    );
  }

  static FlavorConfig get tradoxy {
    _selectedFlavor = Flavor.tradoxy;
    const config = TradoxyConfig(); // Load centralized config
    return FlavorConfig(
      flavor: Flavor.tradoxy,
      appName: config.brandName,
      appTitle: config.appTitle,
      primaryColor: config.primaryColor,
      secondaryColor: config.secondaryColor,
      accentColor: config.accentColor,
      apiBaseUrl: config.apiBaseUrl,
      websocketUrl: config.websocketUrl,
      chartBaseUrl: config.chartBaseUrl,
      appIconPath: config.getAssetPath('tradoxy', config.appIconPath),
      svgLogoPath: config.getAssetPath('tradoxy', config.logoSvgPath),
      splashLogoPath: config.getAssetPath('tradoxy', config.splashLogoPath),
    );
  }
}
