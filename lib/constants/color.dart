import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../flavor_config.dart';
import '../services/theme_service.dart';

/// Central palette + theme-aware colors.
///
/// **UI code:** use getters only — [textPrimary], [background], [card], [border], etc.
/// They switch automatically for light / dark / system theme.
///
/// **Do not use** `textPrimaryLight`, `textPrimaryDark`, or raw hex in screens/widgets.
/// Hex values below exist only as the single source of truth inside this file.
class AppColors {
  static ThemeService? get _themeService =>
      Get.isRegistered<ThemeService>() ? Get.find<ThemeService>() : null;

  static bool get isDarkMode => _themeService?.isDarkMode ?? false;

  // --- Pure literals (private) — only referenced when building the palette below ---
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _pureBlack = Color(0xFF000000);

  static Color get pureWhite => _pureWhite;
  static Color get pureBlack => _pureBlack;

  /// Flavor brand color — unchanged in dark mode (logos, splash glow).
  static Color get brandPrimary => FlavorConfig.instance.primaryColor;

  /// Primary accent for UI (icons, chips, nav). White in dark mode except goldenwolffx.
  static Color get primary {
    if (isDarkMode && !FlavorConfig.isGoldenwolffx()) {
      return _pureWhite;
    }
    return brandPrimary;
  }

  /// Material dark theme primary — stable when building [ThemeData].
  static Color get darkThemePrimary =>
      FlavorConfig.isGoldenwolffx() ? brandPrimary : _pureWhite;

  /// Text/icon on brand, success, error, or other saturated backgrounds.
  static const Color onColoredBackground = _pureWhite;

  static const Color selectedChipForeground = onColoredBackground;

  static Color get darkThemeOnPrimary =>
      FlavorConfig.isGoldenwolffx() ? onColoredBackground : textPrimaryDark;

  static Color get controlActive => isDarkMode ? primary : brandPrimary;

  static Color get sheetHandle =>
      isDarkMode ? icongrey.withValues(alpha: 0.5) : grey;

  static Color get bottomSheetSurface => card;

  static Color get selectedChipBackground =>
      isDarkMode ? const Color(0xFF4F535D) : brandPrimary;

  static Color accountSheetLeadingBackground({required bool isDemo}) =>
      isDarkMode
          ? selectedChipBackground
          : (isDemo
              ? brandPrimary.withValues(alpha: 0.2)
              : brandPrimary);

  static Color accountSheetLeadingIcon({required bool isDemo}) =>
      isDarkMode ? primary : (isDemo ? brandPrimary : onColoredBackground);

  static Color get accountSheetSelectedTile =>
      isDarkMode
          ? selectedChipBackground
          : brandPrimary.withValues(alpha: 0.1);

  static Color get secondary => FlavorConfig.instance.secondaryColor;
  static Color get accent => FlavorConfig.instance.accentColor;

  static const Color secondaryStatic = Color(0xFFF6F6F6);
  static const Color accentStatic = Color(0xFFFEBC1F);
  static const Color blue = Color(0xFF3478F6);

  // --- Light palette (constants — for [ThemeData.light] and [textPrimary] in light mode) ---
  static const Color textPrimaryLight = _pureBlack;
  static const Color textSecondaryLight = Color(0xFF9E9E9E);
  static const Color textGreyLightTheme = Color.fromRGBO(117, 121, 132, 1);
  static const Color textGreyLightVariant = Color(0xFF919EAB);
  static const Color whiteColorLight = Color(0xFFF6F6F6);
  static const Color tradeTextCenterColorLight = Color(0xFF4F535D);
  static const Color tradeBackgroundCenterColorLight = Color(0xFFF7F7F7);

  // --- Dark palette ---
  static const Color textPrimaryDark = _pureWhite;
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textGreyDark = Color.fromRGBO(160, 160, 160, 1);
  static const Color textGreyLightDark = Color(0xFF9E9E9E);
  static const Color whiteColorDark = Color(0xFF2C2C2C);
  static const Color tradeTextCenterColorDark = Color(0xFFB0B0B0);
  static const Color tradeBackgroundCenterColorDark = Color(0xFF1E1E1E);

  // --- Theme-aware text (use these in UI) ---
  static Color get textPrimary =>
      isDarkMode ? textPrimaryDark : textPrimaryLight;

  static Color get textSecondary =>
      isDarkMode ? textSecondaryDark : textSecondaryLight;

  static Color get textGrey =>
      isDarkMode ? textGreyDark : textGreyLightTheme;

  static Color get textGreyLight =>
      isDarkMode ? textGreyLightDark : textGreyLightVariant;

  static Color get whiteColor =>
      isDarkMode ? whiteColorDark : whiteColorLight;

  static Color get tradeTextCenterColor =>
      isDarkMode ? tradeTextCenterColorDark : tradeTextCenterColorLight;

  static Color get tradeBackgroundCenterColor =>
      isDarkMode
          ? tradeBackgroundCenterColorDark
          : tradeBackgroundCenterColorLight;

