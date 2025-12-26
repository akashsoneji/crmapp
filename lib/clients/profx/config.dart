import 'package:flutter/material.dart';
import '../base_config.dart';

/// ProFX client configuration
class ProfxConfig extends BaseClientConfig {
  const ProfxConfig()
    : super(
        brandName: 'ProFX',
        appTitle: 'ProFX Trading',
        primaryColor: const Color(0xFF0D7064),
        secondaryColor: const Color(0xFFE6F5F2),
        accentColor: const Color(0xFF132E37),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://demo.tenaxcode.com/api/',
        websocketUrl: 'wss://demo.tenaxcode.com/trade-engine',
        chartBaseUrl: 'https://demo.tenaxcode.com',
      );
}
