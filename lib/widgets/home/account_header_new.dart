import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/account_controller.dart';
import 'package:crm_app/controllers/dashboard_controller.dart';
import 'package:crm_app/models/mt5_account.dart';
import 'package:crm_app/models/websocket_trading_response.dart';
import 'package:crm_app/utils/currency_format.dart';
import 'package:crm_app/widgets/home/sheets/account_select_sheet_new.dart';

/// Purple gradient account header used by the trading tabs in the new design.
///
/// Shows the same value as [AccountHeaderWidget] (floating P&L when given,
/// otherwise equity) and opens the same account-switch sheet. The bar runs
/// under the status bar, so the shell must not add a top `SafeArea`.
class AccountHeaderNew extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final Widget? rightWidget;
  final double? floatingProfit;

  const AccountHeaderNew({
    super.key,
    this.onMenuTap,
    this.rightWidget,
    this.floatingProfit,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(
          16.w,
          topInset + 8.h,
          16.w,
          8.h,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              AppColors.homeHeaderGradientStart,
              AppColors.homeHeaderGradientEnd,
            ],
          ),
        ),
        child: Row(
          children: [
            _LogoButton(onTap: onMenuTap),
            SizedBox(width: 10.w),
            Expanded(child: _AccountSummary(floatingProfit: floatingProfit)),
            if (rightWidget != null) ...[SizedBox(width: 8.w), rightWidget!],
          ],
        ),
      ),
    );
  }
}

class _LogoButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _LogoButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'Menu',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22.r,
        child: SvgPicture.asset(
          'assets/svg/new_svg/home_logo.svg',
          width: 36.r,
          height: 36.r,
        ),
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  final double? floatingProfit;

  const _AccountSummary({this.floatingProfit});

  @override
  Widget build(BuildContext context) {
    final accountController = Get.find<AccountController>();
    final DashboardController? dashboardController =
        Get.isRegistered<DashboardController>()
            ? Get.find<DashboardController>()
            : null;
    final onHeader = AppColors.onColoredBackground;

    return Obx(() {
      final primaryAccount =
          accountController.activeMT5Account ??
          dashboardController?.primaryMT5Account;
      final accountInfoMap = dashboardController?.accountInfoMap;
      final isWebSocketConnected =
          dashboardController?.isWebSocketConnected ?? false;

      AccountInfo? accountInfo;
      if (primaryAccount != null && accountInfoMap != null) {
        accountInfo = accountInfoMap[primaryAccount.metaAccountNumber];
      }

      final double? realTimeEquity = accountInfo?.equity;
      final double? apiEquity =
          primaryAccount != null ? double.tryParse(primaryAccount.equity) : null;
      final double displayEquity = realTimeEquity ?? (apiEquity ?? 0.0);

      final bool isFetchingAccounts =
          dashboardController?.isLoadingMT5Accounts.value ?? false;
      if (primaryAccount == null && isFetchingAccounts) {
        return Row(
          children: [
            LoadingAnimationWidget.fourRotatingDots(color: onHeader, size: 20.w),
            SizedBox(width: 8.w),
            Text(
              'Loading account...',
              style: AppTextStyles.subheading.copyWith(
                fontSize: 12.sp,
                color: onHeader.withValues(alpha: 0.85),
              ),
            ),
          ],
        );
      }

      if (primaryAccount != null && dashboardController != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          dashboardController.ensureWebSocketInitialized();
        });
      }

      final bool hasAccountInfo =
          primaryAccount != null &&
          accountInfoMap != null &&
          accountInfoMap.containsKey(primaryAccount.metaAccountNumber);
      final bool useFloatingProfit = floatingProfit != null;
      final bool showLoading =
          !useFloatingProfit &&
          primaryAccount != null &&
          realTimeEquity == null &&
          (!isWebSocketConnected || !hasAccountInfo) &&
          displayEquity == 0.0;

      final String amountText =
          useFloatingProfit
              ? CurrencyFormat.signedAmount(floatingProfit!, primaryAccount)
              : CurrencyFormat.amount(displayEquity, primaryAccount);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (showLoading) ...[
                LoadingAnimationWidget.fourRotatingDots(
                  color: onHeader,
                  size: 18.w,
                ),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Text(
                  amountText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: onHeader,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _AccountTypeBadge(account: primaryAccount),
            ],
          ),
          Semantics(
            button: true,
            label: 'Switch account ${primaryAccount?.metaAccountNumber ?? ''}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () {
                accountController.resetToDefaultAccounts();
                AccountSelectSheetNew.show(context);
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 22.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      primaryAccount?.metaAccountNumber ?? '',
                      style: AppTextStyles.subheading.copyWith(
                        fontSize: 12.sp,
                        color: onHeader.withValues(alpha: 0.9),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 18.r, color: onHeader),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _AccountTypeBadge extends StatelessWidget {
  final MT5Account? account;

  const _AccountTypeBadge({this.account});

  @override
  Widget build(BuildContext context) {
    final type = account?.accountType.toLowerCase() ?? 'live';
    final isDemo = type == 'demo';
    final label = switch (type) {
      'live' => 'REAL',
      'demo' => 'DEMO',
      _ => type.toUpperCase(),
    };

    return Container(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 6.w, vertical: 1.h),
      decoration: BoxDecoration(
        color:
            isDemo
                ? AppColors.homeHeaderPillBackground
                : AppColors.homeBadgeRealBackground,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          color:
              isDemo
                  ? AppColors.onColoredBackground
                  : AppColors.homeBadgeRealText,
        ),
      ),
    );
  }
}

/// White-outline pill for the header's end slot (symbol picker, Close All).
class HeaderPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool showCaret;

  const HeaderPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.showCaret = false,
  });

  @override
  Widget build(BuildContext context) {
    final onHeader = AppColors.onColoredBackground;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          constraints: BoxConstraints(minHeight: 34.h),
          padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: AppColors.homeHeaderPillBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.homeHeaderPillBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: onHeader,
                ),
              ),
              if (showCaret) ...[
                SizedBox(width: 4.w),
                Icon(Icons.arrow_drop_down, size: 18.r, color: onHeader),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
