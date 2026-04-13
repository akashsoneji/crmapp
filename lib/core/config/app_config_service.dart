import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../flavor_config.dart';
import 'app_config_model.dart';

class AppConfigService extends GetxService {
  static const String tenaxAssetPath = 'assets/config/tenax/app_config.json';

  final _config = Rxn<AppConfigModel>();

  AppConfigModel? get config => _config.value;

  bool isFeatureEnabled(String key, {bool defaultValue = true}) {
    return _config.value?.isFeatureEnabled(key, defaultValue: defaultValue) ??
        defaultValue;
  }

  Future<void> ensureInitialized() async {
    if (_config.value != null) return;
    await reload();
  }

  Future<void> reload() async {
    final raw = await rootBundle.loadString(tenaxAssetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw StateError('Invalid app_config.json: expected JSON object');
    }
    final model = AppConfigModel.fromJson(decoded.cast<String, dynamic>());
    _config.value = model;

    // Apply branding to FlavorConfig so existing UI uses it without refactors.
    final branding = model.branding;
    FlavorConfig.applyTenaxBrokerRuntimeConfig(
      config: <String, dynamic>{
        'appName': branding.appName,
        'appTitle': branding.appTitle,
        'primaryColor': branding.primaryColor,
        'secondaryColor': branding.secondaryColor,
        'accentColor': branding.accentColor,
      },
      brokerName: branding.appName,
      brokerLogoUrl: branding.logoSvgPath,
      brokerData: null,
    );
  }
}

