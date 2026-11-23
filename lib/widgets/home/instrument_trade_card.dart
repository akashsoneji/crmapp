import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/instruments_controller.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/utils/precision_helper.dart';

/// Symbol without the broker suffix (`EURUSD.c` → `EURUSD`).
String homeDisplaySymbol(String symbol) {
  if (!symbol.contains('.')) return symbol;
  return symbol.substring(0, symbol.lastIndexOf('.'));
}

/// Spread shown as whole points (`0.00003` → `3`, `0.0012` → `12`).
String homeFormatSpread(double spreadDiff) {
  final formatted = spreadDiff.toString();
  if (!formatted.contains('.')) return formatted;
  final parts = formatted.split('.');
  if (parts[0] != '0') return parts[0];
  final trimmed = parts[1].replaceFirst(RegExp(r'^0+'), '');
  return trimmed.isEmpty ? '0' : trimmed;
}

const String _quoteCurrency = 'USDT';

/// Watchlist row on the home tab: symbol + day range on the start side,
/// SELL (bid) and BUY (ask) boxes with the spread badge on the end side.
///
/// Only the price boxes and the range line observe [InstrumentsController.priceRx],
/// so a tick never rebuilds the whole card.
///
/// The card has no outer margin: the caller spaces it, so a swipe-to-remove
/// background can start exactly at the card's edge.
class InstrumentTradeCard extends StatelessWidget {
  final String symbol;
  final InstrumentsController controller;
  final VoidCallback onTap;

  const InstrumentTradeCard({
    super.key,
    required this.symbol,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.homeCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(color: AppColors.homeCardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        // Rows are long-pressed to reorder; a press flash reads as selection.
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(4.w, 12.h, 10.w, 12.h),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.drag_indicator,
                  size: 20.r,
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _SymbolColumn(symbol: symbol, controller: controller),
              ),
              SizedBox(width: 8.w),
              _PriceBoxes(symbol: symbol, controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymbolColumn extends StatelessWidget {
  final String symbol;
  final InstrumentsController controller;

  const _SymbolColumn({required this.symbol, required this.controller});

  @override
  Widget build(BuildContext context) {
    final display = homeDisplaySymbol(symbol);
    final hasQuoteSuffix =
        display.length > _quoteCurrency.length &&
        display.toUpperCase().endsWith(_quoteCurrency);
    final base = hasQuoteSuffix
        ? display.substring(0, display.length - _quoteCurrency.length)
        : display;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: base,
            style: AppTextStyles.heading.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            children: [
              if (hasQuoteSuffix)
                TextSpan(
                  text: '/$_quoteCurrency',
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.textGrey,
                  ),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        // Day range until the feed provides a previous close for % change.
        Obx(() {
          final price = controller.priceRx(symbol).value;
          if (price.dayLow <= 0 && price.dayHigh <= 0) {
            return const SizedBox.shrink();
          }
          final low = PrecisionHelper.formatPrice(
            price.dayLow,
            decimals: price.digits,
          );
          final high = PrecisionHelper.formatPrice(
            price.dayHigh,
            decimals: price.digits,
          );
          final style = AppTextStyles.subheading.copyWith(
            fontSize: 11.sp,
            height: 1.2,
          );
          return Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'L ',
                  style: style.copyWith(color: AppColors.textGrey),
                ),
                TextSpan(
                  text: low,
                  style: style.copyWith(color: AppColors.red),
                ),
                TextSpan(
                  text: '  H ',
                  style: style.copyWith(color: AppColors.textGrey),
                ),
                TextSpan(
                  text: high,
                  style: style.copyWith(color: AppColors.green),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
      ],
    );
  }
}

class _PriceBoxes extends StatelessWidget {
  final String symbol;
  final InstrumentsController controller;

  const _PriceBoxes({required this.symbol, required this.controller});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PriceBox(
              label: languageService.tr('home_sell'),
              symbol: symbol,
              controller: controller,
              isBuy: false,
            ),
            SizedBox(width: 10.w),
            PriceBox(
              label: languageService.tr('home_buy'),
              symbol: symbol,
              controller: controller,
              isBuy: true,
            ),
          ],
        ),
        _SpreadBadge(symbol: symbol, controller: controller),
      ],
    );
  }
}

/// SELL (bid) or BUY (ask) box. Repaints on its own when the price ticks.
class PriceBox extends StatelessWidget {
  final String label;
  final String symbol;
  final InstrumentsController controller;
  final bool isBuy;

  const PriceBox({
    super.key,
    required this.label,
    required this.symbol,
    required this.controller,
    required this.isBuy,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBuy ? AppColors.green : AppColors.red;
    final borderColor = isBuy
        ? AppColors.homeBuyBoxBorder
        : AppColors.homeSellBoxBorder;
    // Opaque fill: the gradient border below is painted as the outer box, so
    // a translucent fill would let it show through the whole box.
    final fill = Color.alphaBlend(
      isBuy ? AppColors.homeBuyBoxBackground : AppColors.homeSellBoxBackground,
      AppColors.homeCardBackground,
    );
    const borderWidth = 1.5;
    final outerRadius = 8.r;

    // Border fades from invisible at the top to solid at the bottom, and the
    // fill lightens downwards, as in the design.
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(outerRadius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [borderColor.withValues(alpha: 0), borderColor],
            stops: const [0.05, 0.6],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(borderWidth),
          child: Container(
            width: 84.w - borderWidth * 2,
            padding: EdgeInsetsDirectional.fromSTEB(
              8.w - borderWidth,
              5.h - borderWidth,
              8.w - borderWidth,
              6.h - borderWidth,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(outerRadius - borderWidth),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  fill,
                  Color.alphaBlend(
                    AppColors.homeCardBackground.withValues(alpha: 0.6),
                    fill,
                  ),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: isBuy
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.subheading.copyWith(
                    fontSize: 10.sp,
                    color: AppColors.textGrey,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 2.h),
                Obx(() {
                  final price = controller.priceRx(symbol).value;
                  final value = isBuy ? price.ask : price.bid;
                  final formatted = PrecisionHelper.formatPrice(
                    value,
                    decimals: price.digits,
                  );
                  return Semantics(
                    label: '$label $formatted',
                    excludeSemantics: true,
                    // Long prices (e.g. BTC) must stay on one line inside the fixed box.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: isBuy
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Text.rich(
                        _splitPrice(formatted, color),
                        maxLines: 1,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Leading digits regular, last two digits emphasised (`4643.` + `25`).
  static TextSpan _splitPrice(String formatted, Color color) {
    final leadStyle = TextStyle(
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    final tailStyle = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w700,
      color: color,
    );
    if (formatted.length < 3) {
      return TextSpan(text: formatted, style: tailStyle);
    }
    final split = formatted.length - 2;
    return TextSpan(
      children: [
        TextSpan(text: formatted.substring(0, split), style: leadStyle),
        TextSpan(text: formatted.substring(split), style: tailStyle),
      ],
    );
  }
}

class _SpreadBadge extends StatelessWidget {
  final String symbol;
  final InstrumentsController controller;

  const _SpreadBadge({required this.symbol, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.homeCardBackground,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
      ),
      child: Obx(() {
        final spread = controller.priceRx(symbol).value.spreadDiff;
        return Text(
          homeFormatSpread(spread),
          textAlign: TextAlign.center,
          style: AppTextStyles.subheading.copyWith(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        );
      }),
    );
  }
}
