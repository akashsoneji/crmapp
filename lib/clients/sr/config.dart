import 'package:flutter/material.dart';
import '../base_config.dart';

/// SR client configuration
class SrConfig extends BaseClientConfig {
  const SrConfig()
    : super(
        brandName: 'SR',
        appTitle: 'SR',
        // SR palette
        // 1. Primary:   #DC2626
        // 2. Secondary: #0A0F19
        // 3. Accent:    #030303
        primaryColor: const Color(0xFFDC2626),
        secondaryColor: const Color(0xFFE6F5F2),
        accentColor: const Color(0xFF030303),
        logoSvgPath: 'logo.svg',
        splashLogoPath: 'splash_logo.svg',
        appIconPath: 'app_icon.png',
        // Re-using askbid backend endpoints until SR endpoints are provided.
        apiBaseUrl: 'https://app.srglobalmarkets.com/api/',
        websocketUrl: 'wss://app.srglobalmarkets.com/trade-engine',
        chartBaseUrl: 'https://app.srglobalmarkets.com',
      );
}
