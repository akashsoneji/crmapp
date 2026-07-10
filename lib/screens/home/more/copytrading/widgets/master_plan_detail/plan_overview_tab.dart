import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_plan_detail_controller.dart';
import 'plan_detail_shared.dart';
import 'plan_detail_tokens.dart';

/// "Overview" tab — Performance, Equity curve, Commission summary,
/// Settlement, Copier rules, Strategy & risk disclosure, Account & system.
class PlanOverviewTab extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;

  const PlanOverviewTab({
    super.key,
    required this.plan,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    // Plain Column — let the outer ListView own scrolling. Nested
    // scrollables (with shrinkWrap) caused per-frame relayout and
    // visible scroll jank.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PerformanceSection(plan: plan, tokens: tokens),
        const SizedBox(height: 12),
        _EquitySection(plan: plan, tokens: tokens),
        const SizedBox(height: 12),
        _CommissionSummarySection(plan: plan, tokens: tokens),
        const SizedBox(height: 12),
        _SettlementSection(plan: plan, tokens: tokens),
        const SizedBox(height: 12),
        _RulesSection(plan: plan, tokens: tokens),
        const SizedBox(height: 12),
        _StrategySection(plan: plan, tokens: tokens),
        const SizedBox(height: 12),
        _AccountSection(plan: plan, tokens: tokens),
      ],
    );
  }
}

// ─── Performance ───────────────────────────────────────────────────────────

class _PerformanceSection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _PerformanceSection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final perf = plan.performance;
    return PlanSectionCard(
      title: 'Performance',
      subtitle: '${perf.closedTrades} closed trades',
      tokens: tokens,
      accent: tokens.success,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.4,
        children: [
          PlanMetricTile(
            icon: Icons.percent_rounded,
            label: 'Win rate',
            value: PlanFormat.percent(perf.winRate, digits: 2),
            tokens: tokens,
            valueColor: tokens.successText,
          ),
          PlanMetricTile(
            icon: Icons.calculate_outlined,
            label: 'Profit factor',
            value: perf.profitFactor.toStringAsFixed(2),
            tokens: tokens,
          ),
          PlanMetricTile(
            icon: Icons.arrow_upward_rounded,
            label: 'Avg win',
            value: PlanFormat.money(perf.avgWin),
            tokens: tokens,
            valueColor: tokens.successText,
          ),
          PlanMetricTile(
            icon: Icons.arrow_downward_rounded,
            label: 'Avg loss',
            value: PlanFormat.money(perf.avgLoss),
            tokens: tokens,
            valueColor: tokens.dangerText,
          ),
          PlanMetricTile(
            icon: Icons.trending_up_rounded,
            label: 'Expectancy',
            value: PlanFormat.money(perf.expectancy),
            tokens: tokens,
            valueColor: perf.expectancy >= 0
                ? tokens.successText
                : tokens.dangerText,
          ),
          PlanMetricTile(
            icon: Icons.south_east_rounded,
            label: 'Max drawdown',
            value: PlanFormat.money(perf.maxDrawdown),
            tokens: tokens,
            valueColor: tokens.dangerText,
          ),
          PlanMetricTile(
            icon: Icons.show_chart_rounded,
            label: 'Gross profit',
            value: PlanFormat.money(perf.grossProfit),
            tokens: tokens,
            valueColor: tokens.successText,
          ),
          PlanMetricTile(
            icon: Icons.trending_down_rounded,
            label: 'Gross loss',
            value: PlanFormat.money(perf.grossLoss),
            tokens: tokens,
            valueColor: tokens.dangerText,
          ),
        ],
      ),
    );
  }
}

// ─── Equity curve ──────────────────────────────────────────────────────────

class _EquitySection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _EquitySection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return PlanSectionCard(
      title: 'Equity curve',
      subtitle: 'Last 90 days',
      tokens: tokens,
      accent: tokens.success,
      child: _EquityChart(equity: plan.equityCurve, tokens: tokens),
    );
  }
}

