import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeService extends GetxService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _themeKey = 'is_dark_mode';

  // Default to light theme
  static const bool defaultTheme = false;

  // Current theme observable
  final RxBool isDarkMode = defaultTheme.obs;

  // Theme mode getter for ThemeData
  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  late final Future<void> _initialization;

  @override
  void onInit() {
    super.onInit();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    await _loadSavedTheme();
  }

  Future<void> ensureInitialized() => _initialization;

  /// Load saved theme preference from secure storage
  Future<void> _loadSavedTheme() async {
    try {
      final savedTheme = await _storage.read(key: _themeKey);
      if (savedTheme != null) {
        isDarkMode.value = savedTheme == 'true';
      }
    } catch (e) {
      print('ThemeService: Error loading saved theme: $e');
      // Fallback to default
      isDarkMode.value = defaultTheme;
    }
  }

  /// Toggle between dark and light theme
  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    await _saveTheme(isDarkMode.value);
    // Trigger UI update
    Get.forceAppUpdate();
  }

  /// Set specific theme mode
  Future<void> setDarkMode(bool value) async {
    if (isDarkMode.value != value) {
      isDarkMode.value = value;
      await _saveTheme(value);
      Get.forceAppUpdate();
    }
  }

  /// Save theme preference to secure storage
  Future<void> _saveTheme(bool isDark) async {
    try {
      await _storage.write(key: _themeKey, value: isDark.toString());
    } catch (e) {
      print('ThemeService: Error saving theme: $e');
    }
  }

  /// Get current theme mode
  bool getCurrentTheme() => isDarkMode.value;

  /// Check if dark mode is enabled
  bool isDark() => isDarkMode.value;
}
