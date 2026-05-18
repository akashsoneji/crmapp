import 'package:flutter/material.dart';
import '../base_config.dart';

/// Goldenwolffx client configuration
class GoldenwolffxConfig extends BaseClientConfig {
  const GoldenwolffxConfig()
    : super(
        brandName: 'Goldenwolf',
        appTitle: 'Goldenwolf',
        primaryColor: const Color(0xFFD4A843),
        secondaryColor: const Color(0xFFF8F3FF),
        accentColor: const Color(0xFFFFC93C),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        // apiBaseUrl: 'https://portal.goldenwolffx.com/api/',
        // websocketUrl: 'wss://portal.goldenwolffx.com/trade-engine',
        // chartBaseUrl: 'https://portal.goldenwolffx.com',
        apiBaseUrl: 'https://demo.tenaxcode.com/api/',
        websocketUrl: 'wss://demo.tenaxcode.com/trade-engine',
        chartBaseUrl: 'https://demo.tenaxcode.com',
        
      );
      
}