class _EquityChart extends StatelessWidget {
  final List<CopyTradingPlanEquityCurvePoint> equity;
  final PlanTokens tokens;
  const _EquityChart({required this.equity, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final pts = <_Pt>[];
    for (final p in equity) {
      if (p.date.isEmpty) continue;
      try {
        pts.add(_Pt(DateTime.parse(p.date), p.equity.toDouble()));
      } catch (_) {}
    }

    if (pts.length < 2) {
      return PlanEmptyHint(message: 'No equity data yet', tokens: tokens);
    }

    final spots = [
      for (int i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i].v),
    ];
    final minY = pts.map((e) => e.v).reduce((a, b) => a < b ? a : b);
    final maxY = pts.map((e) => e.v).reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final padY = range * 0.15 + 1;
    final chartMin = minY - padY;
    final chartMax = maxY + padY;
    final yInterval = ((chartMax - chartMin) / 4).abs();
    final xInterval = (pts.length / 5).clamp(1, pts.length).toDouble();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: chartMin,
          maxY: chartMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: tokens.divider,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: xInterval,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= pts.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('MMM d').format(pts[idx].d),
                      style: TextStyle(
                        fontSize: 9,
                        color: tokens.mutedText,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    PlanFormat.compactMoney(value),
                    style: TextStyle(
                      fontSize: 9,
                      color: tokens.mutedText,
                    ),
                  ),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: tokens.success,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: tokens.success.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pt {
  final DateTime d;
  final double v;
  _Pt(this.d, this.v);
}

// ─── Commission summary ────────────────────────────────────────────────────

class _CommissionSummarySection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _CommissionSummarySection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final c = plan.commissionSummary;
    return PlanSectionCard(
      title: 'Commission summary',
      subtitle: 'Earned & pending payouts',
      tokens: tokens,
      accent: tokens.warning,
      child: Column(
        children: [
          PlanKeyValueRow(
            label: 'Lifetime',
            value: PlanFormat.money(c.lifetime),
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'This month',
            value: PlanFormat.money(c.thisMonth),
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Pending',
            value: PlanFormat.money(c.pending),
            valueColor: tokens.warningText,
            tokens: tokens,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.warningSoft,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                c.pendingSource.isEmpty
                    ? '—'
                    : c.pendingSource.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  color: tokens.warningText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Settled',
            value: PlanFormat.money(c.settled),
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

// ─── Settlement ────────────────────────────────────────────────────────────

class _SettlementSection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _SettlementSection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final s = plan.settlement;
    return PlanSectionCard(
      title: 'Settlement',
      subtitle: 'How & when pending commissions are paid',
      tokens: tokens,
      accent: tokens.warning,
      child: Column(
        children: [
          PlanKeyValueRow(
            label: 'Cycle',
            value: PlanFormat.capitalize(s.cycle.isEmpty ? '—' : s.cycle),
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Last settled',
            value: s.lastSettledAt.isEmpty
                ? '—'
                : PlanFormat.isoToDateTime(s.lastSettledAt),
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Next payout',
            value: s.nextPayoutAt.isEmpty
                ? '—'
                : PlanFormat.isoToDateTime(s.nextPayoutAt),
            tokens: tokens,
            trailing: s.isDue
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.warningSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Due now',
                      style: TextStyle(
                        fontSize: 10,
                        color: tokens.warningText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── Copier rules & fees ───────────────────────────────────────────────────

class _RulesSection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _RulesSection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final cap = plan.maxCopiers == 0
        ? '∞'
        : '${plan.activeCopiers} / ${plan.maxCopiers}';
    return PlanSectionCard(
      title: 'Copier rules & fees',
      subtitle: 'How copiers join and what they pay',
      tokens: tokens,
      child: Column(
        children: [
          PlanKeyValueRow(
            label: 'Minimum capital',
            value: PlanFormat.money(plan.minimumCapital),
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Active / cap',
            value: cap,
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Plan full',
            value: plan.isFull ? 'Yes' : 'No',
            valueColor: plan.isFull ? tokens.dangerText : tokens.successText,
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Commission',
            value: plan.commissionLabel.isNotEmpty
                ? plan.commissionLabel
                : '${plan.commissionPercentage}%',
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Type',
            value: PlanFormat.capitalize(
                plan.commissionType.isEmpty ? 'per_trade' : plan.commissionType),
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

// ─── Strategy & risk ───────────────────────────────────────────────────────

class _StrategySection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _StrategySection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return PlanSectionCard(
      title: 'Strategy & risk',
      subtitle: 'What copiers see before subscribing',
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelText(
            label: 'STRATEGY',
            body: plan.strategyDescription.isEmpty
                ? 'Not provided.'
                : plan.strategyDescription,
            tokens: tokens,
          ),
          const SizedBox(height: 14),
          _LabelText(
            label: 'RISK',
            body: plan.riskInformation.isEmpty
                ? 'Not provided.'
                : plan.riskInformation,
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  final String label;
  final String body;
  final PlanTokens tokens;
  const _LabelText({
    required this.label,
    required this.body,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: tokens.mutedText,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            fontSize: 13,
            color: tokens.bodyText,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ─── Account & system ──────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _AccountSection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final server = plan.tradingServer.isNotEmpty
        ? plan.tradingServer
        : plan.lpProviderName.isEmpty
            ? '—'
            : plan.lpProviderName;
    return PlanSectionCard(
      title: 'Account & system',
      subtitle: 'Routing & metadata',
      tokens: tokens,
      child: Column(
        children: [
          PlanKeyValueRow(
            label: 'Status',
            value: PlanFormat.capitalize(plan.status),
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Copying',
            value: plan.copyingPaused ? 'Paused' : 'Active',
            valueColor:
                plan.copyingPaused ? tokens.warningText : tokens.successText,
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Server',
            value: server,
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Trading account',
            value: plan.tradingAccountNumber.isEmpty
                ? '—'
                : plan.tradingAccountNumber,
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Initial equity',
            value: plan.initialEquitySnapshot == 0
                ? '—'
                : PlanFormat.money(plan.initialEquitySnapshot),
            tokens: tokens,
          ),
          PlanDivider(tokens: tokens),
          PlanKeyValueRow(
            label: 'Created',
            value: PlanFormat.isoToDate(plan.createdAt),
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}
