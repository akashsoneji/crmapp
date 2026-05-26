import 'package:flutter/material.dart';
import '../base_config.dart';

/// Amirifx client configuration
class AmirifxConfig extends BaseClientConfig {
  const AmirifxConfig()
    : super(
        brandName: 'Amirifx',
        appTitle: 'Amirifx Trading',
        primaryColor: const Color(0xFF0A1F44),
        secondaryColor: const Color(0xFFE8C25A),
        accentColor: const Color(0xFF0A1F44),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://my.pipze.com/api/',
        websocketUrl: 'wss://my.pipze.com/trade-engine',
        chartBaseUrl: 'https://my.pipze.com',
      );
}
