import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show NumberFormat;

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/models/trading_central_model.dart';
import 'package:crm_app/screens/common/webview_screen.dart';
import 'package:crm_app/screens/home/more/finance/payment_methods_screen.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/services/trading_central_service.dart';
import 'package:crm_app/widgets/app_svg_back_button.dart';

/// Trading Central tools (calendar, education, technical views, …). Pages
/// open in a WebView; locked ones send the user to Deposit.
class TradingCentralScreen extends StatefulWidget {
  const TradingCentralScreen({super.key});

  @override
  State<TradingCentralScreen> createState() => _TradingCentralScreenState();
}

class _TradingCentralScreenState extends State<TradingCentralScreen> {
  final LanguageService _languageService = Get.find<LanguageService>();
  late Future<TradingCentralSettings> _future;

  @override
  void initState() {
    super.initState();
    _future = TradingCentralService.fetch();
  }

  Future<void> _reload() {
    final future = TradingCentralService.fetch();
    setState(() => _future = future);
    // RefreshIndicator only needs to know when loading ends; the error is
    // shown by the FutureBuilder.
    return future.then((_) {}, onError: (_) {});
  }

  void _openPage(TradingCentralPage page) {
    // Third-party site: our CRM token must never be sent to it.
    Get.to(
      () => WebViewScreen(
        url: page.url,
        title: page.label,
        attachAuthToken: false,
      ),
    );
  }

  Future<void> _openDeposit() async {
    await Get.to(() => PaymentMethodsScreen(accountNumber: ''));
    // A deposit may have unlocked pages; reload so they open right away.
    if (!mounted) return;
    await _reload();
  }

  String _tr(String key, String fallback) =>
      _languageService.trf(key, fallback);

  String _errorText(Object? error) {
    final message = (error?.toString() ?? '')
        .replaceFirst('Exception: ', '')
        .trim();
    if (message.isNotEmpty) return message;
    return _tr('general_something_went_wrong', 'Something went wrong');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TradingCentralSettings>(
      future: _future,
      builder: (context, snapshot) {
        final menuLabel = snapshot.data?.menuLabel ?? '';
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            elevation: 0,
            backgroundColor: AppColors.background,
            centerTitle: true,
            leading: AppSvgBackButton(onPressed: () => Get.back()),
            title: Text(
              menuLabel.isNotEmpty
                  ? menuLabel
                  : _tr('trading_central_title', 'Trading Central'),
              style: AppTextStyles.screenTitle,
            ),
          ),
          body: SafeArea(top: false, child: _buildBody(snapshot)),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<TradingCentralSettings> snapshot) {
    final isWaiting = snapshot.connectionState == ConnectionState.waiting;
    final settings = snapshot.data;

    if (settings == null && (isWaiting || !snapshot.hasError)) {
      return const _LoadingSkeleton();
    }
    if (settings == null) {
      return _StateMessage(
        icon: Icons.cloud_off_rounded,
        message: _errorText(snapshot.error),
        action: FilledButton.icon(
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(_tr('general_retry', 'Retry')),
        ),
      );
    }
    if (settings.pages.isEmpty) {
      return _StateMessage(
        icon: Icons.query_stats_rounded,
        message: _tr(
          'trading_central_empty',
          'No Trading Central tools are available right now.',
        ),
      );
    }
    return _buildList(settings);
  }

  Widget _buildList(TradingCentralSettings settings) {
    final showBanner = settings.depositRequired && !settings.hasFirstDeposit;
    final pages = settings.pages;
    final itemCount = pages.length + (showBanner ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (showBanner && index == 0) {
            return _FirstDepositBanner(
              text: _tr(
                'trading_central_first_deposit_required',
                'Make your first deposit to unlock Trading Central.',
              ),
              onTap: _openDeposit,
            );
          }
          final page = pages[showBanner ? index - 1 : index];
          final canOpen = settings.canAccess && page.canOpen;
          if (canOpen) {
            return _UnlockedPageCard(page: page, onTap: () => _openPage(page));
          }
          return _LockedPageCard(
            page: page,
            subtitle: _lockedSubtitle(page),
            depositLabel: _tr('settings_deposit', 'Deposit'),
            progressLabel:
                '${_formatAmount(settings.depositTotal)} / '
                '${_formatAmount(page.minDeposit)}',
            progress: _progress(settings.depositTotal, page.minDeposit),
            onTap: _openDeposit,
          );
        },
      ),
    );
  }

  String _lockedSubtitle(TradingCentralPage page) {
    if (page.minDeposit <= 0) return _tr('trading_central_locked', 'Locked');
    return _tr(
      'trading_central_deposit_to_unlock',
      'Deposit :amount to unlock',
    ).replaceAll(':amount', _formatAmount(page.minDeposit));
  }

  static double _progress(num total, num required) {
    if (required <= 0) return 0;
    return (total / required).clamp(0.0, 1.0).toDouble();
  }

  static String _formatAmount(num amount) =>
      '\$${NumberFormat.decimalPattern().format(amount)}';
}

IconData _iconForPageKey(String key) {
  final k = key.toLowerCase();
  if (k.contains('calendar')) return Icons.calendar_month_rounded;
  if (k.contains('education')) return Icons.school_rounded;
  if (k.contains('technical')) return Icons.candlestick_chart_rounded;
  if (k.contains('buzz')) return Icons.campaign_rounded;
  if (k.contains('news')) return Icons.newspaper_rounded;
  if (k.contains('idea')) return Icons.lightbulb_outline_rounded;
  if (k.contains('alpha') || k.contains('signal')) {
    return Icons.trending_up_rounded;
  }
  return Icons.query_stats_rounded;
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(
      alpha: 0.06,
    );
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        height: 76,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _StateMessage({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color? background;

  const _CardShell({required this.onTap, required this.child, this.background});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      child: Material(
        color: background ?? colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          // outlineVariant renders as a heavy black border in this theme.
          side: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: const EdgeInsets.all(14), child: child),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const _IconBox({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 24, color: tint),
    );
  }
}

class _FirstDepositBanner extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FirstDepositBanner({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _CardShell(
      onTap: onTap,
      background: colors.primary.withValues(alpha: 0.10),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 20, color: colors.primary),
        ],
      ),
    );
  }
}

class _UnlockedPageCard extends StatelessWidget {
  final TradingCentralPage page;
  final VoidCallback onTap;

  const _UnlockedPageCard({required this.page, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _CardShell(
      onTap: onTap,
      child: Row(
        children: [
          _IconBox(icon: _iconForPageKey(page.key), tint: colors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              page.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _LockedPageCard extends StatelessWidget {
  final TradingCentralPage page;
  final String subtitle;
  final String depositLabel;
  final String progressLabel;
  final double progress;
  final VoidCallback onTap;

  const _LockedPageCard({
    required this.page,
    required this.subtitle,
    required this.depositLabel,
    required this.progressLabel,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = colors.onSurfaceVariant;
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _IconBox(icon: _iconForPageKey(page.key), tint: muted),
                  PositionedDirectional(
                    end: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: muted,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: colors.surface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _DepositChip(label: depositLabel),
            ],
          ),
          if (page.minDeposit > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: colors.primary,
                backgroundColor: colors.primary.withValues(alpha: 0.10),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              progressLabel,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _DepositChip extends StatelessWidget {
  final String label;

  const _DepositChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_card_rounded, size: 16, color: primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}
