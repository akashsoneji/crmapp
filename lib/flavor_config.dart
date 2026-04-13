import 'package:flutter/material.dart';
import 'clients/tenax/config.dart';

enum Flavor {
  tenax,
}

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String appTitle;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String apiBaseUrl;
  final String chartBaseUrl;
  final String websocketUrl;
  final String appIconPath;
  final String svgLogoPath;
  final String splashLogoPath; // Splash screen logo path
  final String? remoteLogoUrl;
  final Map<String, dynamic>? selectedBrokerData;

  static FlavorConfig? _instance;
  static Flavor? _selectedFlavor;

  factory FlavorConfig({
    required Flavor flavor,
    required String appName,
    required String appTitle,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
    required String apiBaseUrl,
    required String websocketUrl,
    required String chartBaseUrl,
    required String appIconPath,
    required String svgLogoPath,
    required String splashLogoPath,
    String? remoteLogoUrl,
    Map<String, dynamic>? selectedBrokerData,
  }) {
    // If no flavor is selected yet, or if the flavor matches the selected one, initialize it
    if (_selectedFlavor == null || _selectedFlavor == flavor) {
      _instance = FlavorConfig._internal(
        flavor: flavor,
        appName: appName,
        title: appTitle,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        accentColor: accentColor,
        apiBaseUrl: apiBaseUrl,
        websocketUrl: websocketUrl,
        chartBaseUrl: chartBaseUrl,
        appIconPath: appIconPath,
        svgLogoPath: svgLogoPath,
        splashLogoPath: splashLogoPath,
        remoteLogoUrl: remoteLogoUrl,
        selectedBrokerData: selectedBrokerData,
      );
      _selectedFlavor = flavor;
    }
    return _instance!;
  }

  /// Reset the flavor configuration (useful for testing or switching flavors)
  static void reset() {
    _instance = null;
    _selectedFlavor = null;
  }

  FlavorConfig._internal({
    required this.flavor,
    required String title,
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.apiBaseUrl,
    required this.websocketUrl,
    required this.chartBaseUrl,
    required this.appIconPath,
    required this.svgLogoPath,
    required this.splashLogoPath,
    required this.remoteLogoUrl,
    required this.selectedBrokerData,
  }) : appTitle = title;

  static FlavorConfig get instance {
    return _instance ?? FlavorConfig.tenax;
  }

  static bool isTenax() => _instance?.flavor == Flavor.tenax;

  /// Whether the multi-broker selection flow is enabled for Tenax.
  /// Controlled by [TenaxConfig.enableMultiBroker].
  /// Set that flag to false to disable the broker picker everywhere.
  static bool get isMultiBrokerEnabled =>
      isTenax() && TenaxConfig.enableMultiBroker;
  static bool get isTenaxBrokerDemoEnabled =>
      isTenax() && TenaxConfig.enableBrokerDemoMode;
  static bool isONSA() => false;
  static bool isProfx() => false;
  static bool isAFX() => false;
  static bool isKantara() => false;
  static bool isTradoxy() => false;
  static bool isAskbid() => false;
  static bool isSR() => false;
  static bool isVr19() => false;
  static String get svgLogoAsset => instance.svgLogoPath;
  static String? get remoteLogo => instance.remoteLogoUrl;
  static bool get hasRemoteLogo =>
      (instance.remoteLogoUrl ?? '').trim().isNotEmpty;
  static String get effectiveLogo => remoteLogo ?? svgLogoAsset;
  static Map<String, dynamic>? get brokerData => instance.selectedBrokerData;
  static String get appNameDisplay => instance.appName;

  static void applyTenaxBrokerSelection({
    required String brokerName,
    String? brokerLogoUrl,
    Map<String, dynamic>? brokerData,
  }) {
    final current = instance;
    _instance = FlavorConfig._internal(
      flavor: current.flavor,
      title: current.appTitle,
      appName: brokerName.trim().isEmpty ? current.appName : brokerName.trim(),
      primaryColor: current.primaryColor,
      secondaryColor: current.secondaryColor,
      accentColor: current.accentColor,
      apiBaseUrl: current.apiBaseUrl,
      websocketUrl: current.websocketUrl,
      chartBaseUrl: current.chartBaseUrl,
      appIconPath: current.appIconPath,
      svgLogoPath: current.svgLogoPath,
      splashLogoPath: current.splashLogoPath,
      remoteLogoUrl:
          (brokerLogoUrl != null && brokerLogoUrl.trim().isNotEmpty)
              ? brokerLogoUrl.trim()
              : null,
      selectedBrokerData: brokerData,
    );
    _selectedFlavor = current.flavor;
  }

  static void applyTenaxBrokerRuntimeConfig({
    required Map<String, dynamic> config,
    String? brokerName,
    String? brokerLogoUrl,
    Map<String, dynamic>? brokerData,
  }) {
    final current = instance;
    final source = _extractRuntimeSource(config);
    final resolvedName =
        (brokerName ??
                _stringFrom(source, [
                  'brandName',
                  'brand_name',
                  'name',
                  'appName',
                  'app_name',
                ]))
            .trim();

    final resolvedTitle =
        _stringFrom(source, ['appTitle', 'app_title', 'title']).trim();

    final resolvedApi = _normalizeApiBaseUrl(
      _stringFrom(source, [
        'primary_url', // decrypted broker config key
        'apiBaseUrl',
        'api_base_url',
        'api_url',
        'base_url',
      ]),
    );
    final resolvedWebSocket = _normalizeUrl(
      _stringFrom(source, [
        'websocketUrl',
        'websocket_url',
        'socket_url',
        'ws_url',
      ]),
    );
    final resolvedChart = _normalizeUrl(
      _stringFrom(source, ['chartBaseUrl', 'chart_base_url', 'chart_url']),
    );

    // Extract logo URL from decrypted config (priority: app_icon_url > logo_url)
    final resolvedLogoFromConfig = _stringFrom(source, [
      'app_icon_url',
      'app_logo_url',
      'logo_url',
      'logoUrl',
    ]);

    final resolvedPrimary = _parseColor(
      source['primaryColor'] ??
          source['primary_color'] ??
          source['themeColor'] ??
          source['theme_color'] ??
          source['brandColor'] ??
          source['brand_color'] ??
          source['color_primary'],
    );
    final resolvedSecondary = _parseColor(
      source['secondaryColor'] ??
          source['secondary_color'] ??
          source['color_secondary'] ??
          source['accent_color'],
    );
    final resolvedAccent = _parseColor(
      source['accentColor'] ??
          source['accent_color'] ??
          source['color_accent'] ??
          source['secondary_color'],
    );

    _instance = FlavorConfig._internal(
      flavor: current.flavor,
      title: resolvedTitle.isNotEmpty ? resolvedTitle : current.appTitle,
      appName: resolvedName.isNotEmpty ? resolvedName : current.appName,
      primaryColor: resolvedPrimary ?? current.primaryColor,
      secondaryColor: resolvedSecondary ?? current.secondaryColor,
      accentColor: resolvedAccent ?? current.accentColor,
      apiBaseUrl: resolvedApi.isNotEmpty ? resolvedApi : current.apiBaseUrl,
      websocketUrl:
          resolvedWebSocket.isNotEmpty
              ? resolvedWebSocket
              : current.websocketUrl,
      chartBaseUrl:
          resolvedChart.isNotEmpty ? resolvedChart : current.chartBaseUrl,
      appIconPath: current.appIconPath,
      svgLogoPath: current.svgLogoPath,
      splashLogoPath: current.splashLogoPath,
      remoteLogoUrl:
          (brokerLogoUrl != null && brokerLogoUrl.trim().isNotEmpty)
              ? brokerLogoUrl.trim()
              : resolvedLogoFromConfig.isNotEmpty
              ? resolvedLogoFromConfig
              : null,
      selectedBrokerData: brokerData,
    );
    _selectedFlavor = current.flavor;
  }

  static Map<String, dynamic> _extractRuntimeSource(
    Map<String, dynamic> config,
  ) {
    final nestedCandidates = ['config', 'flavor', 'broker_config', 'data'];
    for (final key in nestedCandidates) {
      final candidate = config[key];
      if (candidate is Map<String, dynamic> && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return config;
  }

  static String _stringFrom(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  static String _normalizeApiBaseUrl(String value) {
    final normalized = _normalizeUrl(value);
    if (normalized.isEmpty) return normalized;
    return normalized.endsWith('/') ? normalized : '$normalized/';
  }

  static String _normalizeUrl(String value) {
    return value.trim();
  }

  static Color? _parseColor(dynamic value) {
    if (value == null) return null;
    if (value is Color) return value;
    if (value is int) {
      return Color(value);
    }
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    var hex = raw.replaceFirst('#', '').replaceFirst('0x', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) {
      return null;
    }
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return null;
    }
    return Color(parsed);
  }

  static FlavorConfig get tenax {
    _selectedFlavor = Flavor.tenax;
    const config = TenaxConfig(); // Load centralized config
    return FlavorConfig(
      flavor: Flavor.tenax,
      appName: config.brandName,
      appTitle: config.appTitle,
      primaryColor: config.primaryColor,
      secondaryColor: config.secondaryColor,
      accentColor: config.accentColor,
      websocketUrl: config.websocketUrl,
      chartBaseUrl: config.chartBaseUrl,
      apiBaseUrl: config.apiBaseUrl,
      appIconPath: config.getAssetPath('tenax', config.appIconPath),
      svgLogoPath: config.getAssetPath('tenax', config.logoSvgPath),
      splashLogoPath: config.getAssetPath('tenax', config.splashLogoPath),
      remoteLogoUrl: null,
      selectedBrokerData: null,
    );
  }
}
