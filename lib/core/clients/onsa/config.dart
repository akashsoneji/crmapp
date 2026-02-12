import 'package:flutter/material.dart';
import '../base_config.dart';

/// ONSA client configuration
class OnsaConfig extends BaseClientConfig {
  const OnsaConfig()
    : super(
        brandName: 'ONSA',
        appTitle: 'ONSA Trading',
        primaryColor: const Color(0xFF193FAD),
        secondaryColor: const Color(0xFFE8F5E8),
        accentColor: const Color(0xFF193FAD),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://member.onsamarket.com/api/',
        websocketUrl: 'wss://member.onsamarket.com/trade-engine',
        chartBaseUrl: 'https://member.onsamarket.com',
      );
}
