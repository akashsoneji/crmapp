import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum ThemeServiceMode { light, dark, system }

class ThemeService extends GetxService with WidgetsBindingObserver {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _themeKey = 'theme_mode';

  // Default to system theme
  static const ThemeServiceMode defaultMode = ThemeServiceMode.system;

  // Current theme observable — stores the enum value
  final Rx<ThemeServiceMode> currentMode = defaultMode.obs;

  // Theme mode getter for ThemeData — converts enum to Flutter ThemeMode
  ThemeMode get themeMode {
    switch (currentMode.value) {
      case ThemeServiceMode.light:
        return ThemeMode.light;
      case ThemeServiceMode.dark:
        return ThemeMode.dark;
      case ThemeServiceMode.system:
        return ThemeMode.system;
    }
  }

  // Observable mirror of [isDarkMode] — used by widgets inside Obx to
  // rebuild when the theme flips (the underlying [currentMode] is an Rx,
  // but [platformBrightness] changes are not observable through GetX
  // directly, so we recompute and update this whenever either source
  // changes).
  final RxBool isDarkModeObs = false.obs;

  // Convenience getter — true when dark mode is effectively active
  // (dark mode selected OR system mode with dark system preference)
  bool get isDarkMode {
    if (currentMode.value == ThemeServiceMode.dark) return true;
    if (currentMode.value == ThemeServiceMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return false;
  }

  void _refreshDarkMode() {
    isDarkModeObs.value = isDarkMode;
  }

  late final Future<void> _initialization;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // Recompute whenever the user-selected mode changes.
    ever(currentMode, (_) => _refreshDarkMode());
    _refreshDarkMode();
    _initialization = _initialize();
  }

  @override
  void didChangePlatformBrightness() {
    _refreshDarkMode();
    super.didChangePlatformBrightness();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> _initialize() async {
    await _loadSavedTheme();
  }

  Future<void> ensureInitialized() => _initialization;

  /// Load saved theme preference from secure storage
  Future<void> _loadSavedTheme() async {
    try {
      final savedMode = await _storage.read(key: _themeKey);
      if (savedMode != null) {
        currentMode.value = ThemeServiceMode.values.firstWhere(
          (e) => e.name == savedMode,
          orElse: () => defaultMode,
        );
      }
    } catch (e) {
      currentMode.value = defaultMode;
    }
  }

  /// Select a specific theme mode (Light / Dark / System)
  Future<void> selectTheme(ThemeServiceMode mode) async {
    if (currentMode.value != mode) {
      currentMode.value = mode;
      await _saveTheme(mode);
      Get.forceAppUpdate();
    }
  }

  /// Legacy toggle — switches between light and dark only (system defaults to light)
  Future<void> toggleTheme() async {
    final target = currentMode.value == ThemeServiceMode.dark
        ? ThemeServiceMode.light
        : ThemeServiceMode.dark;
    await selectTheme(target);
  }

  /// Legacy setter — kept for backward compatibility
  Future<void> setDarkMode(bool value) async {
    await selectTheme(value ? ThemeServiceMode.dark : ThemeServiceMode.light);
  }

  /// Save theme preference to secure storage
  Future<void> _saveTheme(ThemeServiceMode mode) async {
    try {
      await _storage.write(key: _themeKey, value: mode.name);
    } catch (e) {
      print('ThemeService: Error saving theme: $e');
    }
  }

  /// Check if dark mode is effectively active
  bool isDark() => isDarkMode;

  /// Get current theme mode
  ThemeServiceMode getCurrentMode() => currentMode.value;
}
