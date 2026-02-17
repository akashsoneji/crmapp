import 'package:flutter/material.dart';
import '../base_config.dart';

/// Askbid client configuration
class AskbidConfig extends BaseClientConfig {
  const AskbidConfig()
    : super(
        brandName: 'Askbid',
        appTitle: 'Askbid Trading',
        primaryColor: const Color(0xFF331533),
        secondaryColor: const Color(0xFF2EB77F),
        accentColor: const Color(0xFF2EB77F),
        logoSvgPath: 'askbid_logo.png',
        splashLogoPath: 'askbid_logo.png',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://my.pipze.com/api/',
        websocketUrl: 'wss://my.pipze.com/trade-engine',
        chartBaseUrl: 'https://my.pipze.com',
      );
}
