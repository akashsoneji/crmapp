import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/widgets/home/sheets/sheet_scaffold_new.dart';

/// One tab of [PositionsTabSwitcher]; [count] is hidden when null.
class PositionsTabData {
  const PositionsTabData({required this.label, this.count});

  final String label;
  final int? count;
}

/// Segmented Market / Pending / History switcher of the redesigned
/// Positions screen (new home design only).
class PositionsTabSwitcher extends StatelessWidget {
  const PositionsTabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<PositionsTabData> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: AppColors.homeFeaturePanelBackground,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: _PositionsTabButton(
                data: tabs[index],
                isSelected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _PositionsTabButton extends StatelessWidget {
  const _PositionsTabButton({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final PositionsTabData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isSelected ? AppColors.onColoredBackground : AppColors.textGrey;
    final count = data.count;

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            constraints: BoxConstraints(minHeight: 32.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    data.label,
                    maxLines: 1,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 13.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                ),
                if (count != null) ...[
                  SizedBox(width: 4.w),
                  _PositionsCountBadge(count: count, isSelected: isSelected),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionsCountBadge extends StatelessWidget {
  const _PositionsCountBadge({required this.count, required this.isSelected});

  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final background =
        isSelected
            ? AppColors.onColoredBackground.withValues(alpha: 0.2)
            : AppColors.primary.withValues(alpha: 0.12);
    final foreground =
        isSelected ? AppColors.onColoredBackground : AppColors.primary;

    return Container(
      constraints: BoxConstraints(minWidth: 18.w),
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        count.toString(),
        textAlign: TextAlign.center,
        style: AppTextStyles.label.copyWith(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// A label/value pair shown in [PositionsMetricsCard].
class PositionsMetric {
  const PositionsMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
}

/// Account summary card: one prominent [hero] figure (equity, or profit on
/// History) above a three-column grid of the remaining [items].
///
/// [trailing] (e.g. the filter buttons) takes the grid cell right after the
/// last item, so it fills the gap at the end of the last row.
class PositionsMetricsCard extends StatelessWidget {
  const PositionsMetricsCard({
    super.key,
    required this.hero,
    required this.items,
    this.trailing,
  });

  final PositionsMetric hero;
  final List<PositionsMetric> items;
  final Widget? trailing;

  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing;
    final cellCount = items.length + (trailingWidget == null ? 0 : 1);

    Widget buildCell(int index) {
      if (index < items.length) return _PositionsMetricTile(items[index]);
      if (index == items.length && trailingWidget != null) {
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: trailingWidget,
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.homeCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PositionsMetricsHero(metric: hero),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
            child: Column(
              children: [
                for (var row = 0; row < cellCount; row += _columns)
                  Padding(
                    padding: EdgeInsets.only(top: row == 0 ? 0 : 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (var col = 0; col < _columns; col++) ...[
                          if (col > 0) SizedBox(width: 8.w),
                          Expanded(child: buildCell(row + col)),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small square filter button used inside [PositionsMetricsCard]: tinted
/// when [active], with an optional count badge.
class PositionsFilterIconButton extends StatelessWidget {
  const PositionsFilterIconButton({
    super.key,
    required this.tooltip,
    required this.iconBuilder,
    required this.active,
    required this.onTap,
    this.badgeCount,
  });

  final String tooltip;

  /// Builds the icon in the given colour (lets callers use SVGs too).
  final Widget Function(Color color) iconBuilder;
  final bool active;
  final VoidCallback onTap;

  /// Shown as a badge when non-null.
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final count = badgeCount;
    final radius = BorderRadius.circular(8.r);
    final iconColor =
        active ? AppColors.homeHeaderGradientEnd : AppColors.textGrey;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: active,
        label: tooltip,
        excludeSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: active ? AppColors.sheetSelectedFill : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(
                  color:
                      active
                          ? AppColors.sheetSelectedOutline
                          : AppColors.homeCardBorder,
                ),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: SizedBox(
                  width: 28.r,
                  height: 28.r,
                  child: Center(
                    child: SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: iconBuilder(iconColor),
                    ),
                  ),
                ),
              ),
            ),
            if (count != null)
              PositionedDirectional(
                end: -5.r,
                top: -5.r,
                child: Container(
                  constraints: BoxConstraints(minWidth: 15.r, minHeight: 15.r),
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    color: AppColors.homeHeaderGradientEnd,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.homeCardBackground),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onColoredBackground,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PositionsMetricsHero extends StatelessWidget {
  const _PositionsMetricsHero({required this.metric});

  final PositionsMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      color: AppColors.primary.withValues(alpha: 0.07),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            metric.label,
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          const Spacer(),
          Text(
            metric.value,
            style: AppTextStyles.heading.copyWith(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: metric.valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionsMetricTile extends StatelessWidget {
  const _PositionsMetricTile(this.metric);

  final PositionsMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.label,
          style: AppTextStyles.label.copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.textGrey,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          metric.value,
          style: AppTextStyles.label.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: metric.valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Compact row card for a market position, pending order or closed trade.
/// Purely visual: taps, swipe-to-close and expansion stay with the caller.
class PositionTradeCard extends StatelessWidget {
  const PositionTradeCard({
    super.key,
    required this.symbol,
    required this.isBuy,
    required this.sideLabel,
    required this.priceRange,
    required this.value,
    required this.valueColor,
    this.caption,
    this.isExpanded,
    this.expandedChild,
  });

  final String symbol;
  final bool isBuy;

  /// e.g. "buy 0.01" — shown in a side-coloured pill.
  final String sideLabel;

  /// e.g. "1.08550 -> 1.08612".
  final String priceRange;

  /// Right-hand figure: P/L, or a status such as "placed".
  final String value;
  final Color valueColor;

  /// Small grey line above [value] (close time on History).
  final String? caption;

  /// Non-null shows a chevron; [expandedChild] is laid out under the row.
  final bool? isExpanded;
  final Widget? expandedChild;

  @override
  Widget build(BuildContext context) {
    final sideColor = isBuy ? AppColors.green : AppColors.error;
    final expanded = isExpanded;
    final captionText = caption;
    final belowRow = expandedChild;

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.fromLTRB(12.w, 9.h, expanded == null ? 12.w : 6.w, 9.h),
      decoration: BoxDecoration(
        color: AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.homeCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 3.w,
                height: 30.h,
                decoration: BoxDecoration(
                  color: sideColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            symbol,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        _PositionSidePill(label: sideLabel, color: sideColor),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      priceRange,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 11.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (captionText != null)
                    Text(
                      captionText,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 11.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                  Text(
                    value,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
              if (expanded != null)
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textGrey,
                  size: 18.sp,
                ),
            ],
          ),
          if (belowRow != null) belowRow,
        ],
      ),
    );
  }
}

class _PositionSidePill extends StatelessWidget {
  const _PositionSidePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Drag handle + left-aligned title (and optional subtitle / close button)
/// shared by every new-design Positions bottom sheet.
class PositionsSheetHeader extends StatelessWidget {
  const PositionsSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    final close = onClose;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.sheetGrabber,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sheetTextPrimary,
                        ),
                      ),
                    ),
                    if (subtitleText != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitleText,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.sheetTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (close != null)
                SheetIconButtonNew(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  onPressed: close,
                )
              else
                SizedBox(width: 8.w),
            ],
          ),
        ],
      ),
    );
  }
}

/// Selectable bordered row used for radio-style choices in sheets
/// (direction, close-all options). [onTap] null renders it disabled.
class PositionsSelectOption extends StatelessWidget {
  const PositionsSelectOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final trailingWidget = trailing;
    final radius = BorderRadius.circular(12.r);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        child: Material(
          color: selected ? AppColors.sheetSelectedFill : AppColors.sheetRow,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color:
                  selected
                      ? AppColors.sheetSelectedOutline
                      : AppColors.sheetFieldBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 44.h),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              enabled
                                  ? AppColors.sheetTextPrimary
                                  : AppColors.sheetTextMuted,
                        ),
                      ),
                    ),
                    if (trailingWidget != null) ...[
                      trailingWidget,
                      SizedBox(width: 10.w),
                    ],
                    _SelectDot(selected: selected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18.r,
      height: 18.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            selected
                ? LinearGradient(
                  colors: [
                    AppColors.homeHeaderGradientStart,
                    AppColors.homeHeaderGradientEnd,
                  ],
                )
                : null,
        border:
            selected
                ? null
                : Border.all(color: AppColors.sheetChipIdleBorder, width: 1.5),
      ),
      child:
          selected
              ? Icon(
                Icons.check_rounded,
                size: 12.r,
                color: AppColors.onColoredBackground,
              )
              : null,
    );
  }
}

/// Action row for the position actions sheet: tinted icon, title, subtitle.
class PositionsActionTile extends StatelessWidget {
  const PositionsActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: AppColors.sheetRow,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: AppColors.sheetRowDivider),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Row(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Icon(icon, size: 17.r, color: color),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sheetTextPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.sheetTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20.r,
                  color: AppColors.sheetTextMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill chip for quick date filters (Today / Last Week / ...).
class PositionsFilterChip extends StatelessWidget {
  const PositionsFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);

    return Semantics(
      button: true,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: selected ? null : AppColors.sheetChipIdle,
          gradient:
              selected
                  ? LinearGradient(
                    colors: [
                      AppColors.homeHeaderGradientStart,
                      AppColors.homeHeaderGradientEnd,
                    ],
                  )
                  : null,
          border:
              selected
                  ? null
                  : Border.all(color: AppColors.sheetChipIdleBorder),
        ),
        child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 34.h),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        selected
                            ? AppColors.onColoredBackground
                            : AppColors.sheetChipIdleText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Empty list placeholder: the illustration on a soft brand-tinted disc.
class PositionsEmptyState extends StatelessWidget {
  const PositionsEmptyState({
    super.key,
    required this.illustration,
    required this.message,
  });

  final Widget illustration;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.r,
            height: 120.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: illustration,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.subheading.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
