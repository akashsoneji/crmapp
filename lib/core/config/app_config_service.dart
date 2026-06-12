import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:yaml/yaml.dart' as yaml;
import '../../flavor_config.dart';

class AppConfigService extends GetxService {
  final Rxn<Map<String, dynamic>> _config = Rxn<Map<String, dynamic>>();

  Map<String, dynamic> get config => _config.value ?? {};

  bool isFeatureEnabled(String key, {bool defaultValue = true}) {
    return (config['features'] as Map<String, dynamic>?)?[key] ?? defaultValue;
  }

  Future<void> ensureInitialized() async {
    if (_config.value != null && _config.value!.isNotEmpty) return;
    await reload();
  }

  /// Reload app config from the currently-active brand.
  ///
  /// Sources, in order:
  ///   1. `assets/clients/<activeBrand>/brand.yaml` — the bundled per-
  ///      client config (what the build script copies from
  ///      `assets/brands/<brand>/brand.yaml`).
  ///   2. `FlavorConfig` as a fallback for branding
  Future<void> reload() async {
    final branding = {
      'appName': FlavorConfig.instance.appName,
      'appTitle': FlavorConfig.instance.appTitle,
      'primaryColor': FlavorConfig.instance.primaryColor,
      'secondaryColor': FlavorConfig.instance.secondaryColor,
      'accentColor': FlavorConfig.instance.accentColor,
      'logoSvgPath': FlavorConfig.instance.svgLogoPath,
      'splashLogoPath': FlavorConfig.instance.splashLogoPath,
    };

    final features = await _readFeatureFlags();

    _config.value = {
      'branding': branding,
      'features': features,
    };

    if (kDebugMode) {
      debugPrint(
        'AppConfigService: loaded features for ${FlavorConfig.instance.flavor.name} → $features',
      );
    }
  }

  /// Read `featureFlags:` from the bundled per-client brand.yaml.
  ///
  /// Returns an empty map if the file is missing or has no `featureFlags`
  /// section — every flag then falls back to its defaultValue.
  Future<Map<String, bool>> _readFeatureFlags() async {
    try {
      // Determine the active brand from FlavorConfig
      final activeBrand = FlavorConfig.instance.flavor.name;

      // BrandResolver.appConfigAssetPathFor doesn't exist in crmapp,
      // so we hardcode path based on flavor
      final assetPath = 'assets/clients/$activeBrand/brand.yaml';
      final raw = await rootBundle.loadString(assetPath);
      // brand.yaml is YAML; we only need the top-level `featureFlags` map.
      final parsed = yaml.loadYaml(raw);
      if (parsed is! yaml.YamlMap) return const <String, bool>{};

      final flagBlock = parsed['featureFlags'];
      if (flagBlock is! yaml.YamlMap) return const <String, bool>{};

      final out = <String, bool>{};
      flagBlock.forEach((key, value) {
        if (key is String) {
          if (value is bool) {
            out[key] = value;
          } else if (value is num) {
            out[key] = value != 0;
          } else if (value is String) {
            final v = value.toLowerCase().trim();
            out[key] = v == 'true' || v == '1' || v == 'yes' || v == 'on';
          }
        }
      });
      return out;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppConfigService: failed to read featureFlags: $e');
      }
      return const <String, bool>{};
    }
  }

  /// Convenience: should the app use the single-stream `/ws/stream` socket?
  bool get useUnifiedStreamSocket =>
      isFeatureEnabled(FeatureFlags.unifiedStreamSocketKey, defaultValue: false);
}

/// Canonical feature-flag keys. These must match the keys you put in
/// `assets/brands/<brand>/brand.yaml` under `featureFlags:`.
class FeatureFlags {
  FeatureFlags._();

  /// Master toggle: when true, the app uses the single `/ws/stream` socket
  /// (MessagePack binary, condition-based demux). When false, the legacy
  /// 5-socket path is used.
  static const String unifiedStreamSocketKey = 'unifiedStreamSocket';
}
