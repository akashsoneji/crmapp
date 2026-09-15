import 'package:crm_app/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_plan_detail_controller.dart';
import 'plan_detail_shared.dart';
import 'plan_detail_tokens.dart';

/// Top hero card — plan identity + key metrics + actions.
class PlanHeroCard extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final CopyTradingMasterPlanDetailController controller;
  final PlanTokens tokens;

  /// Optional override for the Edit action — when omitted the button
  /// is rendered but does nothing (matches the original stub).
  final VoidCallback? onEdit;

  /// Optional override for the Inactivate action — when omitted the
  /// plan is inactivated immediately with no confirmation.
  final VoidCallback? onConfirmInactivate;

  const PlanHeroCard({
    super.key,
    required this.plan,
    required this.controller,
    required this.tokens,
    this.onEdit,
    this.onConfirmInactivate,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'P';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  ({Color color, Color soft, Color text}) _statusColor() {
    switch (plan.status.toLowerCase()) {
      case 'approved':
      case 'active':
        return (
          color: tokens.success,
          soft: tokens.successSoft,
          text: tokens.successText,
        );
      case 'paused':
        return (
          color: tokens.warning,
          soft: tokens.warningSoft,
          text: tokens.warningText,
        );
      case 'inactive':
      case 'inactivated':
        return (
          color: tokens.mutedText,
          soft: tokens.chipBg,
          text: tokens.mutedText,
        );
      default:
        return (
          color: tokens.brand,
          soft: tokens.brandSoft,
          text: tokens.brand,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = plan.status.toLowerCase() == 'paused';
    final isInactive =
        plan.status.toLowerCase() == 'inactive' ||
        plan.status.toLowerCase() == 'inactivated';
    final isCopyingOn = !plan.copyingPaused;
    final s = _statusColor();

    return Container(
      decoration: tokens.cardDecoration(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [tokens.brand, tokens.brand.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(plan.planName),
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          plan.planName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        _CopyingDotPill(on: isCopyingOn, tokens: tokens),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        PlanStatusPill(
                          label: PlanFormat.capitalize(
                            plan.status.isEmpty ? 'Unknown' : plan.status,
                          ),
                          tokens: tokens,
                          color: s.color,
                          soft: s.soft,
                          text: s.text,
                        ),
                        if (plan.commissionLabel.isNotEmpty)
                          _MetaChip(text: plan.commissionLabel, tokens: tokens),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hero metrics — AUM + Net P&L with mini equity sparkline
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Plan AUM',
                  value: PlanFormat.money(plan.totalCapital),
                  accent: tokens.brand,
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Net P&L',
                  value: PlanFormat.money(plan.performance.netPnl),
                  accent: plan.performance.netPnl >= 0
                      ? tokens.success
                      : tokens.danger,
                  tokens: tokens,
                  spark: _buildSparkline(plan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action row
          Row(
            children: [
              Expanded(
                child: _HeroAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: onEdit ?? () {},
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroAction(
                  icon: isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  label: isPaused ? 'Resume' : 'Pause',
                  onTap: () {
                    if (isPaused) {
                      controller.resumePlan();
                    } else {
                      controller.pausePlan();
                    }
                  },
                  accent: tokens.warning,
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroAction(
                  icon: Icons.block_outlined,
                  label: 'Inactivate',
                  onTap: onConfirmInactivate ?? controller.inactivatePlan,
                  accent: tokens.danger,
                  disabled: isInactive,
                  tokens: tokens,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a tiny sparkline for the equity curve. Returns null if no data.
  FlChartData? _buildSparkline(CopyTradingMasterPlanDetail plan) {
    final pts = <double>[];
    for (final p in plan.equityCurve) {
      pts.add(p.equity.toDouble());
    }
    if (pts.length < 2) return null;
    return FlChartData(spots: pts);
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final PlanTokens tokens;
  final FlChartData? spark;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.accent,
    required this.tokens,
    this.spark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tokens.isDark
            ? accent.withValues(alpha: 0.14)
            : accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: tokens.isDark ? 0.30 : 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: tokens.subText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: tokens.textPrimary,
                height: 1.05,
                letterSpacing: -0.4,
              ),
              maxLines: 1,
            ),
          ),
          if (spark != null && spark!.spots.length >= 2) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 1,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  minY: spark!.spots.reduce((a, b) => a < b ? a : b),
                  maxY: spark!.spots.reduce((a, b) => a > b ? a : b),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < spark!.spots.length; i++)
                          FlSpot(i.toDouble(), spark!.spots[i]),
                      ],
                      isCurved: true,
                      color: accent,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: accent.withValues(alpha: 0.18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Wrapper struct for sparkline spots (just a List<double> essentially).
class FlChartData {
  final List<double> spots;
  FlChartData({required this.spots});
}

class _MetaChip extends StatelessWidget {
  final String text;
  final PlanTokens tokens;
  const _MetaChip({required this.text, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: tokens.chipDecoration(),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          color: tokens.bodyText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CopyingDotPill extends StatelessWidget {
  final bool on;
  final PlanTokens tokens;
  const _CopyingDotPill({required this.on, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final color = on ? tokens.success : tokens.mutedText;
    final soft = on ? tokens.successSoft : tokens.chipBg;
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            on ? 'Copying on' : 'Copying off',
            style: TextStyle(
              fontSize: 10.5,
              color: on ? tokens.successText : tokens.mutedText,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;
  final bool disabled;
  final PlanTokens tokens;

  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tokens,
    this.accent,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? tokens.bodyText;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(
            color: disabled
                ? tokens.border
                : c.withValues(alpha: tokens.isDark ? 0.40 : 0.30),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: disabled ? tokens.mutedText : c),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: disabled ? tokens.mutedText : c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
