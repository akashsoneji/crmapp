import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/instruments_controller.dart';
import 'package:crm_app/utils/precision_helper.dart';
import 'package:crm_app/widgets/home/instrument_trade_card.dart';

/// Row of up to 3 compact live-price cards shown above the quick actions.
class TickerCardsRow extends StatelessWidget {
  final List<String> symbols;
  final InstrumentsController controller;
  final ValueChanged<String> onSymbolTap;

  const TickerCardsRow({
    super.key,
    required this.symbols,
    required this.controller,
    required this.onSymbolTap,
  });

  static const int maxCards = 3;

  @override
  Widget build(BuildContext context) {
    if (symbols.isEmpty) return const SizedBox.shrink();
    final visible = symbols.take(maxCards).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < maxCards; i++) ...[
          if (i > 0) SizedBox(width: 8.w),
          Expanded(
            child: i < visible.length
                ? _TickerCard(
                    symbol: visible[i],
                    controller: controller,
                    onTap: () => onSymbolTap(visible[i]),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _TickerCard extends StatelessWidget {
  final String symbol;
  final InstrumentsController controller;
  final VoidCallback onTap;

  const _TickerCard({
    required this.symbol,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.homeCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: AppColors.homeCardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(10.w, 10.h, 8.w, 10.h),
          child: RepaintBoundary(
            child: Obx(() {
              final price = controller.priceRx(symbol).value;
              final formatted = PrecisionHelper.formatPrice(
                price.bid,
                decimals: price.digits,
              );
              return Semantics(
                button: true,
                label: '${homeDisplaySymbol(symbol)} $formatted',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homeDisplaySymbol(symbol),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subheading.copyWith(
                        fontSize: 11.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      formatted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
