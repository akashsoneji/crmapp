import 'package:flutter/material.dart';

/// Base configuration template for all clients
/// DO NOT USE DIRECTLY - extend this class in client-specific configs
class BaseClientConfig {
  // Branding
  final String brandName;
  final String appTitle;

  // Colors
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  // Splash color (null = use primaryColor)
  final Color? splashColor;

  // Asset paths (relative to clients/{client}/assets/)
  final String logoSvgPath;
  final String splashLogoPath;
  final String appIconPath;

  // URLs
  final String apiBaseUrl;
  final String websocketUrl;
  final String chartBaseUrl;

  // Feature flags
  /// Whether deposit / withdrawal open the new flow (finance v2) instead of
  /// the legacy screens.
  final bool useNewDepositWithdrawFlow;

  const BaseClientConfig({
    required this.brandName,
    required this.appTitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.splashColor,
    required this.logoSvgPath,
    required this.splashLogoPath,
    required this.appIconPath,
    required this.apiBaseUrl,
    required this.websocketUrl,
    required this.chartBaseUrl,
    this.useNewDepositWithdrawFlow = false,
  });

  /// Get the full asset path for a client asset
  String getAssetPath(String clientName, String assetPath) {
    return 'assets/clients/$clientName/$assetPath';
  }
}
