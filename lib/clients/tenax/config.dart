import 'package:flutter/material.dart';
import '../base_config.dart';

/// Tenax client configuration
class TenaxConfig extends BaseClientConfig {
  /// Set to true to enable the multi-broker selection flow.
  /// Set to false to disable it and go directly to login.
  static const bool enableMultiBroker = false;

  /// Demo broker mode customizes the broker selection flow for demo accounts.
  static const bool enableBrokerDemoMode = bool.fromEnvironment(
    'TENAX_BROKER_DEMO',
    defaultValue: false,
  );

  const TenaxConfig()
    : super(
        brandName: 'Tenax',
        appTitle: 'Tenax Code',
        primaryColor: const Color(0xFF4A0C54),
        secondaryColor: const Color(0xFFE8F5E8),
        accentColor: const Color(0xFF4A0C54),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://demo.tenaxcode.com/api/',
        websocketUrl: 'wss://demo.tenaxcode.com/trade-engine',
        chartBaseUrl: 'https://demo.tenaxcode.com',
      );
}
