import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/screens/home/more/finance/internal_transfer_screen.dart';
import 'package:crm_app/screens/home/more/finance/payment_methods_screen.dart';
import 'package:crm_app/controllers/wallet_controller.dart';
import 'package:crm_app/utils/navigation_helper.dart';
import '../../../../services/language_service.dart';
import '../../../../widgets/common_loading_widget.dart';
import '../../../../widgets/custom_toast.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletController controller = Get.put(WalletController());
  final LanguageService languageService = Get.find<LanguageService>();
  late final ScrollController _scrollController;
  final GlobalKey _filterButtonKey = GlobalKey();

  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  static final NumberFormat _amountFormat = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200.h) {
        controller.loadMoreTransactions();
      }
    });
    // Trigger fresh load on enter
    controller.fetchWalletData();
    controller.fetchWalletHistory(page: 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasDateFilter =>
      controller.filterDateFrom.value.isNotEmpty ||
      controller.filterDateTo.value.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 10.w),
          child: IconButton(
            icon: SvgPicture.asset(
              "assets/svg/trade/arro_back.svg",
              height: 24.h,
              width: 24.w,
              colorFilter: ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
            ),
            onPressed: () => NavigationHelper.safeBack(context: context),
          ),
        ),
        title: Text(
          languageService.tr('wallet_title'),
          style: AppTextStyles.screenTitle,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Obx(() {
              final visible = controller.visibleHistoryTransactions;
              final isInitialLoading =
                  controller.isHistoryLoading.value && visible.isEmpty;
              // Tabs are split client-side, so the visible tab can be empty
              // while later pages are still being fetched to fill it.
              final isFillingTab = visible.isEmpty &&
                  (controller.isLoadingMore.value || controller.hasMore.value);
              final showDateChip = _hasDateFilter;
              final controlsExtent = showDateChip ? 54.h + 38.h : 54.h;

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildWalletHeader()),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedControlsDelegate(
                      extent: controlsExtent,
                      child: _buildHistoryControls(showDateChip),
                    ),
                  ),
                  if (isInitialLoading || isFillingTab)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else ...[
                    _buildGroupedList(visible),
                    SliverToBoxAdapter(child: _buildListFooter(visible)),
                  ],
                ],
              );
            }),
          ),

          // Processing overlay (used for deposit, transfers)
          Obx(
            () =>
                controller.isLoading.value
                    ? CommonLoadingWidget(
                      message: languageService.tr('wallet_processing'),
                      size: 60.0,
                      color: AppColors.primary,
                      isFullScreen: true,
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isCompletedTab =
        controller.selectedHistoryTab.value == WalletHistoryTab.completed;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 40.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              languageService.tr('transaction_history_no_transactions'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isCompletedTab) ...[
              SizedBox(height: 6.h),
              Text(
                languageService.tr('wallet_history_completed_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(List<WalletHistoryEntry> entries) {
    final groups = _groupByDay(entries);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildTransactionGroup(
            groups[index].key,
            groups[index].value,
          ),
          childCount: groups.length,
        ),
      ),
    );
  }

  Widget _buildListFooter(List<WalletHistoryEntry> visible) {
    Widget child = const SizedBox.shrink();
    if (controller.isLoadingMore.value) {
      child = CircularProgressIndicator(color: AppColors.primary);
    } else if (!controller.hasMore.value && visible.isNotEmpty) {
      child = Text(
        languageService.tr('wallet_history_no_more'),
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(child: child),
    );
  }

  Widget _buildWalletHeader() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageService.tr('wallet_history_current_balance'),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Obx(
                      () => Text(
                        '\$${controller.balance.value}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Obx(() {
            final walletId = controller.wallet.value?.walletId ?? '';
            return InkWell(
              onTap: walletId.isEmpty
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: walletId));
                      CustomToastService.showSuccess(
                        message: languageService.tr('deposit_instruction_copied'),
                      );
                    },
              child: Row(
                children: [
                  Text(
                    '${languageService.tr('wallet_wallet_id')}: ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      walletId,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (walletId.isNotEmpty) ...[
                    SizedBox(width: 6.w),
                    Icon(Icons.copy, size: 13.sp, color: AppColors.textSecondary),
                  ],
                ],
              ),
            );
          }),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _buildHeaderAction(
                  label: languageService.tr('wallet_deposit_wallet'),
                  icon: Icons.add_circle_outline,
                  isPrimary: true,
                  onPressed: () {
                    Get.to(() => PaymentMethodsScreen(accountNumber: ''));
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildHeaderAction(
                  label: languageService.tr('internal_transfer'),
                  icon: Icons.swap_horiz,
                  isPrimary: false,
                  onPressed: () {
                    Get.to(() => InternalTransferScreen(preselectWallet: true));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    final foreground = isPrimary ? Colors.white : AppColors.primary;
    return SizedBox(
      height: 40.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16.sp, color: foreground),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: foreground,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryControls(bool showDateChip) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 54.h,
            child: Row(
              children: [
                Expanded(child: _buildStatusSegmentedControl()),
                SizedBox(width: 8.w),
                _buildSquareIconButton(
                  key: _filterButtonKey,
                  icon: Icons.tune,
                  isActive: showDateChip,
                  onTap: _showFilterPopup,
                ),
              ],
            ),
          ),
          if (showDateChip)
            SizedBox(
              height: 38.h,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: _buildFilterChip(
                  label: _dateRangeLabel(),
                  onDeleted: controller.clearFilters,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _dateRangeLabel() {
    final from = controller.filterDateFrom.value;
    final to = controller.filterDateTo.value;
    if (from.isNotEmpty && to.isNotEmpty) return '$from → $to';
    if (from.isNotEmpty) return '${languageService.tr('ibm_from_date')}: $from';
    return '${languageService.tr('ibm_to_date')}: $to';
  }

  (String, Color) _tabVisual(WalletHistoryTab tab) {
    switch (tab) {
      case WalletHistoryTab.completed:
        return (languageService.tr('transaction_history_completed'), AppColors.success);
      case WalletHistoryTab.pending:
        return (languageService.tr('transaction_history_pending'), AppColors.warning);
      case WalletHistoryTab.rejected:
        return (languageService.tr('ibm_status_rejected'), AppColors.error);
    }
  }

  Widget _buildStatusSegmentedControl() {
    final selected = controller.selectedHistoryTab.value;
    return Container(
      height: 38.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: WalletHistoryTab.values.map((tab) {
          final (label, color) = _tabVisual(tab);
          final isSelected = tab == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.selectHistoryTab(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: isSelected
                      ? Border.all(color: color.withValues(alpha: 0.4))
                      : null,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSquareIconButton({
    Key? key,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 38.h,
        height: 38.h,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: isActive ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 11.sp, color: AppColors.primary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(Icons.close, size: 12.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Opens the date filter as a popup anchored under the filter button rather
  /// than a full bottom sheet.
  void _showFilterPopup() {
    final buttonContext = _filterButtonKey.currentContext;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final buttonBox = buttonContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null || overlayBox == null) return;

    final buttonRect = buttonBox.localToGlobal(
          Offset.zero,
          ancestor: overlayBox,
        ) &
        buttonBox.size;
    final popupWidth = 280.w;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final left = isRtl
        ? buttonRect.left
        : (buttonRect.right - popupWidth).clamp(8.0, overlayBox.size.width - popupWidth - 8.0);

    var localFrom = controller.filterDateFrom.value;
    var localTo = controller.filterDateTo.value;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (dialogContext, _, __) {
        return Stack(
          children: [
            Positioned(
              top: buttonRect.bottom + 6.h,
              left: left,
              width: popupWidth,
              child: Material(
                color: AppColors.cardBackground,
                elevation: 8,
                borderRadius: BorderRadius.circular(14.r),
                child: StatefulBuilder(
                  builder: (popupContext, setPopupState) {
                    return Padding(
                      padding: EdgeInsets.all(14.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageService.tr('wallet_screen_date_range'),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          _buildDateField(
                            label: languageService.tr('ibm_from_date'),
                            value: localFrom,
                            onTap: () async {
                              final picked = await _pickDate(popupContext, localFrom);
                              if (picked != null) setPopupState(() => localFrom = picked);
                            },
                          ),
                          SizedBox(height: 8.h),
                          _buildDateField(
                            label: languageService.tr('ibm_to_date'),
                            value: localTo,
                            onTap: () async {
                              final picked = await _pickDate(popupContext, localTo);
                              if (picked != null) setPopupState(() => localTo = picked);
                            },
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    controller.clearFilters();
                                  },
                                  child: Text(
                                    languageService.tr('common_reset'),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (localFrom.isNotEmpty &&
                                        localTo.isNotEmpty &&
                                        localTo.compareTo(localFrom) < 0) {
                                      CustomToastService.showError(
                                        message: languageService.tr('trade_date_range_error'),
                                      );
                                      return;
                                    }
                                    Navigator.pop(dialogContext);
                                    controller.filterDateFrom.value = localFrom;
                                    controller.filterDateTo.value = localTo;
                                    controller.applyFilters();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: Text(
                                    languageService.tr('common_apply'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _pickDate(BuildContext pickerContext, String current) async {
    final isDark =
        Theme.of(pickerContext).brightness == Brightness.dark || AppColors.isDarkMode;
    final now = DateTime.now();
    final initial = DateTime.tryParse(current) ?? now;
    final picked = await showDatePicker(
      context: pickerContext,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.cardBackground,
                    onSurface: AppColors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.cardBackground,
                    onSurface: AppColors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );
    return picked == null ? null : _apiDateFormat.format(picked);
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        height: 42.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? label : value,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: value.isEmpty ? AppColors.hint : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.calendar_today, size: 14.sp, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  /// Groups consecutive entries by calendar day, preserving server order.
  List<MapEntry<DateTime?, List<WalletHistoryEntry>>> _groupByDay(
    List<WalletHistoryEntry> entries,
  ) {
    final groups = <MapEntry<DateTime?, List<WalletHistoryEntry>>>[];
    for (final entry in entries) {
      final created = entry.createdAt;
      final day = created == null
          ? null
          : DateTime(created.year, created.month, created.day);
      if (groups.isNotEmpty && groups.last.key == day) {
        groups.last.value.add(entry);
      } else {
        groups.add(MapEntry(day, [entry]));
      }
    }
    return groups;
  }

  Widget _buildTransactionGroup(DateTime? day, List<WalletHistoryEntry> entries) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
            child: Text(
              _formatDate(day),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 60.w,
                      color: AppColors.border.withValues(alpha: 0.2),
                    ),
                  _buildTransactionTile(entries[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(WalletHistoryEntry entry) {
    final (icon, iconColor, typeLabel) = _typeVisual(entry);
    final time = entry.createdAt == null
        ? ''
        : DateFormat('hh:mm a').format(entry.createdAt!);
    final subtitle = [entry.reference, time].where((part) => part.isNotEmpty).join(' • ');

    return InkWell(
      onTap: () => _showTransactionDetails(entry),
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18.sp, color: iconColor),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatSignedAmount(entry),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: entry.isCredit ? AppColors.success : AppColors.error,
                  ),
                ),
                SizedBox(height: 4.h),
                _buildStatusBadge(entry, fontSize: 9.sp),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSignedAmount(WalletHistoryEntry entry) {
    final sign = entry.isCredit ? '+' : '-';
    return '$sign\$${_amountFormat.format(entry.amount.abs())}';
  }

  String _formatDate(DateTime? day) {
    if (day == null) return '-';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return languageService.tr('time_today');
    if (day == today.subtract(const Duration(days: 1))) {
      return languageService.tr('time_yesterday');
    }
    return DateFormat('dd MMM yyyy').format(day);
  }

  (Color, Color) _statusColors(WalletHistoryTab tab) {
    switch (tab) {
      case WalletHistoryTab.completed:
        return (AppColors.successBg, AppColors.successText);
      case WalletHistoryTab.pending:
        return (AppColors.warningBg, AppColors.warningText);
      case WalletHistoryTab.rejected:
        return (AppColors.errorBg, AppColors.errorText);
    }
  }

  (IconData, Color, String) _typeVisual(WalletHistoryEntry entry) {
    final type = entry.type.toLowerCase();
    final label = entry.type.isEmpty
        ? languageService.tr('transaction_history_transaction_type')
        : toBeginningOfSentenceCase(entry.type.replaceAll('_', ' '));
    if (type.contains('deposit')) {
      return (Icons.arrow_downward, AppColors.success, label);
    }
    if (type.contains('withdraw')) {
      return (Icons.arrow_upward, AppColors.error, label);
    }
    return (Icons.swap_horiz, AppColors.blue, label);
  }

  Widget _buildStatusBadge(WalletHistoryEntry entry, {required double fontSize}) {
    final (background, foreground) = _statusColors(entry.tab);
    final status = entry.status.isEmpty ? _tabVisual(entry.tab).$1 : entry.status;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }

  void _showTransactionDetails(WalletHistoryEntry entry) {
    final (_, _, typeLabel) = _typeVisual(entry);
    final dateText = entry.createdAt == null
        ? '-'
        : DateFormat('dd MMM yyyy, hh:mm a').format(entry.createdAt!);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20.w,
            16.h,
            20.w,
            MediaQuery.of(sheetContext).padding.bottom + 20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    languageService.tr('ibm_transaction_details'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Divider(color: AppColors.border.withValues(alpha: 0.2)),
              SizedBox(height: 12.h),
              Center(
                child: Column(
                  children: [
                    Text(
                      _formatSignedAmount(entry),
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        color: entry.isCredit ? AppColors.success : AppColors.error,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _buildStatusBadge(entry, fontSize: 11.sp),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              _buildDetailRow(
                languageService.tr('tw_reference_number'),
                entry.reference.isEmpty ? '-' : entry.reference,
              ),
              _buildDetailRow(
                languageService.tr('transaction_history_transaction_type'),
                typeLabel,
              ),
              if (entry.paymentMethod.isNotEmpty)
                _buildDetailRow(
                  languageService.tr('wallet_history_payment_method'),
                  entry.paymentMethod,
                ),
              _buildDetailRow(
                languageService.tr('wallet_history_account'),
                entry.account.isEmpty
                    ? languageService.tr('wallet_title')
                    : 'MT5: ${entry.account}',
              ),
              _buildDetailRow(languageService.tr('transaction_history_date'), dateText),
              if (entry.tab == WalletHistoryTab.rejected && entry.reason.isNotEmpty)
                _buildDetailRow(
                  languageService.tr('order_history_screen_reason'),
                  entry.reason,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedControlsDelegate extends SliverPersistentHeaderDelegate {
  _PinnedControlsDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: extent, child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedControlsDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}
