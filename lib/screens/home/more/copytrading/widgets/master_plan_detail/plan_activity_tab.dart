import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_master_plan_detail_controller.dart';
import 'plan_detail_shared.dart';
import 'plan_detail_tokens.dart';

/// "Activity" tab — Recent activity feed + Plan timeline.
class PlanActivityTab extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;

  const PlanActivityTab({super.key, required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    // Plain Column — let the outer ListView own scrolling. Nested
    // scrollables caused visible jank and inconsistent overscroll feel.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActivityFeedSection(plan: plan, tokens: tokens),
        const SizedBox(height: 12),
        _TimelineSection(plan: plan, tokens: tokens),
      ],
    );
  }
}

class _ActivityFeedSection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _ActivityFeedSection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final feed = plan.activityFeed;
    return PlanSectionCard(
      title: 'Activity feed',
      subtitle: 'Most recent events',
      tokens: tokens,
      accent: tokens.brand,
      child: feed.isEmpty
          ? PlanEmptyHint(
              message: 'No recent activity',
              icon: Icons.notifications_none_outlined,
              tokens: tokens,
            )
          : Column(
              children: [
                for (int i = 0; i < feed.length; i++) ...[
                  if (i > 0) PlanDivider(tokens: tokens),
                  _FeedRow(item: feed[i], tokens: tokens),
                ],
              ],
            ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  final CopyTradingPlanActivityFeedItem item;
  final PlanTokens tokens;
  const _FeedRow({required this.item, required this.tokens});

  ({Color color, Color soft, Color text, IconData icon}) _resolve() {
    final t = item.type.toLowerCase();
    if (t == 'trade_closed') {
      final positive = item.subtitle.contains('+');
      return (
        color: positive ? tokens.success : tokens.danger,
        soft: positive ? tokens.successSoft : tokens.dangerSoft,
        text: positive ? tokens.successText : tokens.dangerText,
        icon: positive
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
      );
    }
    if (t.contains('commission')) {
      return (
        color: tokens.warning,
        soft: tokens.warningSoft,
        text: tokens.warningText,
        icon: Icons.payments_outlined,
      );
    }
    if (t.contains('plan')) {
      return (
        color: tokens.brand,
        soft: tokens.brandSoft,
        text: tokens.brand,
        icon: Icons.flag_outlined,
      );
    }
    return (
      color: tokens.brand,
      soft: tokens.brandSoft,
      text: tokens.brand,
      icon: Icons.bolt_outlined,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final r = _resolve();
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
                color: tokens.isDark ? r.color.withValues(alpha: 0.18) : r.soft,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(r.icon, color: r.text, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: r.text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _fmtTime(item.at),
                    style: TextStyle(fontSize: 10, color: tokens.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(String iso) {
    if (iso.isEmpty) return '—';
    try {
      return DateFormat('d MMM, HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}

class _TimelineSection extends StatelessWidget {
  final CopyTradingMasterPlanDetail plan;
  final PlanTokens tokens;
  const _TimelineSection({required this.plan, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return PlanSectionCard(
      title: 'Plan timeline',
      subtitle: 'Lifecycle events',
      tokens: tokens,
      accent: tokens.brand,
      child: plan.timeline.isEmpty
          ? PlanEmptyHint(
              message: 'No timeline events',
              icon: Icons.timeline_outlined,
              tokens: tokens,
            )
          : Column(
              children: [
                for (int i = 0; i < plan.timeline.length; i++) ...[
                  if (i > 0) PlanDivider(tokens: tokens),
                  _TimelineRow(
                    item: plan.timeline[i],
                    isLast: i == plan.timeline.length - 1,
                    tokens: tokens,
                  ),
                ],
              ],
            ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final CopyTradingPlanTimelineItem item;
  final bool isLast;
  final PlanTokens tokens;
  const _TimelineRow({
    required this.item,
    required this.isLast,
    required this.tokens,
  });

  Color _dotColor() {
    switch (item.kind.toLowerCase()) {
      case 'approved':
        return tokens.success;
      case 'created':
        return tokens.brand;
      case 'paused':
        return tokens.warning;
      case 'inactive':
      case 'inactivated':
        return tokens.mutedText;
      default:
        return tokens.subText;
    }
  }

  String _fmt(String iso) {
    if (iso.isEmpty) return '—';
    try {
      return DateFormat(
        'd MMM yyyy, HH:mm',
      ).format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    // RepaintBoundary keeps each timeline row's render layer isolated.
    return RepaintBoundary(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: _dotColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: tokens.border)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _fmt(item.at),
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const SizedBox(height: 2),
                    Text(
                      item.detail,
                      style: TextStyle(fontSize: 11.5, color: tokens.subText),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
