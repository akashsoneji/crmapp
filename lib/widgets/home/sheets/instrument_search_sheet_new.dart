import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/sheets/instrument_search_sheet_controller.dart';
import 'package:crm_app/models/search_instruments_model.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/widgets/home/sheets/sheet_scaffold_new.dart';

/// tenaxnew instrument sheet: the chart symbol picker (favourites only) and
/// the Markets search (all instruments, category chips, favourite toggle).
/// Same content and callbacks as `SearchInstrumentsScreen`.
class InstrumentSearchSheetNew extends GetView<InstrumentSearchSheetController> {
  final String controllerTag;
  final void Function(String)? onNavigateToChart;

  const InstrumentSearchSheetNew({
    super.key,
    required this.controllerTag,
    this.onNavigateToChart,
  });

  @override
  String? get tag => controllerTag;

  static Future<void> show(
    BuildContext context, {
    bool favoritesOnly = false,
    String? activeSymbol,
    void Function(String)? onNavigateToChart,
  }) async {
    final tag = 'instrument_sheet_${DateTime.now().microsecondsSinceEpoch}';
    Get.put(
      InstrumentSearchSheetController(
        favoritesOnly: favoritesOnly,
        activeSymbol: activeSymbol,
      ),
      tag: tag,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) =>
          SheetControllerScope<InstrumentSearchSheetController>(
        tag: tag,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.9,
          child: InstrumentSearchSheetNew(
            controllerTag: tag,
            onNavigateToChart: onNavigateToChart,
          ),
        ),
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffoldNew(
      expand: true,
      header: _SearchHeader(controller: controller),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!controller.favoritesOnly) _CategoryChips(controller: controller),
          Expanded(
            child: controller.favoritesOnly
                ? _FavoritesList(
                    controller: controller,
                    onSelect: (symbol) => _select(context, symbol),
                  )
                : _AllInstrumentsList(
                    controller: controller,
                    onSelect: (symbol) => _select(context, symbol),
                  ),
          ),
        ],
      ),
    );
  }

  void _select(BuildContext context, String symbol) {
    controller.selectSymbol(symbol, onNavigateToChart);
    Navigator.of(context).pop();
  }
}

class _SearchHeader extends StatelessWidget {
  final InstrumentSearchSheetController controller;

  const _SearchHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(12.w, 0, 12.w, 6.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.sheetField,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: AppColors.sheetFieldBorder),
        ),
        child: Row(
          children: [
            SheetIconButtonNew(
              icon: Icons.arrow_back_rounded,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: TextField(
                controller: controller.searchField,
                autofocus: !controller.favoritesOnly,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.input.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.sheetTextPrimary,
                ),
                cursorColor: AppColors.sheetSelectedOutline,
                decoration: InputDecoration(
                  hintText: TranslationUtils.tr('instruments_search'),
                  hintStyle: AppTextStyles.input.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.sheetTextMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Obx(
              () => controller.query.value.isEmpty
                  ? Padding(
                      padding: EdgeInsetsDirectional.only(end: 12.w),
                      child: Icon(
                        Icons.search_rounded,
                        size: 18.r,
                        color: AppColors.sheetTextMuted,
                      ),
                    )
                  : SheetIconButtonNew(
                      icon: Icons.close_rounded,
                      tooltip: 'Clear search',
                      onPressed: controller.clearQuery,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final InstrumentSearchSheetController controller;

  const _CategoryChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = controller.search.availableCategories;
      if (categories.isEmpty) return const SizedBox.shrink();
      final current = controller.search.currentCategory.value;
      return SizedBox(
        height: 40.r,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsetsDirectional.only(start: 12.w, end: 12.w, bottom: 6.h),
          itemCount: categories.length,
          separatorBuilder: (_, __) => SizedBox(width: 6.w),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryChip(
              label: category,
              selected: category == current,
              onTap: () => controller.search.filterByCategory(category),
            );
          },
        ),
      );
    });
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(17.r);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: radius,
          color: selected ? null : AppColors.sheetChipIdle,
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.homeHeaderGradientStart,
                    AppColors.homeHeaderGradientEnd,
                  ],
                )
              : null,
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.sheetChipIdleBorder,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Container(
              constraints: BoxConstraints(minWidth: 48.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.onColoredBackground
                      : AppColors.sheetChipIdleText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  final InstrumentSearchSheetController controller;
  final ValueChanged<String> onSelect;

  const _FavoritesList({required this.controller, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.favoriteResults;
      if (controller.instruments.isLoadingFavorites.value &&
          controller.instruments.instruments.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (items.isEmpty) {
        return const _EmptyState(
          icon: Icons.star_border_rounded,
          title: 'No favourites added',
          subtitle: 'Add symbols from the Quote tab',
        );
      }
      return ListView.separated(
        padding: EdgeInsetsDirectional.fromSTEB(12.w, 2.h, 12.w, 12.h),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: 6.h),
        itemBuilder: (context, index) {
          final symbol = items[index].symbol;
          return InstrumentRowNew(
            symbol: symbol,
            isActive: controller.isActive(symbol),
            onTap: () => onSelect(symbol),
          );
        },
      );
    });
  }
}

