import 'package:flutter/material.dart';
import '../base_config.dart';

/// TenaxNew client configuration: Tenax branding on the new home design.
class TenaxNewConfig extends BaseClientConfig {
  /// Set to true to enable the multi-broker selection flow.
  /// Set to false to disable it and go directly to login.
  static const bool enableMultiBroker = false;

  /// Demo broker mode customizes the broker selection flow for demo accounts.
  static const bool enableBrokerDemoMode = bool.fromEnvironment(
    'TENAX_BROKER_DEMO',
    defaultValue: false,
  );

  const TenaxNewConfig()
    : super(
        brandName: 'Tenax',
        appTitle: 'Tenax Code',
        primaryColor: const Color(0xFF4A0C54),
        secondaryColor: const Color(0xFFE8F5E8),
        accentColor: const Color(0xFF4A0C54),
        splashColor: const Color(0xFF4A0C54),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        apiBaseUrl: 'https://dev.tenaxcodecrm.com/api/',
        websocketUrl: 'wss://dev.tenaxcodecrm.com/trade-engine',
        chartBaseUrl: 'https://dev.tenaxcodecrm.com',
      );
}
