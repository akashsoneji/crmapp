import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/sheets/account_select_sheet_controller.dart';
import 'package:crm_app/models/mt5_account.dart';
import 'package:crm_app/utils/currency_format.dart';
import 'package:crm_app/widgets/home/sheets/sheet_scaffold_new.dart';

/// tenaxnew "Select Account" sheet: same accounts, ACTIVE marker, ID and
/// balance as the old sheet; tapping a card switches the account.
class AccountSelectSheetNew extends GetView<AccountSelectSheetController> {
  final String controllerTag;

  const AccountSelectSheetNew({super.key, required this.controllerTag});

  @override
  String? get tag => controllerTag;

  static Future<void> show(BuildContext context) async {
    final tag = 'account_sheet_${DateTime.now().microsecondsSinceEpoch}';
    Get.put(AccountSelectSheetController(), tag: tag);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => SheetControllerScope<AccountSelectSheetController>(
        tag: tag,
        child: AccountSelectSheetNew(controllerTag: tag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.65;
    return SheetScaffoldNew(
      title: 'Select Account',
      trailing: SheetIconButtonNew(
        icon: Icons.close_rounded,
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxListHeight),
        child: Obx(() {
          final items = controller.items;
          final isBusy = controller.isSwitching;
          return ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsetsDirectional.fromSTEB(16.w, 4.h, 16.w, 8.h),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final account = items[index];
              return AccountCardNew(
                account: account,
                isActive: controller.isActive(account),
                enabled: !isBusy,
                onTap: () => _onSelect(context, account),
              );
            },
          );
        }),
      ),
    );
  }

  void _onSelect(BuildContext context, MT5Account account) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
    controller.select(account);
  }
}

/// One account card. The active one gets a gradient outline and an ACTIVE
/// chip; screen readers get radio semantics (checked / not checked).
class AccountCardNew extends StatelessWidget {
  final MT5Account account;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  const AccountCardNew({
    super.key,
    required this.account,
    required this.isActive,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDemo = AccountSelectSheetController.isDemo(account);
    final typeLabel = account.accountType.capitalizeFirst ?? '';
    final balance = '${CurrencyFormat.symbol(account)}${account.balance}';
    final radius = BorderRadius.circular(18.r);
    // At large text sizes the balance moves under the ID rather than being
    // squeezed or truncated beside it.
    final stackBalance = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final balanceText = Text(
      balance,
      style: AppTextStyles.label.copyWith(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.sheetTextPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    // The gradient outline below is painted behind the whole card, so the
    // card itself must be opaque or the gradient bleeds through and hides
    // the dark text in light mode.
    final activeFill = Color.alphaBlend(
      AppColors.sheetSelectedFill,
      AppColors.sheetSurface,
    );
    final card = Material(
      color: isActive ? activeFill : AppColors.sheetRow,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 72.r),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.w, 12.h, 14.w, 12.h),
            child: Row(
              children: [
                _WalletBadge(isDemo: isDemo),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 4.h,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            typeLabel,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sheetTextPrimary,
                            ),
                          ),
                          if (isActive) const _ActiveChip(),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'ID: ${account.metaAccountNumber}',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.sheetTextMuted,
                        ),
                      ),
                      if (stackBalance) ...[
                        SizedBox(height: 4.h),
                        balanceText,
                      ],
                    ],
                  ),
                ),
                if (!stackBalance) ...[
                  SizedBox(width: 8.w),
                  balanceText,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isActive,
      enabled: enabled,
      button: true,
      label: '$typeLabel account ${account.metaAccountNumber}, '
          'balance $balance${isActive ? ', active' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(isActive ? 1.5 : 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19.5.r),
          color: isActive ? null : AppColors.sheetRowDivider,
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    AppColors.homeHeaderGradientStart,
                    AppColors.homeHeaderGradientEnd,
                  ],
                )
              : null,
        ),
        child: card,
      ),
    );
  }
}

class _WalletBadge extends StatelessWidget {
  final bool isDemo;

  const _WalletBadge({required this.isDemo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.r,
      height: 44.r,
      padding: EdgeInsets.all(11.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        color: isDemo ? AppColors.accountSheetLeadingBackground(isDemo: true) : null,
        gradient: isDemo
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.homeHeaderGradientStart,
                  AppColors.homeHeaderGradientEnd,
                ],
              ),
      ),
      child: SvgPicture.asset(
        'assets/svg/empty-wallet.svg',
        colorFilter: ColorFilter.mode(
          isDemo
              ? AppColors.accountSheetLeadingIcon(isDemo: true)
              : AppColors.onColoredBackground,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.sheetActiveChipBackground,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_rounded,
            size: 12.r,
            color: AppColors.sheetActiveChipText,
          ),
          SizedBox(width: 3.w),
          Text(
            'ACTIVE',
            style: AppTextStyles.label.copyWith(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.sheetActiveChipText,
            ),
          ),
        ],
      ),
    );
  }
}
