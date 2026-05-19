import 'package:flutter/material.dart';
import 'package:crm_app/constants/color.dart';

/// Trade & Win colors that stay readable in dark mode.
///
/// In dark mode [AppColors.primary] is white, so solid primary fills with
/// [AppColors.onColoredBackground] text become invisible. Use these getters
/// for buttons, chips, and hero cards instead.
abstract final class TradeWinTheme {
  static Color get accentFill =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.15)
          : AppColors.brandPrimary;

  static Color get accentFillStrong =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.22)
          : AppColors.brandPrimary;

  static Color get onAccentFill =>
      AppColors.isDarkMode ? AppColors.textPrimary : AppColors.onColoredBackground;

  static Color get chipSelectedBg =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.15)
          : AppColors.brandPrimary;

  static Color get chipUnselectedBg => AppColors.card;

  static Color get chipSelectedFg => onAccentFill;

  static Color get chipUnselectedFg => AppColors.textPrimary;

  static Color get chipBorder =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.25)
          : AppColors.brandPrimary.withValues(alpha: 0.35);

  static Color get heroCardBg =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.12)
          : AppColors.brandPrimary;

  static Border? get heroCardBorder =>
      AppColors.isDarkMode
          ? Border.all(color: Colors.white.withValues(alpha: 0.18))
          : null;
}
