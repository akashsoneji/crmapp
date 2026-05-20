import 'package:flutter/material.dart';
import '../base_config.dart';

/// Celestial client configuration (Tenax clone)
class CelestialConfig extends BaseClientConfig {
  const CelestialConfig()
    : super(
        brandName: 'Celestial',
        appTitle: 'Celestial',
        primaryColor: const Color(0xFF24324D),
        secondaryColor: const Color(0xFF22D3EE),
        accentColor: const Color(0xFF24324D),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://client.celestialtrader.com/api/',
        websocketUrl: 'wss://client.celestialtrader.com/trade-engine',
        chartBaseUrl: 'https://client.celestialtrader.com',
      );
}
