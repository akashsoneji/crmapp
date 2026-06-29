import 'package:flutter/material.dart';
import '../base_config.dart';

/// GTX Prime client configuration
class GtxprimeConfig extends BaseClientConfig {
  const GtxprimeConfig()
    : super(
        brandName: 'GTX Prime',
        appTitle: 'GTX Prime',
        primaryColor: const Color(0xFF01061A),
        secondaryColor: const Color(0xFF011947),
        accentColor: const Color(0xFF011947),
        logoSvgPath: 'logo.png',
        splashLogoPath: 'splash_logo.png',
        appIconPath: 'icon.png',
        apiBaseUrl: 'https://member.gtxprime.com/api/',
        websocketUrl: 'wss://member.gtxprime.com/trade-engine',
        chartBaseUrl: 'https://member.gtxprime.com',
      );
}
