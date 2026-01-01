import 'package:flutter/material.dart';
import '../base_config.dart';

/// AFX client configuration
class AfxConfig extends BaseClientConfig {
  const AfxConfig()
    : super(
        brandName: 'AFX',
        appTitle: 'AFX',
        primaryColor: const Color(0xFF182430),
        secondaryColor: const Color(0xFFE8F0F5),
        accentColor: const Color(0xFF182430),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://member.alibabafx.com/api/',
        websocketUrl: 'wss://member.alibabafx.com/trade-engine',
        chartBaseUrl: 'https://member.alibabafx.com',
      );
}
