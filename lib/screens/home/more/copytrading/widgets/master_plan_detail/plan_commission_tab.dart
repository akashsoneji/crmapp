import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_plan_detail_controller.dart';
import 'plan_detail_shared.dart';
import 'plan_detail_tokens.dart';

/// "Commission" tab — Settlement + Recent commission history.
class PlanCommissionTab extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;

  const PlanCommissionTab({
    super.key,
    required this.plan,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final c = plan.commissionHistory;
    // Plain Column — let the outer screen's ListView handle scrolling.
    // Nested scrollables caused jitter and inconsistent momentum.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CommissionTotalsSection(plan: plan, tokens: tokens),
        const SizedBox(height: 12),
        _CommissionHistorySection(history: c, tokens: tokens),
      ],
    );
  }
}

class _CommissionTotalsSection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _CommissionTotalsSection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final s = plan.commissionSummary;
    return PlanSectionCard(
      title: 'Commission totals',
      subtitle: 'Earnings across all cycles',
      tokens: tokens,
      accent: tokens.warning,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.4,
        children: [
          PlanMetricTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Lifetime',
            value: PlanFormat.money(s.lifetime),
            tokens: tokens,
            valueColor: tokens.successText,
          ),
          PlanMetricTile(
            icon: Icons.calendar_month_outlined,
            label: 'This month',
            value: PlanFormat.money(s.thisMonth),
            tokens: tokens,
            valueColor: tokens.successText,
          ),
          PlanMetricTile(
            icon: Icons.hourglass_top_rounded,
            label: 'Pending',
            value: PlanFormat.money(s.pending),
            tokens: tokens,
            valueColor: tokens.warningText,
          ),
          PlanMetricTile(
            icon: Icons.check_circle_outline_rounded,
            label: 'Settled',
            value: PlanFormat.money(s.settled),
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

class _CommissionHistorySection extends StatelessWidget {
  final List<CopyTradingMasterCommissionHistoryItem> history;
  final PlanTokens tokens;
  const _CommissionHistorySection({
    required this.history,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return PlanSectionCard(
      title: 'Commission history',
      subtitle: '${history.length} entries',
      tokens: tokens,
      accent: tokens.warning,
      child: history.isEmpty
          ? PlanEmptyHint(
              message: 'No commissions settled yet',
              icon: Icons.receipt_long_outlined,
              tokens: tokens,
            )
          : Column(
              children: [
                for (int i = 0; i < history.length; i++) ...[
                  if (i > 0) PlanDivider(tokens: tokens),
                  _CommissionRow(item: history[i], tokens: tokens),
                ],
              ],
            ),
    );
  }
}

class _CommissionRow extends StatelessWidget {
  final CopyTradingMasterCommissionHistoryItem item;
  final PlanTokens tokens;
  const _CommissionRow({required this.item, required this.tokens});

  @override
  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates each row's repaint — keeps scrolling
    // smooth on long lists by avoiding neighbour-row relayouts.
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.warningSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.payments_outlined,
                color: tokens.warningText,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.symbol,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (item.inGracePeriod)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.brandSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Grace',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: tokens.brand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Trade #${item.tradeMappingId} • ${item.copierAccount}',
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(item.settledAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: tokens.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  PlanFormat.money(item.commissionCharged),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Profit share ${PlanFormat.money(item.grossProfitShare)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: tokens.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      return DateFormat('d MMM yyyy, HH:mm')
          .format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
