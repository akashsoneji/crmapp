import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/widgets/brand_logo.dart';

/// A label/value pair in the metrics strip of [DashboardAccountCardNew].
class DashboardAccountMetric {
  const DashboardAccountMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
}

/// One tinted action button (Trade / Deposit / Withdraw ...) of a card.
class DashboardAccountAction {
  const DashboardAccountAction({
    required this.label,
    required this.svgAsset,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String svgAsset;
  final Color color;
  final VoidCallback onTap;
}

/// Compact trading-account card of the redesigned Dashboard tab (new home
/// design only). Purely visual: every action is a callback from the screen.
class DashboardAccountCardNew extends StatelessWidget {
  const DashboardAccountCardNew({
    super.key,
    required this.accountNumber,
    required this.accountTypeLabel,
    required this.isLive,
    required this.groupName,
    required this.metrics,
    required this.actions,
    required this.infoTooltip,
    required this.onInfo,
    required this.menuTooltip,
    required this.onMenu,
    this.isScratchCard = false,
    this.activeLabel,
    this.switchLabel,
    this.onSwitch,
  });

  final String accountNumber;
  final String accountTypeLabel;
  final bool isLive;
  final String groupName;
  final List<DashboardAccountMetric> metrics;
  final List<DashboardAccountAction> actions;
  final String infoTooltip;
  final VoidCallback onInfo;
  final String menuTooltip;
  final VoidCallback onMenu;
  final bool isScratchCard;

  /// Shown as a chip when the account is the active trading account.
  final String? activeLabel;

  /// Both set → a "switch to this account" button under the actions.
  final String? switchLabel;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    final active = activeLabel;
    final switchText = switchLabel;
    final switchTap = onSwitch;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(10.w, 4.h, 2.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.homeCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            accountNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        _AccountTypePill(
                          label: accountTypeLabel,
                          isLive: isLive,
                        ),
                        if (isScratchCard) ...[
                          SizedBox(width: 6.w),
                          BrandLogo(
                            source: 'assets/svg/more/scratch.svg',
                            height: 18.r,
                            width: 18.r,
                            color: AppColors.primary,
                          ),
                        ],
                        if (active != null) ...[
                          SizedBox(width: 6.w),
                          _ActiveChip(label: active),
                        ],
                      ],
                    ),
                    if (groupName.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        groupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 10.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _CardIconButton(
                svgAsset: 'assets/svg/info-circle.svg',
                tooltip: infoTooltip,
                onTap: onInfo,
              ),
              _CardIconButton(
                svgAsset: 'assets/svg/deshboard/Three_dot.svg',
                tooltip: menuTooltip,
                onTap: onMenu,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsetsDirectional.only(end: 8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetricsStrip(metrics: metrics),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) SizedBox(width: 6.w),
                      Expanded(child: _ActionButton(action: actions[i])),
                    ],
                  ],
                ),
                if (switchText != null && switchTap != null) ...[
                  SizedBox(height: 6.h),
                  _SwitchButton(label: switchText, onTap: switchTap),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTypePill extends StatelessWidget {
  const _AccountTypePill({required this.label, required this.isLive});

  final String label;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final Color background =
        isLive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.12);
    final Color foreground =
        isLive
            ? AppColors.onColoredBackground
            : (AppColors.isDarkMode ? AppColors.textPrimary : AppColors.primary);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.r,
            height: 5.r,
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.svgAsset,
    required this.tooltip,
    required this.onTap,
  });

  final String svgAsset;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: 32.r, height: 32.r),
      icon: SvgPicture.asset(
        svgAsset,
        width: 16.r,
        height: 16.r,
        colorFilter: ColorFilter.mode(AppColors.textGrey, BlendMode.srcIn),
      ),
    );
  }
}

class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip({required this.metrics});

  final List<DashboardAccountMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.homeFeaturePanelBackground,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) SizedBox(width: 8.w),
            Expanded(child: _MetricTile(metric: metrics[i])),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final DashboardAccountMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            fontSize: 10.sp,
            color: AppColors.textGrey,
          ),
        ),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: metric.valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

    final DashboardAccountAction action;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(7.r);

    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: Material(
        color: action.color.withValues(alpha: 0.1),
        borderRadius: radius,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 32.h),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    action.svgAsset,
                    width: 14.r,
                    height: 14.r,
                    colorFilter: ColorFilter.mode(
                      action.color,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: action.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  const _SwitchButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(7.r);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 30.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/svg/deshboard/switch_icon.svg',
                width: 13.r,
                height: 13.r,
                colorFilter: ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 5.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// No-accounts state of the redesigned Dashboard: illustration on a soft
/// disc, short copy, and Real / Demo buttons side by side.
class DashboardEmptyStateNew extends StatelessWidget {
  const DashboardEmptyStateNew({
    super.key,
    required this.illustration,
    required this.title,
    required this.description,
    required this.realLabel,
    required this.onOpenReal,
    required this.demoLabel,
    required this.onOpenDemo,
  });

  final Widget illustration;
  final String title;
  final String description;
  final String realLabel;
  final VoidCallback onOpenReal;
  final String demoLabel;
  final VoidCallback onOpenDemo;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.r),
    );
    final buttonTextStyle = AppTextStyles.label.copyWith(
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 104.r,
            height: 104.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: illustration,
          ),
          SizedBox(height: 14.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              fontSize: 13.sp,
              height: 1.45,
              color: AppColors.textGrey,
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenReal,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, 42.h),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: shape,
                    textStyle: buttonTextStyle,
                  ),
                  child: Text(realLabel, maxLines: 1),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: FilledButton(
                  onPressed: onOpenDemo,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, 42.h),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onColoredBackground,
                    shape: shape,
                    textStyle: buttonTextStyle,
                  ),
                  child: Text(demoLabel, maxLines: 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
