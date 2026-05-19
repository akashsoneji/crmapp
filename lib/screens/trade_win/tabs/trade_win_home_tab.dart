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
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/screens/trade_win/trade_win_theme.dart';
import 'package:crm_app/screens/trade_win/widgets/trade_win_product_image.dart';

class TradeWinHomeTab extends StatelessWidget {
  const TradeWinHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final controller = Get.find<TradeWinController>();

    return Obx(() {
      if (controller.isLoading.value && controller.products.isEmpty) {
        return Center(
          child: CommonLoadingWidget(size: 40, color: AppColors.primary),
        );
      }

      if (!controller.moduleEnabled.value) {
        return _ModuleDisabled(languageService: languageService);
      }

      final stats = controller.stats.value;

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => controller.fetchProducts(showLoader: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: SvgPicture.asset(
                        'assets/svg/trade/arro_back.svg',
                        colorFilter: ColorFilter.mode(
                          AppColors.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        languageService.tr('tw_title'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: _PointsCard(stats: stats, languageService: languageService),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
                child: _OverviewSection(
                  controller: controller,
                  languageService: languageService,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageService.tr('tw_product_catalog'),
                      style: AppTextStyles.headingblack,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                final cats = controller.categories;
                return SizedBox(
                  height: 40.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final cat = cats[index];
                      final selected =
                          controller.selectedCategory.value == cat;
                      final label = cat == 'all'
                          ? languageService.tr('tw_all')
                          : TradeWinFormat.categoryLabel(cat);
                      return GestureDetector(
                        onTap: () => controller.selectCategory(cat),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? TradeWinTheme.chipSelectedBg
                                : TradeWinTheme.chipUnselectedBg,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: selected
                                  ? TradeWinTheme.chipSelectedBorder
                                  : TradeWinTheme.chipUnselectedBorder,
                              width: selected
                                  ? TradeWinTheme.chipSelectedBorderWidth
                                  : TradeWinTheme.chipUnselectedBorderWidth,
                            ),
                            boxShadow: selected && AppColors.isDarkMode
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: selected
                                  ? TradeWinTheme.chipSelectedFg
                                  : TradeWinTheme.chipUnselectedFg,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
            Obx(() {
              final items = controller.filteredProducts;
              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.h),
                    child: Center(
                      child: Text(
                        languageService.tr('tw_no_products'),
                        style: AppTextStyles.subheading,
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                    child: _ProductCatalogCard(
                      product: items[index],
                      languageService: languageService,
                    ),
                  ),
                  childCount: items.length,
                ),
              );
            }),
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
      );
    });
  }
}

class _ModuleDisabled extends StatelessWidget {
  final LanguageService languageService;

  const _ModuleDisabled({required this.languageService});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              languageService.tr('tw_module_disabled'),
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(languageService.tr('tw_back')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  final dynamic stats;
  final LanguageService languageService;

  const _PointsCard({required this.stats, required this.languageService});

  @override
  Widget build(BuildContext context) {
    final points = stats?.totalPoints ?? 0;
    final spentLots = stats?.spentLots ?? 0;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: TradeWinTheme.heroCardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: TradeWinTheme.heroCardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageService.tr('tw_available_points'),
            style: AppTextStyles.subheading.copyWith(
              color: TradeWinTheme.onAccentFill.withValues(alpha: 0.85),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 28.sp),
              SizedBox(width: 8.w),
              Text(
                TradeWinFormat.points(points),
                style: AppTextStyles.centerbodyHeading.copyWith(
                  color: TradeWinTheme.onAccentFill,
                  fontSize: 28.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            languageService.tr('tw_total_spent_claims', {
              'lots': TradeWinFormat.lots(spentLots),
            }),
            style: AppTextStyles.subheading.copyWith(
              color: TradeWinTheme.onAccentFill.withValues(alpha: 0.75),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final TradeWinController controller;
  final LanguageService languageService;

  const _OverviewSection({
    required this.controller,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageService.tr('tw_overview'),
          style: AppTextStyles.headingblack,
        ),
        SizedBox(height: 12.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 1.6,
          children: [
            _OverviewTile(
              value: TradeWinFormat.lots(stats?.totalLots ?? 0),
              label: languageService.tr('tw_total_lots'),
              valueColor: AppColors.quickActionBlue,
            ),
            _OverviewTile(
              value: '${stats?.pastWinsCount ?? 0}',
              label: languageService.tr('tw_past_wins'),
              valueColor: AppColors.green,
            ),
            _OverviewTile(
              value: TradeWinFormat.currency(stats?.totalPrizeValueWon ?? 0),
              label: languageService.tr('tw_total_prize'),
              valueColor: AppColors.quickActionOrange,
            ),
            _OverviewTile(
              value: '${controller.pastWins.length}',
              label: languageService.tr('tw_redemptions'),
              valueColor: AppColors.quickActionBlue,
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _OverviewTile({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.icongrey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.headingblack.copyWith(
              fontSize: 20.sp,
              color: valueColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(label, style: AppTextStyles.subheading.copyWith(fontSize: 12.sp)),
        ],
      ),
    );
  }
}

class _ProductCatalogCard extends StatelessWidget {
  final TradeWinProductModel product;
  final LanguageService languageService;

  const _ProductCatalogCard({
    required this.product,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    final progress = product.progressFraction;
    final percent = (progress * 100).round();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.icongrey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TradeWinProductImage(
                imagePath: product.imagePath,
                width: 80.w,
                height: 80.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: AppTextStyles.headingblack,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            TradeWinFormat.categoryTag(product.category),
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14.sp, color: Colors.amber),
                        SizedBox(width: 4.w),
                        Text(
                          TradeWinFormat.points(product.requiredPoints),
                          style: AppTextStyles.subheading.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: TradeWinTheme.accentFill,
                            borderRadius: BorderRadius.circular(12.r),
                            border: AppColors.isDarkMode
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  )
                                : null,
                          ),
                          child: Text(
                            languageService.tr('tw_lot_required_chip', {
                              'lots': TradeWinFormat.lots(product.requiredLots),
                            }),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: TradeWinTheme.onAccentFill,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6.h,
              backgroundColor: AppColors.icongrey.withValues(alpha: 0.2),
              color: AppColors.green,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            languageService.tr('tw_progress_lots', {
              'current': TradeWinFormat.lots(product.availableLots),
              'required': TradeWinFormat.lots(product.requiredLots),
              'percent': '$percent',
            }),
            style: AppTextStyles.subheading.copyWith(fontSize: 12.sp),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _onRedeem(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: TradeWinTheme.accentFill,
                foregroundColor: TradeWinTheme.onAccentFill,
                padding: EdgeInsets.symmetric(vertical: 12.h),
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
    );
  }

  void _onRedeem(BuildContext context) {
    if (!product.canRedeem) {
      CustomToastService.show(
        message: languageService.tr('tw_insufficient_eligibility'),
        type: ToastType.warning,
      );
      return;
    }
    Get.toNamed(
      AppPages.TRADE_WIN_PRODUCT_DETAIL,
      arguments: {'productId': product.id},
    );
  }
}
