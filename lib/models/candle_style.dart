import 'dart:convert';

import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';

import '../constants/color.dart';

/// Reserved enum for future use — `candlesticks` v3 does not expose log
/// scale in the public API yet, but exposing a stable type now lets the
/// UI toggle persist across versions.
enum ScaleMode { linear, log }

/// Wraps a [CandleSticksStyle] with extra runtime preferences.
///
/// `candlesticks` v3 only exposes chart colors through [CandleSticksStyle] —
/// log/linear scale, visible-item count, and time-axis visibility are
/// controlled internally by the widget's gesture handlers in v3 (they are
/// not part of the public Dart API). We model them here so that when the
/// upstream package promotes them to public API, we can flip a single line
/// to expose them. For now they're persisted but acknowledged as no-ops.
@immutable
class CandleStyle {
  /// The underlying chart visual style. Null means: pick from theme.
  final CandleSticksStyle? style;

  /// Linear vs logarithmic price scale (reserved — no public API in v3 yet).
  final ScaleMode scaleMode;

  /// How many candles are visible at once (reserved — no public API in v3 yet).
  final int itemCount;

  /// Show the time axis at the bottom (reserved — no public API in v3 yet).
  final bool showTimeAxis;

  const CandleStyle({
    this.style,
    this.scaleMode = ScaleMode.linear,
    this.itemCount = 50,
    this.showTimeAxis = true,
  });

  CandleStyle copyWith({
    CandleSticksStyle? style,
    ScaleMode? scaleMode,
    int? itemCount,
    bool? showTimeAxis,
  }) {
    return CandleStyle(
      style: style ?? this.style,
      scaleMode: scaleMode ?? this.scaleMode,
      itemCount: itemCount ?? this.itemCount,
      showTimeAxis: showTimeAxis ?? this.showTimeAxis,
    );
  }

  /// Sensible dark preset tuned for the brand. Bull/bear colours match
  /// the TradingView default so it feels familiar to MT5 users.
  static CandleStyle darkPreset({Color? brandColor}) {
    final accent = brandColor ?? AppColors.brandPrimary;
    return CandleStyle(
      style: CandleSticksStyle.dark(
        candleBullColor: const Color(0xFF26A69A),
        candleBearColor: const Color(0xFFEF5350),
        loadingIndicatorColor: accent,
        crosshairLineColor: accent.withOpacity(0.6),
        crosshairLabelBackgroundColor: accent,
      ),
    );
  }

  /// Sensible light preset.
  static CandleStyle lightPreset({Color? brandColor}) {
    final accent = brandColor ?? AppColors.brandPrimary;
    return CandleStyle(
      style: CandleSticksStyle.light(
        candleBullColor: const Color(0xFF26A69A),
        candleBearColor: const Color(0xFFEF5350),
        loadingIndicatorColor: accent,
        crosshairLineColor: accent.withOpacity(0.6),
        crosshairLabelBackgroundColor: accent,
      ),
    );
  }

  /// Resolves the active theme based on the app's current dark-mode flag.
  static CandleStyle forCurrentTheme({Color? brandColor}) {
    return AppColors.isDarkMode
        ? CandleStyle.darkPreset(brandColor: brandColor)
        : CandleStyle.lightPreset(brandColor: brandColor);
  }

  /// Smaller style for embedded previews (pending-order, close-position
  /// etc.). For now just aliases to the main preset; finer-grained
  /// overrides can be added later.
  static CandleStyle compact({bool dark = true, Color? brandColor}) {
    return dark
        ? darkPreset(brandColor: brandColor)
        : lightPreset(brandColor: brandColor);
  }

  // ---------------------------------------------------------------------------
  // JSON (de)serialization for SharedPreferences persistence.
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'scaleMode': scaleMode == ScaleMode.log ? 'log' : 'linear',
      'itemCount': itemCount,
      'showTimeAxis': showTimeAxis,
      // Style colors are intentionally NOT persisted yet — they default from
      // the current theme on each launch. Persisting them would require us to
      // serialize 21 individual Color values and migrate every time we add a
      // new field on CandleSticksStyle. Add later if user-driven color
      // customization becomes a product requirement.
    };
  }

  factory CandleStyle.fromJson(Map<String, dynamic> json) {
    final scale = json['scaleMode'] as String?;
    return CandleStyle(
      scaleMode: scale == 'log' ? ScaleMode.log : ScaleMode.linear,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 50,
      showTimeAxis: json['showTimeAxis'] as bool? ?? true,
    );
  }

  String encode() => jsonEncode(toJson());
  static CandleStyle decode(String src) {
    try {
      final raw = jsonDecode(src);
      if (raw is Map<String, dynamic>) return CandleStyle.fromJson(raw);
    } catch (_) {}
    return CandleStyle.forCurrentTheme();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CandleStyle &&
        other.scaleMode == scaleMode &&
        other.itemCount == itemCount &&
        other.showTimeAxis == showTimeAxis;
  }

  @override
  int get hashCode => Object.hash(scaleMode, itemCount, showTimeAxis);
}