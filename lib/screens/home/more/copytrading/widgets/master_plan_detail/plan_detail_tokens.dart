import 'package:crm_app/constants/color.dart';
import 'package:flutter/material.dart';

/// Theme-aware design tokens for the Master Plan Detail screen.
///
/// ODDA-style mobile feel: clean neutrals, generous spacing, subtle
/// elevations, soft rounded corners, and an accent that matches the
/// broker's primary brand colour via [AppColors.primary].
class PlanTokens {
  final bool isDark;
  PlanTokens({required this.isDark});

  // Brand — sourced from the broker theme (AppColors.primary). When the
  // active broker flips (Tenax → SR → ONSa → …), every accent on this
  // screen follows automatically.
  static const Color _brandSoft = Color(0xFFEEF2FF);

  // Semantic
  static const Color _success = Color(0xFF12B76A);
  static const Color _successSoft = Color(0xFFE6F7EE);
  static const Color _successText = Color(0xFF027A48);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dangerSoft = Color(0xFFFEE4E2);
  static const Color _dangerText = Color(0xFFB42318);
  static const Color _warning = Color(0xFFF79009);
  static const Color _warningSoft = Color(0xFFFFFAEB);
  static const Color _warningText = Color(0xFFB54708);

  // Light neutrals
  static const Color _bgLight = Color(0xFFF6F7F9);
  static const Color _surfaceLight = Colors.white;
  static const Color _borderLight = Color(0xFFEAECEF);
  static const Color _dividerLight = Color(0xFFF1F3F5);
  static const Color _chipBgLight = Color(0xFFF1F3F5);
  static const Color _mutedTextLight = Color(0xFF98A2B3);
  static const Color _subTextLight = Color(0xFF667085);
  static const Color _bodyTextLight = Color(0xFF344054);
  static const Color _headingLight = Color(0xFF101828);

  // Dark neutrals
  static const Color _bgDark = Color(0xFF0E1217);
  static const Color _surfaceDark = Color(0xFF161B22);
  static const Color _surfaceAltDark = Color(0xFF1C2128);
  static const Color _borderDark = Color(0xFF2A3038);
  static const Color _dividerDark = Color(0xFF1F242C);
  static const Color _chipBgDark = Color(0xFF1F242C);
  static const Color _mutedTextDark = Color(0xFF6B7280);
  static const Color _subTextDark = Color(0xFF8B95A4);
  static const Color _bodyTextDark = Color(0xFFD4DAE4);
  static const Color _headingDark = Color(0xFFF5F7FA);

  // Base
  Color get background => isDark ? _bgDark : _bgLight;
  Color get surface => isDark ? _surfaceDark : _surfaceLight;
  Color get surfaceAlt => isDark ? _surfaceAltDark : _surfaceLight;
  Color get border => isDark ? _borderDark : _borderLight;
  Color get divider => isDark ? _dividerDark : _dividerLight;
  Color get chipBg => isDark ? _chipBgDark : _chipBgLight;
  Color get mutedText => isDark ? _mutedTextDark : _mutedTextLight;
  Color get subText => isDark ? _subTextDark : _subTextLight;
  Color get bodyText => isDark ? _bodyTextDark : _bodyTextLight;
  Color get textPrimary => isDark ? _headingDark : _headingLight;

  // Brand & semantic
  // Accent — mirrors AppColors.primary so the active broker's brand
  // colour flows through every chip, badge and tab indicator.
  Color get brand => AppColors.primary;
  Color get brandSoft => isDark
      ? AppColors.primary.withValues(alpha: 0.18)
      : _brandSoft;
  Color get success => _success;
  Color get successSoft => isDark
      ? _success.withValues(alpha: 0.18)
      : _successSoft;
  Color get successText => _successText;
  Color get danger => _danger;
  Color get dangerSoft => isDark
      ? _danger.withValues(alpha: 0.18)
      : _dangerSoft;
  Color get dangerText => _dangerText;
  Color get warning => _warning;
  Color get warningSoft => isDark
      ? _warning.withValues(alpha: 0.18)
      : _warningSoft;
  Color get warningText => _warningText;

  // Subtle elevation for cards
  List<BoxShadow> get cardShadow => isDark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0F101828),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ];

  BoxDecoration cardDecoration({double radius = 16}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: cardShadow,
      );

  BoxDecoration chipDecoration({Color? color}) => BoxDecoration(
        color: color ?? chipBg,
        borderRadius: BorderRadius.circular(999),
      );
}
