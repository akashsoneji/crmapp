import 'package:flutter/material.dart';
import '../base_config.dart';

/// Pipze client configuration
class PipzeConfig extends BaseClientConfig {
  const PipzeConfig()
    : super(
        brandName: 'Pipze',
        appTitle: 'Pipze Trading',
        primaryColor: const Color(0xFF5F259E),
        secondaryColor: const Color(0xFFF8F3FF),
        accentColor: const Color(0xFFFFC93C),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://my.pipze.com/api/',
        websocketUrl: 'wss://my.pipze.com/trade-engine',
        chartBaseUrl: 'https://my.pipze.com',
      );
}
