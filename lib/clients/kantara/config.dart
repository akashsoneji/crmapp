import 'package:flutter/material.dart';
import '../base_config.dart';

/// Kantara client configuration
class KantaraConfig extends BaseClientConfig {
  const KantaraConfig()
    : super(
        brandName: 'Kantara',
        appTitle: 'Kantara',
        primaryColor: const Color(0xFF2E2174),
        secondaryColor: const Color(0xFF4AAF46),
        accentColor: const Color(0xFF2E2174),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://member.kantaracapital.io/api/',
        websocketUrl: 'wss://member.kantaracapital.io/trade-engine',
        chartBaseUrl: 'https://member.kantaracapital.io',
      );
}