  static const Color backgroundLightTheme = Color(0xFFFFFFFF);
  static const Color surfaceLightTheme = Color(0xFFF5F5F5);
  static const Color cardLightTheme = Color(0xFFFFFFFF);

  static const Color backgroundDarkTheme = Color(0xFF121212);
  static const Color surfaceDarkTheme = Color(0xFF1E1E1E);
  static const Color cardDarkTheme = Color(0xFF2C2C2C);

  static Color get backgroundLight =>
      isDarkMode ? backgroundDarkTheme : backgroundLightTheme;

  static Color get surface =>
      isDarkMode ? surfaceDarkTheme : surfaceLightTheme;

  static Color get cardBackground =>
      isDarkMode ? cardDarkTheme : cardLightTheme;

  static Color get background =>
      isDarkMode ? backgroundDarkTheme : backgroundLightTheme;

  static Color get card => isDarkMode ? cardDarkTheme : cardLightTheme;

  static Color get successBg =>
      isDarkMode ? const Color(0xFF1A3D2A) : const Color(0xFFEDF7EE);

  static Color get successText =>
      isDarkMode ? const Color(0xFF6EE7A0) : const Color(0xFF2A7D3F);

  static Color get warningBg =>
      isDarkMode ? const Color(0xFF3D2A1A) : const Color(0xFFFFF8E1);

  static Color get warningText =>
      isDarkMode ? const Color(0xFFFFCC02) : const Color(0xFFB7791F);

  static Color get warningBorder =>
      isDarkMode ? const Color(0xFF92400E) : const Color(0xFFFFCC02);

  static Color get errorBg =>
      isDarkMode ? const Color(0xFF3D1A1A) : const Color(0xFFFEF2F2);

  static Color get errorText =>
      isDarkMode ? const Color(0xFFEF9999) : const Color(0xFFD32F2F);

  static const Color quickActionGreen = Color(0xFF4CAF50);
  static const Color quickActionOrange = Color(0xFFFF9800);
  static const Color quickActionBlue = Color(0xFF2196F3);
  static const Color quickActionPurple = Color(0xFF9C27B0);

  static Color get accentPurple =>
      isDarkMode ? const Color(0xFF3D2A4A) : const Color(0xFFF0E0F8);

  static Color get accentYellow =>
      isDarkMode ? const Color(0xFF3D3A1A) : const Color(0xFFFFF8D4);

  static const Color scratchOverlay = Color(0xFF0F1E2D);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color red = Color(0xFFD72E1F);
  static const Color green = Color(0xFF3C8836);
  static const Color grey = Color(0xFFEDF1F3);
  static const Color icongrey = Color(0xFF757984);
  static const Color icongreylight = Color(0xFF919EAB7A);

  static Color get cardBackGround =>
      primary.withValues(alpha: isDarkMode ? 0.10 : 0.20);

  static Color get cardBackGroundSecondary =>
      primary.withValues(alpha: isDarkMode ? 0.45 : 0.60);

  static const Color borderLight = Color(0xFFBBBBBB);
  static const Color hintLight = Color(0xFF9E9E9E);
  static const Color dashLineColorLight = Color(0xFF75798433);

  static const Color borderDark = Color(0xFF404040);
  static const Color hintDark = Color(0xFF9E9E9E);
  static const Color dashLineColorDark = Color(0x40404040);

  static Color get border => isDarkMode ? borderDark : borderLight;

  static Color get hint => isDarkMode ? hintDark : hintLight;

  static Color get dashLineColor =>
      isDarkMode ? dashLineColorDark : dashLineColorLight;

  static String get chartTheme => isDarkMode ? 'dark' : 'light';

  /// App bar / back icon / primary readable text — black in light, white in dark.
  static Color get iconPrimary => textPrimary;

  static Color get shadow =>
      textPrimary.withValues(alpha: isDarkMode ? 0.2 : 0.05);

  static Color shadowAlpha(double alpha) =>
      textPrimary.withValues(alpha: alpha);

  static Color get scrim => _pureBlack.withValues(alpha: 0.54);

  static Color get scrimLight => _pureBlack.withValues(alpha: 0.26);

  static Color get overlayDim => _pureBlack.withValues(alpha: 0.4);

  static Color get toastBackground => _pureBlack.withValues(alpha: 0.87);

  static Color get cameraBackground => backgroundDarkTheme;

  /// Disabled / step indicator track (theme-aware neutral).
  static Color get neutralTrack =>
      isDarkMode ? const Color(0xFF404040) : const Color(0xFFE0E0E0);

  static Color get neutralTrackMuted =>
      isDarkMode ? const Color(0xFF505050) : const Color(0xFFD0D0D0);

  static Color get neutralTrackSoft =>
      isDarkMode ? const Color(0xFF606060) : const Color(0xFFBDBDBD);

  /// Unselected chip / tab fill.
  static Color get chipSurface =>
      isDarkMode ? surfaceDarkTheme : const Color(0xFFF3F4F6);

  /// Switch track when off.
  static Color get switchTrackOff =>
      isDarkMode ? const Color(0xFF505050) : const Color(0xFFDCDCDC);
}
