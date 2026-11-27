import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';

// Presentational widgets for the new-design pending order sheet. They only
// take values and callbacks; all order logic stays in PendingOrderScreen /
// PendingOrderContent.

const Duration _kAnim = Duration(milliseconds: 220);

/// Value text of [PendingStepperFieldNew]; also used to measure whether a
/// price fits before choosing a layout.
TextStyle _stepperValueStyle() => AppTextStyles.label.copyWith(
  fontSize: 15.sp,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// Tap size of the stepper − / + buttons.
double get _stepperHitSize => 40.r;

/// Horizontal space a stepper uses besides its value text: two buttons plus
/// its own side padding.
double get _stepperChromeWidth => 2 * _stepperHitSize + 4.w;

/// Puts two stepper-based items side by side when [sampleValue] fits in half
/// the width, otherwise stacks them full width, so a long price (BTC, indices)
/// or a large text size never gets cut off. [sampleValue] should come from the
/// market price, not the typed text, so the layout never flips mid-edit and
/// the field keeps its focus.
class PendingAdaptivePairNew extends StatelessWidget {
  final Widget first;
  final Widget second;
  final String sampleValue;

  /// Width each item spends around its stepper (card padding and border).
  final double itemChrome;

  const PendingAdaptivePairNew({
    super.key,
    required this.first,
    required this.second,
    required this.sampleValue,
    this.itemChrome = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 8.w;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        final available = itemWidth - itemChrome - _stepperChromeWidth;

        final painter = TextPainter(
          text: TextSpan(text: sampleValue, style: _stepperValueStyle()),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        // Breathing room so the digits never touch the − / + buttons.
        final needed = painter.width + 8.w;
        painter.dispose();

        if (needed <= available) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              SizedBox(width: gap),
              Expanded(child: second),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, SizedBox(height: gap), second],
        );
      },
    );
  }
}

/// Small caption above a section of the pending order form.
class PendingSectionLabelNew extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const PendingSectionLabelNew(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 2.w, bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.label.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
                letterSpacing: 0.4,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Live Bid | Ask bar under the sheet header.
class PendingQuoteBarNew extends StatelessWidget {
  final String bid;
  final String ask;

  const PendingQuoteBarNew({super.key, required this.bid, required this.ask});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.chartPillBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(child: _QuoteCell(label: 'BID', price: bid, isSell: true)),
          Container(width: 1, height: 20.h, color: AppColors.border),
          Expanded(child: _QuoteCell(label: 'ASK', price: ask, isSell: false)),
        ],
      ),
    );
  }
}

class _QuoteCell extends StatelessWidget {
  final String label;
  final String price;
  final bool isSell;

  const _QuoteCell({
    required this.label,
    required this.price,
    required this.isSell,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSell ? AppColors.chartSellAccent : AppColors.chartBuyAccent;
    return Semantics(
      label: '$label $price',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: 6.w,
              vertical: 2.h,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              price,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: AppTextStyles.label.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible chart card. The body keeps its widget alive while collapsed
/// by the keyboard ([visible] false) so the chart does not reload.
class PendingChartCardNew extends StatelessWidget {
  final bool expanded;
  final bool visible;
  final double chartHeight;
  final VoidCallback onToggle;
  final Widget? chart;

  const PendingChartCardNew({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.chartHeight,
    this.visible = true,
    this.chart,
  });

  @override
  Widget build(BuildContext context) {
    final showBody = expanded && visible;
    final radius = BorderRadius.circular(14.r);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.chartPillBackground,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            label: expanded ? 'Hide chart' : 'Show chart',
            excludeSemantics: true,
            child: InkWell(
              onTap: onToggle,
              child: SizedBox(
                height: 36.h,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.candlestick_chart_rounded,
                        size: 16.r,
                        color: AppColors.homeIconTint,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'Chart',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        expanded ? 'Hide' : 'Show',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textGrey,
                        ),
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: _kAnim,
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20.r,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: _kAnim,
            curve: Curves.easeInOut,
            height: showBody ? chartHeight : 0,
            child: chart == null ? null : ClipRect(child: chart),
          ),
        ],
      ),
    );
  }
}

/// Segmented control with a sliding thumb. Used for SELL/BUY and for the
/// order kind (Limit / Stop / Stop Limit).
class PendingSegmentedNew extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color thumbColor;
  final Color selectedTextColor;
  final double height;
  final String semanticsPrefix;