class _AllInstrumentsList extends StatelessWidget {
  final InstrumentSearchSheetController controller;
  final ValueChanged<String> onSelect;

  const _AllInstrumentsList({required this.controller, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final search = controller.search;
      if (search.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = search.filteredSymbols;
      if (items.isEmpty) {
        return _EmptyState(
          icon: Icons.search_off_rounded,
          title: TranslationUtils.tr('common_no_data'),
        );
      }
      return ListView.separated(
        padding: EdgeInsetsDirectional.fromSTEB(12.w, 0, 12.w, 8.h),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: 6.h),
        itemBuilder: (context, index) {
          final item = items[index];
          return InstrumentRowNew(
            symbol: item.displaySymbol,
            subtitle: item.categoryName,
            isActive: controller.isActive(item.displaySymbol),
            onTap: () => onSelect(item.displaySymbol),
            trailing: _FavoriteToggle(controller: controller, symbol: item),
          );
        },
      );
    });
  }
}

class _FavoriteToggle extends StatelessWidget {
  final InstrumentSearchSheetController controller;
  final SearchSymbol symbol;

  const _FavoriteToggle({required this.controller, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFavorite = controller.isFavorite(symbol.displaySymbol);
      final name =
          InstrumentSearchSheetController.stripSuffix(symbol.displaySymbol);
      return IconButton(
        tooltip: isFavorite
            ? 'Remove $name from favourites'
            : 'Add $name to favourites',
        constraints: BoxConstraints.tightFor(width: 44.r, height: 44.r),
        padding: EdgeInsets.zero,
        onPressed: () => controller.toggleFavorite(symbol),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isFavorite ? Icons.check_circle_rounded : Icons.add_circle_outline,
            key: ValueKey(isFavorite),
            size: 22.r,
            color: isFavorite
                ? AppColors.sheetSelectedOutline
                : AppColors.sheetTextMuted,
          ),
        ),
      );
    });
  }
}

/// One instrument row: flag avatar, symbol, optional category, and either a
/// trailing widget or a check mark when it is the chart's current symbol.
class InstrumentRowNew extends StatelessWidget {
  final String symbol;
  final String? subtitle;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? trailing;

  const InstrumentRowNew({
    super.key,
    required this.symbol,
    required this.onTap,
    this.subtitle,
    this.isActive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final name = InstrumentSearchSheetController.stripSuffix(symbol);
    final radius = BorderRadius.circular(12.r);
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    return Semantics(
      button: true,
      selected: isActive,
      child: Material(
        color: isActive ? AppColors.sheetSelectedFill : AppColors.sheetRow,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isActive
                ? AppColors.sheetSelectedOutline
                : AppColors.sheetRowDivider,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 48.r),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(10.w, 4.h, 4.w, 4.h),
              child: Row(
                children: [
                  _FlagAvatar(symbol: name),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.input.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sheetTextPrimary,
                          ),
                        ),
                        if (hasSubtitle)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.sheetTextMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else if (isActive)
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 8.w),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18.r,
                        color: AppColors.sheetSelectedOutline,
                        semanticLabel: 'Current symbol',
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

class _FlagAvatar extends StatelessWidget {
  final String symbol;

  const _FlagAvatar({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.show_chart_rounded,
      color: AppColors.sheetSelectedOutline,
      size: 20.r,
    );
    return ExcludeSemantics(
      child: Container(
        width: 32.r,
        height: 32.r,
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: AppColors.sheetAvatarBackground,
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: SvgPicture.asset(
          'assets/svg/flags/${symbol.toLowerCase()}.svg',
          fit: BoxFit.contain,
          placeholderBuilder: (_) => fallback,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _EmptyState({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                color: AppColors.sheetSelectedFill,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26.r, color: AppColors.sheetSelectedOutline),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.sheetTextPrimary,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6.h),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.sheetTextMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
