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

  /// Bottom nav selected pill — low alpha so icons stay visible.
  static Color get navSelectedBg =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.08)
          : AppColors.brandPrimary.withValues(alpha: 0.12);

  static Color get onAccentFill =>
      AppColors.isDarkMode ? AppColors.textPrimary : AppColors.onColoredBackground;

  /// Category filter chips — clear selected vs unselected in light & dark.
  static Color get catalogChipSelectedBg =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.1)
          : AppColors.brandPrimary;

  static Color get catalogChipSelectedFg =>
      AppColors.isDarkMode ? Colors.white : AppColors.onColoredBackground;

  static Color get catalogChipSelectedBorder =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.1)
          : AppColors.brandPrimary;

  static Color get catalogChipUnselectedBg =>
      AppColors.isDarkMode
          ? Colors.transparent
          : AppColors.icongrey.withValues(alpha: 0.12);

  static Color get catalogChipUnselectedFg => AppColors.textPrimary;

  static Color get catalogChipUnselectedBorder =>
      AppColors.isDarkMode
          ? AppColors.icongrey.withValues(alpha: 0.45)
          : AppColors.icongrey.withValues(alpha: 0.35);

  static Color get chipSelectedBg =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.28)
          : AppColors.brandPrimary;

  static Color get chipUnselectedBg => AppColors.card;

  static Color get chipSelectedFg => onAccentFill;

  static Color get chipUnselectedFg => AppColors.textPrimary;

  static Color get chipSelectedBorder =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.55)
          : AppColors.brandPrimary;

  static Color get chipUnselectedBorder =>
      AppColors.icongrey.withValues(alpha: 0.25);

  static double get chipSelectedBorderWidth => AppColors.isDarkMode ? 1.5 : 1.0;

  static double get chipUnselectedBorderWidth => 1.0;

  static Color get heroCardBg =>
      AppColors.isDarkMode
          ? Colors.white.withValues(alpha: 0.12)
          : AppColors.brandPrimary;

  static Border? get heroCardBorder =>
      AppColors.isDarkMode
          ? Border.all(color: Colors.white.withValues(alpha: 0.18))
          : null;

  /// Redeem stepper — always brand-colored (never white lines in dark mode).
  static Color get stepperActiveBg => AppColors.brandPrimary;

  static Color get stepperInactiveBg =>
      AppColors.icongrey.withValues(alpha: AppColors.isDarkMode ? 0.4 : 0.28);

  static Color get stepperActiveFg => AppColors.onColoredBackground;

  static Color get stepperInactiveFg => AppColors.textGrey;

  static Color get stepperLineCompleted => AppColors.brandPrimary;

  static Color get stepperLinePending =>
      AppColors.icongrey.withValues(alpha: AppColors.isDarkMode ? 0.4 : 0.28);

  /// Section headings (avoid [AppColors.primary] which is white in dark mode).
  static Color get sectionTitle => AppColors.brandPrimary;
}
