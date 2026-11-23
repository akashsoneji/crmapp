import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/sheets/price_alert_sheet_controller.dart';
import 'package:crm_app/screens/home/price_alerts_screen.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/widgets/home/sheets/sheet_scaffold_new.dart';

/// tenaxnew "New Price Alert" sheet. Same content as `PriceAlertDialog`
/// (price stepper, above/below, note, my alerts, current bid) in the new
/// design; all state lives in [PriceAlertSheetController].
class PriceAlertSheetNew extends GetView<PriceAlertSheetController> {
  final String controllerTag;

  const PriceAlertSheetNew({super.key, required this.controllerTag});

  @override
  String? get tag => controllerTag;

  /// Opens the sheet with its own controller and removes the controller
  /// once the sheet is gone.
  static Future<void> show(
    BuildContext context, {
    required String symbol,
    required double currentPrice,
    required int digits,
    Stream<dynamic>? bidChanges,
    double? Function()? readBid,
  }) async {
    final tag = 'price_alert_sheet_${DateTime.now().microsecondsSinceEpoch}';
    Get.put(
      PriceAlertSheetController(
        symbol: symbol,
        openingBid: currentPrice,
        digits: digits,
        bidChanges: bidChanges,
        readBid: readBid,
      ),
      tag: tag,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => SheetControllerScope<PriceAlertSheetController>(
        tag: tag,
        child: PriceAlertSheetNew(controllerTag: tag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffoldNew(
      title: 'New Price Alert',
      trailing: _MyAlertsButton(onPressed: () {
        Navigator.of(context).pop();
        Get.to(() => const PriceAlertsScreen());
      }),
      bodyPadding: EdgeInsetsDirectional.symmetric(horizontal: 16.w),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SymbolRow(controller: controller),
            SizedBox(height: 10.h),
            _PriceCard(controller: controller),
            SizedBox(height: 12.h),
            const _SectionLabel('Condition'),
            SizedBox(height: 6.h),
            _ConditionToggle(controller: controller),
            SizedBox(height: 4.h),
            _NoteSection(controller: controller),
            SizedBox(height: 8.h),
            Obx(
              () => SheetGradientButtonNew(
                label: _ctaLabel(controller),
                isLoading: controller.isLoading.value,
                onPressed: () => _submit(context),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  String _ctaLabel(PriceAlertSheetController c) {
    final sign = c.isAbove ? '≥' : '≤';
    return 'Alert me when ${c.symbol} $sign ${c.priceText}';
  }

  Future<void> _submit(BuildContext context) async {
    final navigator = Navigator.of(context);
    final created = await controller.submit();
    if (created && navigator.mounted) navigator.pop();
  }
}

class _MyAlertsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MyAlertsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size(44.r, 44.r),
        foregroundColor: AppColors.sheetSelectedOutline,
      ),
      icon: Icon(Icons.list_alt_rounded, size: 16.r),
      label: Text(
        TranslationUtils.tr('price_alerts_my_alerts'),
        style: AppTextStyles.label.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.sheetSelectedOutline,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.sheetTextMuted,
      ),
    );
  }
}

/// Symbol chip on the left, live bid pill on the right (tap = use bid).
class _SymbolRow extends StatelessWidget {
  final PriceAlertSheetController controller;

  const _SymbolRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: AppColors.sheetSelectedFill,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            controller.symbol,
            style: AppTextStyles.label.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.sheetTextPrimary,
            ),
          ),
        ),
        Obx(
          () => Semantics(
            button: true,
            label: 'Current bid price '
                '${controller.format(controller.liveBid.value)}, '
                'tap to use it',
            excludeSemantics: true,
            child: InkWell(
              onTap: controller.useLiveBid,
              borderRadius: BorderRadius.circular(20.r),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 44.r),
                // Tap area stays 44px; the visible pill is only as tall as
                // its text.
                child: Align(
                  widthFactor: 1,
                  child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.sheetField,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.sheetFieldBorder),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Bid  ',
                          style: TextStyle(color: AppColors.sheetTextMuted),
                        ),
                        TextSpan(
                          text: controller.format(controller.liveBid.value),
                          style: TextStyle(
                            color: AppColors.sheetTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    style: AppTextStyles.label.copyWith(fontSize: 12.sp),
                  ),
                ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  final PriceAlertSheetController controller;

  const _PriceCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.sheetField,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.sheetFieldBorder),
      ),
      child: Column(
        children: [
          Text(
            'Price',
            style: AppTextStyles.label.copyWith(
              fontSize: 11.sp,
              color: AppColors.sheetTextMuted,
            ),
          ),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                tooltip: 'Decrease price',
                onPressed: controller.stepDown,
              ),
              Expanded(
                child: TextField(
                  controller: controller.priceField,
                  onChanged: controller.onPriceTyped,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sheetTextPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                tooltip: 'Increase price',
                onPressed: controller.stepUp,
              ),
            ],
          ),
          Obx(() {
            final distance = controller.distance;
            final isUp = distance >= 0;
            final color = distance == 0
                ? AppColors.sheetTextMuted
                : (isUp
                    ? AppColors.sheetConditionAbove
                    : AppColors.sheetConditionBelow);
            final sign = isUp ? '+' : '−';
            final pct = controller.distancePercent.abs().toStringAsFixed(2);
            return Text(
              '$sign${controller.format(distance.abs())} · '
              '$sign$pct% from bid',
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        // 44px tap area around a smaller 32px visible circle.
        child: InkResponse(
          radius: 22.r,
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          child: SizedBox(
            width: 44.r,
            height: 44.r,
            child: Center(
              child: Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: AppColors.sheetSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.sheetFieldBorder),
                ),
                child: Icon(
                  icon,
                  size: 18.r,
                  color: AppColors.sheetSelectedOutline,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-segment Above / Below toggle; colour is backed by an arrow icon and
/// the text label so the state never relies on colour alone.
class _ConditionToggle extends StatelessWidget {
  final PriceAlertSheetController controller;

  const _ConditionToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          color: AppColors.sheetField,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.sheetFieldBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ConditionSegment(
                label: TranslationUtils.tr('price_alerts_above'),
                icon: Icons.arrow_upward_rounded,
                accent: AppColors.sheetConditionAbove,
                selected: controller.isAbove,
                onTap: () => controller
                    .setCondition(PriceAlertSheetController.conditionAbove),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _ConditionSegment(
                label: TranslationUtils.tr('price_alerts_below'),
                icon: Icons.arrow_downward_rounded,
                accent: AppColors.sheetConditionBelow,
                selected: !controller.isAbove,
                onTap: () => controller
                    .setCondition(PriceAlertSheetController.conditionBelow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _ConditionSegment({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? accent : AppColors.sheetTextMuted;
    final radius = BorderRadius.circular(9.r);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.sheetSurface : Colors.transparent,
          borderRadius: radius,
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 38.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16.r, color: foreground),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13.sp,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                    ),
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

class _NoteSection extends StatelessWidget {
  final PriceAlertSheetController controller;

  const _NoteSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isNoteOpen.value) {
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: controller.toggleNote,
            style: TextButton.styleFrom(
              minimumSize: Size(44.r, 40.r),
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              foregroundColor: AppColors.sheetTextMuted,
            ),
            icon: Icon(Icons.edit_note_rounded, size: 18.r),
            label: Text(
              'Add a note (optional)',
              style: AppTextStyles.label.copyWith(
                fontSize: 12.sp,
                color: AppColors.sheetTextMuted,
              ),
            ),
          ),
        );
      }
      return TextField(
        controller: controller.noteField,
        autofocus: true,
        maxLines: 2,
        minLines: 1,
        maxLength: 120,
        style: AppTextStyles.input.copyWith(
          fontSize: 13.sp,
          color: AppColors.sheetTextPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Note (optional)',
          hintStyle: TextStyle(color: AppColors.sheetTextMuted),
          filled: true,
          fillColor: AppColors.sheetField,
          counterStyle: TextStyle(color: AppColors.sheetTextMuted),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: AppColors.sheetFieldBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: AppColors.sheetFieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppColors.sheetSelectedOutline,
              width: 1.5,
            ),
          ),
        ),
      );
    });
  }
}
