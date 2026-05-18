import 'package:flutter/material.dart';
import 'package:crm_app/constants/color.dart';

/// Theme-aware helpers for dropdowns and date pickers in forms.
class AppPickerTheme {
  AppPickerTheme._();

  static const Color _white = Color(0xFFFFFFFF);

  /// Background for open dropdown menus.
  static Color get dropdownMenuColor => AppColors.card;

  /// Selected value / menu item text.
  static TextStyle dropdownTextStyle(
    double fontSize, {
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: fontSize,
        color: AppColors.textPrimary,
        fontWeight: fontWeight,
      );

  /// Hint / placeholder text in dropdowns.
  static TextStyle dropdownHintStyle(double fontSize) =>
      TextStyle(fontSize: fontSize, color: AppColors.textGrey);

  /// Icon color for dropdown arrows.
  static Color get dropdownIconColor => AppColors.textGrey;

  static DatePickerThemeData _calendarDayTheme({required bool isDark}) {
    final selectedBg = _white.withValues(alpha: 0.1);
    const selectedFg = _white;
    final todayBg = _white.withValues(alpha: 0.1);

    if (isDark) {
      return DatePickerThemeData(
        dayBackgroundColor: WidgetStateProperty<Color?>.fromMap({
          WidgetState.selected: selectedBg,
        }),
        dayForegroundColor: WidgetStateProperty<Color?>.fromMap({
          WidgetState.selected: selectedFg,
        }),
        todayForegroundColor: WidgetStateProperty.all(selectedFg),
        todayBackgroundColor: WidgetStateProperty.all(todayBg),
      );
    }

    // Light mode: dark text + subtle dark tint (white alpha is invisible on white).
    final lightFg = AppColors.textPrimaryLight;
    final lightSelectedBg = lightFg.withValues(alpha: 0.1);

    return DatePickerThemeData(
      dayBackgroundColor: WidgetStateProperty<Color?>.fromMap({
        WidgetState.selected: lightSelectedBg,
      }),
      dayForegroundColor: WidgetStateProperty<Color?>.fromMap({
        WidgetState.selected: lightFg,
      }),
      todayForegroundColor: WidgetStateProperty.all(lightFg),
      todayBackgroundColor: WidgetStateProperty.all(lightSelectedBg),
    );
  }

  /// Opens a date picker dialog with light/dark colors from [AppColors].
  static Future<DateTime?> showAppDatePicker(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final isDark = AppColors.isDarkMode;
    final selectedBg = _white.withValues(alpha: 0.1);
    const selectedFg = _white;

    // primary/onPrimary drive the selected-day circle when theme props fall through.
    final colorScheme =
        isDark
            ? ColorScheme.dark(
              primary: selectedBg,
              onPrimary: selectedFg,
              surface: AppColors.cardDarkTheme,
              onSurface: AppColors.textPrimaryDark,
            )
            : ColorScheme.light(
              primary: AppColors.textPrimaryLight.withValues(alpha: 0.1),
              onPrimary: AppColors.textPrimaryLight,
              surface: AppColors.cardLightTheme,
              onSurface: AppColors.textPrimaryLight,
            );

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final actionTextColor =
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme,
            dialogTheme: DialogThemeData(backgroundColor: colorScheme.surface),
            datePickerTheme: _calendarDayTheme(isDark: isDark),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: actionTextColor),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
