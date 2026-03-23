import 'package:flutter/material.dart';
import '../base_config.dart';

/// VR19 client configuration
class Vr19Config extends BaseClientConfig {
  const Vr19Config()
    : super(
        brandName: 'VR19',
        appTitle: 'VR19',
        // VR19 palette - UPDATE THESE COLORS with actual brand colors
        primaryColor: const Color(0xFF25456F),
        secondaryColor: const Color(0xFFFFFFFF),
        accentColor: const Color(0xFF1a1f3e),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        // TODO: Replace with actual API endpoints
        apiBaseUrl: 'https://trade.vr19capital.com/api/',
        websocketUrl: 'wss://trade.vr19capital.com/trade-engine',
        chartBaseUrl: 'https://trade.vr19capital.com',
      );
}
