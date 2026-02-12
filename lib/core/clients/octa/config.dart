import 'package:flutter/material.dart';
import '../base_config.dart';

/// Octa client configuration
class OctaConfig extends BaseClientConfig {
  const OctaConfig()
    : super(
        brandName: 'Octa',
        appTitle: 'Octa Trading',
        primaryColor: const Color(0xFFFF6B35),
        secondaryColor: const Color(0xFFFFF3E0),
        accentColor: const Color(0xFFE65100),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://api.octa.com',
        websocketUrl: 'wss://api.octa.com',
        chartBaseUrl: 'https://api.octa.com',
      );
}
