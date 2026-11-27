import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/services/language_service.dart';

/// Every tappable shortcut on the home tab (quick actions + feature panel).
/// The screen decides where each one goes and whether it is shown.
enum HomeShortcut {
  deposit,
  demoContest,
  pamm,
  ibDashboard,
  withdraw,
  bonus,
  transfer,
  history,
  copyTrading,
  supportTickets,
  wallet,
  promotional,
  finance,
  savings,
  liveStream,
}

class _QuickAction {
  final HomeShortcut shortcut;
  final String iconAsset;
  final String labelKey;
  final String fallbackLabel;

  const _QuickAction(
    this.shortcut,
    this.iconAsset,
    this.labelKey,
    this.fallbackLabel,
  );
}

/// 4×2 grid of icon + label shortcuts. The first [maxTiles] shortcuts that
/// [isVisible] accepts are laid out, so when a broker has a module off
/// (PAMM, IB…) a reserve shortcut moves up and the grid stays full.
class QuickActionsGrid extends StatelessWidget {
  final ValueChanged<HomeShortcut> onShortcutTap;
  final bool Function(HomeShortcut shortcut) isVisible;

  const QuickActionsGrid({
    super.key,
    required this.onShortcutTap,
    required this.isVisible,
  });

  static const int columns = 4;
  static const int maxTiles = 8;

  static const String _iconDir = 'assets/svg/new_svg';

  /// In display order; the last three are reserves for module-gated slots.
  static const List<_QuickAction> _actions = [
    _QuickAction(
      HomeShortcut.deposit,
      '$_iconDir/arrow-down.svg',
      'deposit',
      'Deposit',
    ),
    _QuickAction(
      HomeShortcut.demoContest,
      '$_iconDir/gift.svg',
      'more_demo_contest',
      'Demo Contest',
    ),
    _QuickAction(
      HomeShortcut.pamm,
      '$_iconDir/calendar-tick.svg',
      'home_pamm',
      'PAMM',
    ),
    _QuickAction(
      HomeShortcut.ibDashboard,
      '$_iconDir/calculator.svg',
      'more_dashboard',
      'IB Dashboard',
    ),
    _QuickAction(
      HomeShortcut.withdraw,
      '$_iconDir/coin.svg',
      'general_withdraw',
      'Withdraw',
    ),
    _QuickAction(
      HomeShortcut.bonus,
      '$_iconDir/moneys.svg',
      'more_bonus',
      'Bonus',
    ),
    _QuickAction(
      HomeShortcut.transfer,
      '$_iconDir/message-question.svg',
      'general_transfer',
      'Transfer',
    ),
    _QuickAction(
      HomeShortcut.history,
      '$_iconDir/element-plus.svg',
      'general_history',
      'History',
    ),
    _QuickAction(
      HomeShortcut.copyTrading,
      '$_iconDir/chart.svg',
      'more_copy_trading',
      'Copy Trading',
    ),
    _QuickAction(
      HomeShortcut.supportTickets,
      '$_iconDir/messenger.svg',
      'ticket_title',
      'Support Tickets',
    ),
    _QuickAction(
      HomeShortcut.wallet,
      '$_iconDir/empty-wallet.svg',
      'wallet',
      'Wallet',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _actions
        .where((a) => isVisible(a.shortcut))
        .take(maxTiles)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var start = 0; start < visible.length; start += columns) {
      final rowItems = visible.skip(start).take(columns).toList();
      if (start > 0) rows.add(SizedBox(height: 4.h));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final action in rowItems)
              Expanded(
                child: _QuickActionTile(
                  action: action,
                  onTap: () => onShortcutTap(action.shortcut),
                ),
              ),
            // Keep tiles in the same column width on a short last row.
            for (var i = rowItems.length; i < columns; i++)
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  final VoidCallback onTap;

  const _QuickActionTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = Get.find<LanguageService>().trf(
      action.labelKey,
      action.fallbackLabel,
    );

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 2.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  action.iconAsset,
                  width: 32.r,
                  height: 32.r,
                  colorFilter: AppColors.homeArtworkColorFilter,
                ),
                SizedBox(height: 6.h),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
