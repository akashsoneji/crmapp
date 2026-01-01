import 'package:flutter/material.dart';
import '../base_config.dart';

/// Tradoxy client configuration
class TradoxyConfig extends BaseClientConfig {
  const TradoxyConfig()
    : super(
        brandName: 'Tradoxy',
        appTitle: 'Tradoxy Trading',
        primaryColor: const Color(0xFF071A2D),
        secondaryColor: const Color(0xFFE8F0F5),
        accentColor: const Color(0xFF071A2D),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://member.alibabafx.com/api/',
        websocketUrl: 'wss://member.alibabafx.com/trade-engine',
        chartBaseUrl: 'https://member.alibabafx.com',
      );
}
