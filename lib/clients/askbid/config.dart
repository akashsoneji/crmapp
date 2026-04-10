import 'package:flutter/material.dart';
import '../base_config.dart';

/// Askbid client configuration
class AskbidConfig extends BaseClientConfig {
  const AskbidConfig()
    : super(
        brandName: 'Askbid',
        appTitle: 'Askbid Trading',
        primaryColor: const Color(0xFF331533),
        secondaryColor: const Color(0xFFE8F5E8),
        accentColor: const Color(0xFF2EB77F),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://app.askbidfx.com/api/',
        websocketUrl: 'wss://app.askbidfx.com/trade-engine',
        chartBaseUrl: 'https://app.askbidfx.com',
      );
}
