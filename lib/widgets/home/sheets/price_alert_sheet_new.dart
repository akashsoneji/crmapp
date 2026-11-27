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
import 'package:crm_app/widgets/pending_order/pending_order_widgets_new.dart';

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
            _QuoteRow(controller: controller),
            SizedBox(height: 16.h),
            const PendingSectionLabelNew('CONDITION'),
            _ConditionToggle(controller: controller),
            SizedBox(height: 16.h),
            PendingSectionLabelNew(
              'TARGET PRICE',
              trailing: _DistanceChip(controller: controller),
            ),
            PendingStepperFieldNew(
              semanticsName: 'price',
              controller: controller.priceField,
              onDecrement: controller.stepDown,
              onIncrement: controller.stepUp,
              onChanged: controller.onPriceTyped,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            SizedBox(height: 16.h),
            _NoteSection(controller: controller),
            SizedBox(height: 16.h),
            Obx(
              () => SheetGradientButtonNew(
                label: _ctaLabel(controller),
                isLoading: controller.isLoading.value,
                onPressed: () => _submit(context),
              ),
            ),
            SizedBox(height: 12.h),
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
    // homeIconTint is brand in light and white in dark; the old dark-purple
    // outline colour was unreadable on the dark sheet.
    final color = AppColors.homeIconTint;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size(44.r, 44.r),
        foregroundColor: color,
      ),
      icon: Icon(Icons.list_alt_rounded, size: 16.r),
      label: Text(
        TranslationUtils.tr('price_alerts_my_alerts'),
        style: AppTextStyles.label.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Symbol on the left, live bid on the right; tapping the bid copies it
/// into the target price.
class _QuoteRow extends StatelessWidget {
  final PriceAlertSheetController controller;

  const _QuoteRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    final sellAccent = AppColors.chartSellAccent;
    return Material(
      color: AppColors.chartPillBackground,
      borderRadius: radius,
      child: Obx(() {
        final bid = controller.format(controller.liveBid.value);
        return Semantics(
          button: true,
          label: '${controller.symbol}, bid $bid, tap to use it as the price',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              HapticFeedback.selectionClick();
              controller.useLiveBid();
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 44.r),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.symbol,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: sellAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'BID',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: sellAccent,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      bid,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.south_west_rounded,
                      size: 14.r,
                      color: AppColors.textGrey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Signed distance of the target from the bid, e.g. "+0.83 (+0.02%)".
/// The sign and the wording in the screen-reader label carry the direction,
/// not the colour alone.
class _DistanceChip extends StatelessWidget {
  final PriceAlertSheetController controller;

  const _DistanceChip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final distance = controller.distance;
      final isUp = distance >= 0;
      final color = distance == 0
          ? AppColors.textGrey
          : (isUp ? AppColors.chartBuyAccent : AppColors.chartSellAccent);
      final sign = distance == 0 ? '' : (isUp ? '+' : '−');
      final amount = controller.format(distance.abs());
      final pct = controller.distancePercent.abs().toStringAsFixed(2);
      final direction = distance == 0 ? 'at' : (isUp ? 'above' : 'below');
      return Semantics(
        label: '$amount, $pct percent $direction bid',
        excludeSemantics: true,
        child: Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: 6.w,
            vertical: 2.h,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            '$sign$amount ($sign$pct%)',
            style: AppTextStyles.label.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    });
  }
}

/// Above / Below as the same sliding segment the pending order sheet uses.
/// The thumb colour follows the direction; the label text carries the state.
class _ConditionToggle extends StatelessWidget {
  final PriceAlertSheetController controller;

  const _ConditionToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isAbove = controller.isAbove;
      return PendingSegmentedNew(
        options: [
          TranslationUtils.tr('price_alerts_above'),
          TranslationUtils.tr('price_alerts_below'),
        ],
        selectedIndex: isAbove ? 0 : 1,
        onSelected: (index) => controller.setCondition(
          index == 0
              ? PriceAlertSheetController.conditionAbove
              : PriceAlertSheetController.conditionBelow,
        ),
        thumbColor:
            isAbove ? AppColors.chartBuyAccent : AppColors.chartSellAccent,
        selectedTextColor: AppColors.onColoredBackground,
        height: 40.h,
        semanticsPrefix: 'Alert when price is ',
      );
    });
  }
}

/// Collapsed: a field-shaped row that opens the note. Open: the note field
/// in the same shape, so the layout does not jump.
class _NoteSection extends StatelessWidget {
  final PriceAlertSheetController controller;

  const _NoteSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    return Obx(() {
      if (!controller.isNoteOpen.value) {
        return Material(
          color: AppColors.chartPillBackground,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: controller.toggleNote,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 44.r),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 18.r,
                      color: AppColors.textGrey,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Add a note (optional)',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.add_rounded,
                      size: 18.r,
                      color: AppColors.textGrey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PendingSectionLabelNew('NOTE'),
          TextField(
            controller: controller.noteField,
            autofocus: true,
            maxLines: 2,
            minLines: 1,
            maxLength: 120,
            style: AppTextStyles.input.copyWith(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'e.g. Take profit zone',
              hintStyle: TextStyle(color: AppColors.textGrey),
              filled: true,
              fillColor: AppColors.chartPillBackground,
              counterStyle: TextStyle(color: AppColors.textGrey),
              contentPadding: EdgeInsetsDirectional.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(
                  color: AppColors.homeIconTint,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
