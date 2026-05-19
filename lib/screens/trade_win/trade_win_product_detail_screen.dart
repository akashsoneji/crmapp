import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/trade_win/trade_win_controller.dart';
import 'package:crm_app/models/trade_win/trade_win_product_model.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/utils/trade_win_format.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/screens/trade_win/trade_win_theme.dart';
import 'package:crm_app/screens/trade_win/widgets/trade_win_product_image.dart';

class TradeWinProductDetailScreen extends StatefulWidget {
  const TradeWinProductDetailScreen({super.key});

  @override
  State<TradeWinProductDetailScreen> createState() =>
      _TradeWinProductDetailScreenState();
}

class _TradeWinProductDetailScreenState
    extends State<TradeWinProductDetailScreen> {
  int _quantity = 1;
  TradeWinProductModel? _product;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    final productId = args?['productId'] as int?;
    final ctrl = Get.find<TradeWinController>();
    if (productId != null) {
      _product = ctrl.productById(productId);
    }
    _product ??= args?['product'] as TradeWinProductModel?;
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final product = _product;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: SvgPicture.asset(
              'assets/svg/trade/arro_back.svg',
              colorFilter: ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
            ),
          ),
        ),
        body: Center(child: Text(languageService.tr('tw_product_not_found'))),
      );
    }

    final maxQty = product.stock > 0 ? product.stock : 1;

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          languageService.tr('tw_product_detail'),
          style: AppTextStyles.heading,
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset(
            'assets/svg/trade/arro_back.svg',
            colorFilter: ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TradeWinProductImage(
              imagePath: product.imagePath,
              width: double.infinity,
              height: 200.h,
              borderRadius: BorderRadius.circular(16.r),
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  TradeWinFormat.categoryTag(product.category),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(product.name, style: AppTextStyles.centerbodyHeading),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    label: languageService.tr('tw_point_cost'),
                    value: TradeWinFormat.points(product.requiredPoints),
                    sub: languageService.tr('tw_available_balance'),
                    bg: AppColors.warningBg,
                    labelColor: AppColors.warningText,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _InfoCard(
                    label: languageService.tr('tw_lot_required'),
                    value: languageService.tr('tw_lot_required_chip', {
                      'lots': TradeWinFormat.lots(product.requiredLots),
                    }),
                    sub: languageService.tr('tw_closed_trades_only'),
                    bg: TradeWinTheme.accentFill,
                    labelColor: TradeWinTheme.onAccentFill,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.icongrey.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  _Row(
                    label: languageService.tr('tw_your_available_lots'),
                    value: TradeWinFormat.lots(product.availableLots),
                    valueColor: AppColors.green,
                  ),
                  Divider(height: 1, color: AppColors.icongrey.withValues(alpha: 0.15)),
                  _Row(
                    label: languageService.tr('tw_your_available_points'),
                    value: TradeWinFormat.points(product.calculatedPoints),
                    valueColor: AppColors.green,
                  ),
                  Divider(height: 1, color: AppColors.icongrey.withValues(alpha: 0.15)),
                  _Row(
                    label: languageService.tr('tw_stock_left'),
                    value: languageService.tr('tw_stock_count', {
                      'count': '${product.stock}',
                    }),
                    valueColor: AppColors.quickActionOrange,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            _Row(
              label: languageService.tr('tw_product_value'),
              value: TradeWinFormat.currency(product.prizeValue),
            ),
            SizedBox(height: 8.h),
            _Row(
              label: languageService.tr('tw_claimed'),
              value: languageService.tr('tw_claimed_times', {
                'count': '${product.claimsCount}',
              }),
            ),
            SizedBox(height: 20.h),
            Text(
              languageService.tr('tw_about_product'),
              style: AppTextStyles.headingblack,
            ),
            SizedBox(height: 8.h),
            Text(
              product.description.isNotEmpty
                  ? product.description
                  : languageService.tr('tw_no_description'),
              style: AppTextStyles.subheading,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.icongrey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: Icon(Icons.remove, color: TradeWinTheme.onAccentFill),
                    ),
                    Text('$_quantity', style: AppTextStyles.headingblack),
                    IconButton(
                      onPressed: _quantity < maxQty
                          ? () => setState(() => _quantity++)
                          : null,
                      icon: Icon(Icons.add, color: TradeWinTheme.onAccentFill),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _redeem(product, languageService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TradeWinTheme.accentFill,
                    foregroundColor: TradeWinTheme.onAccentFill,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: AppColors.isDarkMode
                          ? BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    languageService.tr('tw_redeem_now'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                      color: TradeWinTheme.onAccentFill,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _redeem(TradeWinProductModel product, LanguageService languageService) {
    if (!product.canRedeem) {
      CustomToastService.show(
        message: languageService.tr('tw_insufficient_eligibility'),
        type: ToastType.warning,
      );
      return;
    }
    Get.toNamed(
      AppPages.TRADE_WIN_REDEEM,
      arguments: {'product': product, 'quantity': _quantity},
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color bg;
  final Color labelColor;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.bg,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(value, style: AppTextStyles.headingblack.copyWith(fontSize: 18.sp)),
          SizedBox(height: 4.h),
          Text(sub, style: AppTextStyles.subheading.copyWith(fontSize: 11.sp)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: valueColor == null ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.headingblack.copyWith(
              fontSize: 14.sp,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
