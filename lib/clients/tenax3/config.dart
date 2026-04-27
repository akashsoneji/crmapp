import 'package:flutter/material.dart';
import '../base_config.dart';

/// Tenax3 client configuration (Tenax clone)
class Tenax3Config extends BaseClientConfig {
  /// Keep Tenax behavior flags identical.
  static const bool enableMultiBroker = false;

  /// Demo broker mode customizes the broker selection flow for demo accounts.
  static const bool enableBrokerDemoMode = bool.fromEnvironment(
    'TENAX_BROKER_DEMO',
    defaultValue: false,
  );

  const Tenax3Config()
    : super(
        brandName: 'Tenax3',
        appTitle: 'Tenax Code',
        primaryColor: const Color(0xFF4A0C54),
        secondaryColor: const Color(0xFFE8F5E8),
        accentColor: const Color(0xFF4A0C54),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://demo3.tenaxcode.com/api/',
        websocketUrl: 'wss://demo3.tenaxcode.com/trade-engine',
        chartBaseUrl: 'https://demo3.tenaxcode.com',
      );
}

