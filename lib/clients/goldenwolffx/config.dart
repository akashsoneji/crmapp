import 'package:flutter/material.dart';
import '../base_config.dart';

/// Goldenwolffx client configuration
class GoldenwolffxConfig extends BaseClientConfig {
  const GoldenwolffxConfig()
    : super(
        brandName: 'Goldenwolffx',
        appTitle: 'Goldenwolffx',
        primaryColor: const Color(0xFFD4A843),
        secondaryColor: const Color(0xFFF8F3FF),
        accentColor: const Color(0xFFFFC93C),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://goldenwolffx.alibabafx.com/api/',
        websocketUrl: 'wss://goldenwolffx.alibabafx.com/trade-engine',
        chartBaseUrl: 'https://goldenwolffx.alibabafx.com',
      );
}
