import 'package:crm_app/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'plan_detail_tokens.dart';

/// Generic section card used throughout the Plan Detail screen.
/// ODDA-style: rounded 16px, soft elevation, clean header row.
class PlanSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final PlanTokens tokens;
  final Color? accent;
  final Widget? trailing;
  final EdgeInsets padding;
  final double radius;

  const PlanSectionCard({
    super.key,
    required this.title,
    required this.child,
    required this.tokens,
    this.subtitle,
    this.accent,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? tokens.brand;
    return Container(
      width: double.infinity,
      decoration: tokens.cardDecoration(radius: radius),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: a,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: tokens.mutedText,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Status pill — small, soft-tinted, rounded.
class PlanStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color soft;
  final Color text;
  final PlanTokens tokens;

  PlanStatusPill({
    super.key,
    required this.label,
    required this.tokens,
    Color? color,
    Color? soft,
    Color? text,
  })  : color = color ?? AppColors.primary,
        soft = soft ?? const Color(0xFFEEF2FF),
        text = text ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.isDark ? color.withValues(alpha: 0.18) : soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: text, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: text,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact key-value row used inside cards (e.g. settings-style lists).
class PlanKeyValueRow extends StatelessWidget {
  final String label;
  final String? description;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  final PlanTokens tokens;

  const PlanKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    required this.tokens,
    this.description,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final desc = description;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: tokens.subText,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                if (desc != null && desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: tokens.mutedText,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? tokens.textPrimary,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(height: 4),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Thin horizontal divider inside cards.
class PlanDivider extends StatelessWidget {
  final PlanTokens tokens;
  const PlanDivider({super.key, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: tokens.divider);
  }
}

/// Empty-state for sections with no data.
class PlanEmptyHint extends StatelessWidget {
  final String message;
  final IconData icon;
  final PlanTokens tokens;
  const PlanEmptyHint({
    super.key,
    required this.message,
    required this.tokens,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, size: 32, color: tokens.mutedText),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: tokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact "metric tile" — 2xN grid item for KPIs.
class PlanMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final PlanTokens tokens;
  const PlanMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.tokens,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: tokens.subText),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: tokens.mutedText,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor ?? tokens.textPrimary,
                height: 1.0,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helpers for parsing & formatting shared across tabs.
class PlanFormat {
  static String money(num v, {String currency = '\$'}) {
    final negative = v < 0;
    final abs = v.abs();
    final fixed = abs >= 1000
        ? NumberFormat('#,##0.00').format(abs)
        : abs.toStringAsFixed(2);
    return '${negative ? '-' : ''}$currency$fixed';
  }

  static String compactMoney(num v, {String currency = '\$'}) {
    return NumberFormat.compactCurrency(symbol: currency).format(v);
  }

  static String percent(num v, {int digits = 1}) =>
      '${v.toStringAsFixed(digits)}%';

  static String isoToDate(String iso, {String fmt = 'd MMM yyyy'}) {
    if (iso.isEmpty) return '—';
    try {
      return DateFormat(fmt).format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String isoToDateTime(String iso) {
    if (iso.isEmpty) return '—';
    try {
      return DateFormat('d MMM yyyy, HH:mm').format(
        DateTime.parse(iso).toLocal(),
      );
    } catch (_) {
      return iso;
    }
  }

  static String capitalize(String s) {
    if (s.isEmpty) return '—';
    return s[0].toUpperCase() + s.substring(1);
  }
}
