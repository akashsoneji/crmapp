import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_plan_detail_controller.dart';
import 'plan_detail_shared.dart';
import 'plan_detail_tokens.dart';

/// "Trades" tab — Open positions + Recent trade history.
class PlanTradesTab extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;

  const PlanTradesTab({super.key, required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    // Return a plain Column — the outer screen's ListView owns the
    // scroll physics. Nested scrollables caused visible jank and
    // inconsistent momentum ("stops on the right side").
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _OpenPositionsSection(plan: plan, tokens: tokens),
        const SizedBox(height: 12),
        _TradeHistorySection(plan: plan, tokens: tokens),
      ],
    );
  }
}

class _OpenPositionsSection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _OpenPositionsSection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final open = plan.openPositionsDetail;
    return PlanSectionCard(
      title: 'Open positions',
      subtitle: '${open.length} active',
      tokens: tokens,
      accent: tokens.brand,
      child: open.isEmpty
          ? PlanEmptyHint(
              message: 'No open positions right now',
              icon: Icons.layers_clear_outlined,
              tokens: tokens,
            )
          : Column(
              children: [
                for (int i = 0; i < open.length; i++) ...[
                  if (i > 0) PlanDivider(tokens: tokens),
                  _OpenPositionRow(item: open[i], tokens: tokens),
                ],
              ],
            ),
    );
  }
}

class _OpenPositionRow extends StatelessWidget {
  final PlanOpenPositionItem item;
  final PlanTokens tokens;
  const _OpenPositionRow({required this.item, required this.tokens});

  @override
  @override
  Widget build(BuildContext context) {
    final isBuy = item.direction.toLowerCase() == 'buy';
    final dirColor = isBuy ? tokens.success : tokens.danger;
    // RepaintBoundary keeps each row's render layer isolated so that
    // scrolling doesn't trigger relayout of neighbouring rows.
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
                color: dirColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                isBuy
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: dirColor,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: dirColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.direction.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: dirColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Vol ${item.masterVolume} • Open @ ${item.openPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: tokens.mutedText),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  PlanFormat.money(item.profit),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: item.profit >= 0
                        ? tokens.successText
                        : tokens.dangerText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.copierAccount.isEmpty ? '—' : item.copierAccount,
                  style: TextStyle(fontSize: 10.5, color: tokens.mutedText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TradeHistorySection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _TradeHistorySection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final trades = plan.tradeHistory;
    return PlanSectionCard(
      title: 'Recent trades',
      subtitle: '${trades.length} shown',
      tokens: tokens,
      accent: tokens.success,
      child: trades.isEmpty
          ? PlanEmptyHint(
              message: 'No trade history yet',
              icon: Icons.history_toggle_off_outlined,
              tokens: tokens,
            )
          : Column(
              children: [
                for (int i = 0; i < trades.length; i++) ...[
                  if (i > 0) PlanDivider(tokens: tokens),
                  _TradeRow(item: trades[i], tokens: tokens),
                ],
              ],
            ),
    );
  }
}

class _TradeRow extends StatelessWidget {
  final CopyTradingMasterTradeHistoryItem item;
  final PlanTokens tokens;
  const _TradeRow({required this.item, required this.tokens});

  @override
  @override
  Widget build(BuildContext context) {
    final isBuy = item.direction.toLowerCase() == 'buy';
    final isWin = item.masterProfit > 0;
    final dirColor = isBuy ? tokens.success : tokens.danger;
    final pnlColor = isWin ? tokens.successText : tokens.dangerText;
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
                color: dirColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                isBuy
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: dirColor,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: dirColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.direction.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: dirColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          '${item.masterVolume}',
                          style: TextStyle(
                            fontSize: 10,
                            color: tokens.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.copierAccount}',
                    style: TextStyle(fontSize: 11, color: tokens.mutedText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtRange(item.openTime, item.closeTime),
                    style: TextStyle(fontSize: 10, color: tokens.mutedText),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  PlanFormat.money(item.masterProfit),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: pnlColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Master P&L',
                  style: TextStyle(fontSize: 9.5, color: tokens.mutedText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtRange(String open, String close) {
    final o = _short(open);
    final c = _short(close);
    if (o == '—' && c == '—') return '—';
    if (o == '—') return 'Closed $c';
    if (c == '—') return 'Opened $o';
    return '$o → $c';
  }

  String _short(String iso) {
    if (iso.isEmpty) return '—';
    try {
      return DateFormat('d MMM, HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