  const PendingSegmentedNew({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    required this.thumbColor,
    required this.selectedTextColor,
    required this.height,
    this.semanticsPrefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final count = options.length;
    final thumbX = count == 1 ? 0.0 : -1 + 2 * selectedIndex / (count - 1);

    return Container(
      height: height,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: AppColors.chartPillBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: _kAnim,
            curve: Curves.easeInOut,
            alignment: AlignmentDirectional(thumbX, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: _kAnim,
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: thumbColor,
                  borderRadius: BorderRadius.circular(9.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.chartDockShadow,
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < count; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selectedIndex,
                    label: '$semanticsPrefix${options[i]}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelected(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: _kAnim,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 13.sp,
                            fontWeight:
                                i == selectedIndex
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                            color:
                                i == selectedIndex
                                    ? selectedTextColor
                                    : AppColors.textGrey,
                          ),
                          child: Text(
                            options[i],
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact − / value / + field. Used for volume, prices and TP/SL.
class PendingStepperFieldNew extends StatelessWidget {
  final String? caption;
  final String semanticsName;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final Color? background;

  const PendingStepperFieldNew({
    super.key,
    this.caption,
    required this.semanticsName,
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.inputFormatters,
    this.hintText,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 42.h),
      padding: EdgeInsetsDirectional.symmetric(horizontal: 2.w),
      decoration: BoxDecoration(
        color: background ?? AppColors.chartPillBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _StepperButton(
            isIncrement: false,
            semanticsLabel: 'Decrease $semanticsName',
            onPressed: onDecrement,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (caption != null)
                  Text(
                    caption!,
                    maxLines: 1,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: inputFormatters,
                  textAlign: TextAlign.center,
                  style: _stepperValueStyle(),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: AppTextStyles.label.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.textGrey,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: onChanged,
                  onEditingComplete: onEditingComplete,
                ),
              ],
            ),
          ),
          _StepperButton(
            isIncrement: true,
            semanticsLabel: 'Increase $semanticsName',
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final bool isIncrement;
  final String semanticsLabel;
  final VoidCallback onPressed;

  const _StepperButton({
    required this.isIncrement,
    required this.semanticsLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 20.r,
        // Visual circle is 26px but the tap area stays 40px.
        child: SizedBox(
          width: _stepperHitSize,
          height: _stepperHitSize,
          child: Center(
            child: Container(
              width: 26.r,
              height: 26.r,
              decoration: BoxDecoration(
                color: AppColors.chartPillButtonBackground,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.chartDockShadow,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                isIncrement ? Icons.add_rounded : Icons.remove_rounded,
                size: 16.r,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact TP or SL card meant to sit side by side with its pair. When
/// switched off it shows "Not set" instead of the field.
class PendingTpSlCardNew extends StatelessWidget {
  final String title;
  final bool isTakeProfit;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Widget footer;
  final Widget child;

  const PendingTpSlCardNew({
    super.key,
    required this.title,
    required this.isTakeProfit,
    required this.enabled,
    required this.onToggle,
    required this.footer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isTakeProfit ? AppColors.chartBuyAccent : AppColors.chartSellAccent;

    return AnimatedContainer(
      duration: _kAnim,
      curve: Curves.easeInOut,
      padding: EdgeInsetsDirectional.fromSTEB(12.w, 6.h, 6.w, 12.h),
      decoration: BoxDecoration(
        color: enabled ? accent.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: enabled ? accent.withValues(alpha: 0.45) : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                Icon(
                  isTakeProfit ? Icons.flag_rounded : Icons.shield_outlined,
                  size: 14.r,
                  color: accent,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.72,
                  child: Switch.adaptive(
                    value: enabled,
                    onChanged: onToggle,
                    activeTrackColor: accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: _kAnim,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:
                enabled
                    ? Padding(
                      padding: EdgeInsetsDirectional.only(end: 6.w, top: 4.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [child, footer],
                      ),
                    )
                    : Padding(
                      padding: EdgeInsetsDirectional.only(top: 2.h),
                      child: Text(
                        'Not set',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

/// Label + value line for the potential P&L under a TP/SL field.
class PendingPnLLineNew extends StatelessWidget {
  final String label;
  final String? value;
  final Color color;

  const PendingPnLLineNew({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: 6.h, start: 2.w),
      // Wrap, not Row: a long amount drops under the label instead of being
      // cut off in the narrow side-by-side cards.
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.w,
          runSpacing: 2.h,
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontSize: 10.sp,
                color: AppColors.textGrey,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                value ?? '—',
                key: ValueKey(value),
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: value == null ? AppColors.textGrey : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline warning with an icon, so the message is not carried by colour alone.
class PendingValidationNoteNew extends StatelessWidget {
  final String message;

  const PendingValidationNoteNew({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsetsDirectional.only(top: 6.h),
      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14.r, color: AppColors.error),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.label.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-line order summary shown above the place button.
class PendingOrderSummaryNew extends StatelessWidget {
  final String orderType;
  final String volume;
  final String price;
  final bool isSell;

  const PendingOrderSummaryNew({
    super.key,
    required this.orderType,
    required this.volume,
    required this.price,
    required this.isSell,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSell ? AppColors.chartSellAccent : AppColors.chartBuyAccent;
    final muted = AppTextStyles.label.copyWith(
      fontSize: 12.sp,
      color: AppColors.textGrey,
    );
    final strong = AppTextStyles.label.copyWith(
      fontSize: 12.sp,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: orderType.toUpperCase(),
            style: strong.copyWith(color: accent),
          ),
          TextSpan(text: '  ·  ', style: muted),
          TextSpan(text: volume, style: strong),
          TextSpan(text: ' lot  @  ', style: muted),
          TextSpan(text: price, style: strong),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}

/// Place button tinted by order side, with disabled and loading states.
class PendingPlaceButtonNew extends StatelessWidget {
  final String label;
  final bool isSell;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const PendingPlaceButtonNew({
    super.key,
    required this.label,
    required this.isSell,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isSell ? AppColors.chartSellAccent : AppColors.chartBuyAccent;
    final textStyle = AppTextStyles.label.copyWith(
      fontSize: 15.sp,
      fontWeight: FontWeight.w700,
      color: AppColors.onColoredBackground,
    );

    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: accent,
          foregroundColor: AppColors.onColoredBackground,
          disabledBackgroundColor: accent.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.onColoredBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child:
            isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.onColoredBackground,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text('Processing...', style: textStyle),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle,
                      ),
                    ),
                    if (enabled) ...[
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18.r,
                        color: AppColors.onColoredBackground,
                      ),
                    ],
                  ],
                ),
      ),
    );
  }
}
