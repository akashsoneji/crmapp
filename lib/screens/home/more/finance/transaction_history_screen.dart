import 'package:crm_app/widgets/app_svg_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import '../../../../constants/text_styles.dart';
import '../../../../controllers/finance/transaction_history_controller.dart';
import '../../../../routes/app_pages.dart';
import '../../../../services/language_service.dart';
import '../../../../utils/app_picker_theme.dart';
import '../../../../widgets/custom_toast.dart';

enum _TxStatus { completed, pending, failed }

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String selectedAccount = 'All';
  String selectedTransactionType = 'All';
  String selectedTimePeriod = 'All Time';
  DateTime? customStartDate;
  DateTime? customEndDate;
  final controller = Get.put(TransactionHistoryController());

  late final LanguageService languageService;

  /// Keys of rows whose detail panel is open.
  final Set<String> _expandedKeys = <String>{};

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final List<String> transactionTypes = [
    'All',
    'Deposit',
    'Withdrawal',
    'Transfer',
  ];

  final List<String> timePeriods = [
    'All Time',
    'Today',
    'Last week',
    'This month',
    'Custom',
  ];

  /// Short labels so all five periods fit one row without scrolling.
  /// Filter values (keys) are unchanged.
  static const Map<String, String> _periodLabels = {
    'All Time': 'All',
    'Today': 'Today',
    'Last week': '7 Days',
    'This month': 'Month',
    'Custom': 'Custom',
  };

  @override
  void initState() {
    super.initState();
    languageService = Get.find<LanguageService>();
    controller.fetchUserTransactions(); // fetch on load
  }

  // ─── Filtering ────────────────────────────────────────────────────────────

  // Compute filtered transactions - must be called inside Obx
  List<Data> _computeFilteredTransactions(List<Data> allTransactions) {
    final filtered =
        allTransactions.where((transaction) {
          if (selectedAccount != 'All' &&
              (transaction.mt5AccountId ?? '') != selectedAccount) {
            return false;
          }

          if (selectedTransactionType != 'All' &&
              (transaction.transactionType?.toLowerCase() ?? '') !=
                  selectedTransactionType.toLowerCase()) {
            return false;
          }

          final transactionDate = _parseDate(transaction) ?? DateTime(1970);
          return _isTransactionInTimePeriod(transactionDate);
        }).toList();

    // Sort by newest first
    filtered.sort((a, b) {
      final aDate = _parseDate(a) ?? DateTime(1970);
      final bDate = _parseDate(b) ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  bool _isTransactionInTimePeriod(DateTime transactionDate) {
    final now = DateTime.now();

    switch (selectedTimePeriod) {
      case 'Today':
        return transactionDate.year == now.year &&
            transactionDate.month == now.month &&
            transactionDate.day == now.day;

      case 'Last week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return transactionDate.isAfter(weekAgo) &&
            transactionDate.isBefore(now.add(const Duration(days: 1)));

      case 'This month':
        return transactionDate.year == now.year &&
            transactionDate.month == now.month;

      case 'Custom':
        if (customStartDate == null || customEndDate == null) return true;
        return transactionDate.isAfter(
              customStartDate!.subtract(const Duration(days: 1)),
            ) &&
            transactionDate.isBefore(
              customEndDate!.add(const Duration(days: 1)),
            );

      default:
        return true;
    }
  }

  void _onTimePeriodSelected(String period) {
    setState(() {
      selectedTimePeriod = period;
      if (period != 'Custom') {
        customStartDate = null;
        customEndDate = null;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      selectedTimePeriod = 'All Time';
      selectedTransactionType = 'All';
      customStartDate = null;
      customEndDate = null;
    });
  }

  /// Universal back handler — works for every caller:
  ///   • Normal push (from More / settings, etc.)   → Navigator.canPop() is true → pop the screen.
  ///   • Stack wiped via offAllNamed (from Cregis) → fall back to TRADING so the
  ///     user lands on a meaningful screen instead of a black void.
  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Get.back();
      return;
    }
    Get.offAllNamed(Routes.TRADING);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // we route back manually via _handleBack()
      onPopInvoked: (didPop) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: AppSvgBackButton(
            onPressed: _handleBack,
            iconWidth: 30.w,
            iconHeight: 30.h,
          ),
          title: Text(
            languageService.tr('transaction_history'),
            style: AppTextStyles.screenTitle,
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterPanel(),
                  Expanded(child: _buildTransactionList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Filters (fixed, never scroll) ────────────────────────────────────────

  Widget _buildFilterPanel() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPeriodSegment(),
          SizedBox(height: 8.h),
          _buildTypeChips(),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child:
                selectedTimePeriod == 'Custom'
                    ? Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: _buildCustomDateRange(),
                    )
                    : const SizedBox(width: double.infinity),
          ),
          SizedBox(height: 10.h),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSegment() {
    return Container(
      height: 34.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: AppColors.chipSurface,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children:
            timePeriods.map((period) {
              return Expanded(
                child: _SegmentButton(
                  label: _periodLabels[period] ?? period,
                  icon:
                      period == 'Custom' ? Icons.calendar_month_rounded : null,
                  isSelected: period == selectedTimePeriod,
                  onTap: () => _onTimePeriodSelected(period),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTypeChips() {
    return Semantics(
      label: languageService.tr('transaction_history_transaction_type'),
      child: Row(
        children: [
          for (var i = 0; i < transactionTypes.length; i++) ...[
            if (i > 0) SizedBox(width: 6.w),
            Expanded(
              child: _TypeChip(
                label: transactionTypes[i],
                isSelected: transactionTypes[i] == selectedTransactionType,
                onTap:
                    () => setState(
                      () => selectedTransactionType = transactionTypes[i],
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomDateRange() {
    return Row(
      children: [
        Expanded(
          child: _DateField(
            label: 'From',
            value:
                customStartDate != null
                    ? _formatDate(customStartDate!)
                    : 'Select date',
            isSet: customStartDate != null,
            onTap: () => _showCustomDatePicker(true),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 14.r,
            color: AppColors.textGrey,
          ),
        ),
        Expanded(
          child: _DateField(
            label: 'To',
            value:
                customEndDate != null
                    ? _formatDate(customEndDate!)
                    : 'Select date',
            isSet: customEndDate != null,
            onTap: () => _showCustomDatePicker(false),
          ),
        ),
      ],
    );
  }

  // ─── List ─────────────────────────────────────────────────────────────────

  Widget _buildTransactionList() {
    return Obx(() {
      final allTransactions = controller.userTransactions.toList();
      final isBusy = controller.isLoading;

      if (isBusy && allTransactions.isEmpty) {
        return const _TransactionSkeleton();
      }

      final transactions = _computeFilteredTransactions(allTransactions);
      final groups = _groupByDay(transactions);

      return Stack(
        children: [
          RefreshIndicator(
            color: AppColors.controlActive,
            backgroundColor: AppColors.card,
            onRefresh: () => controller.fetchUserTransactions(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (transactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(
                      hasAnyTransactions: allTransactions.isNotEmpty,
                    ),
                  )
                else ...[
                  SliverList.builder(
                    itemCount: groups.length,
                    itemBuilder:
                        (_, index) => _buildDayGroup(
                          groups[index].key,
                          groups[index].value,
                          isBusy,
                        ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                ],
              ],
            ),
          ),
          // Thin progress line for background work (e.g. receipt download)
          // so the list stays visible instead of being replaced by a loader.
          if (isBusy)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.controlActive,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      );
    });
  }

  List<MapEntry<String, List<Data>>> _groupByDay(List<Data> transactions) {
    final groups = <String, List<Data>>{};
    for (final transaction in transactions) {
      groups
          .putIfAbsent(_groupLabel(_parseDate(transaction)), () => <Data>[])
          .add(transaction);
    }
    return groups.entries.toList();
  }

  /// One day = one rounded panel with divider-separated rows.
  Widget _buildDayGroup(String label, List<Data> items, bool isBusy) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 6.h),
            child: Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textGrey,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.card,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
              side: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 58.w,
                      color: AppColors.border.withValues(alpha: 0.3),
                    ),
                  _buildTransactionRow(items[i], isBusy),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Data transaction, bool isBusy) {
    final rowKey = _transactionKey(transaction);
    final isExpanded = _expandedKeys.contains(rowKey);
    final typeRaw = (transaction.transactionType ?? '').toLowerCase();
    final isDeposit = typeRaw.contains('deposit');
    final isTransfer = typeRaw.contains('transfer');
    final flowColor = isDeposit ? AppColors.successText : AppColors.errorText;
    final flowBackground = isDeposit ? AppColors.successBg : AppColors.errorBg;
    final typeLabel = _formatType(transaction.transactionType);
    final method = (transaction.paymentMethod ?? '').trim();
    final date = _parseDate(transaction);
    final subtitle = [
      if (date != null) _formatTime(date),
      if (method.isNotEmpty) method,
    ].join(' · ');

    return InkWell(
      onTap:
          () => setState(() {
            if (!_expandedKeys.remove(rowKey)) _expandedKeys.add(rowKey);
          }),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: flowBackground,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child:
                      isTransfer
                          ? Icon(
                            Icons.swap_horiz_rounded,
                            size: 18.r,
                            color: flowColor,
                          )
                          : SvgPicture.asset(
                            isDeposit
                                ? 'assets/svg/deshboard/money-recive.svg'
                                : 'assets/svg/deshboard/money-send.svg',
                            width: 16.r,
                            height: 16.r,
                            colorFilter: ColorFilter.mode(
                              flowColor,
                              BlendMode.srcIn,
                            ),
                          ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel.isEmpty ? 'Transaction' : typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textGrey,
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
                      _formatAmount(transaction, isDeposit),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: flowColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    _StatusPill(
                      status: _statusOf(transaction),
                      label: _formatType(transaction.status),
                    ),
                  ],
                ),
                SizedBox(width: 2.w),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18.r,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child:
                  isExpanded
                      ? _buildTransactionDetails(transaction, isBusy)
                      : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(Data transaction, bool isBusy) {
    final reference = (transaction.referenceNumber ?? '').trim();
    final transactionId = (transaction.transactionId ?? '').trim();
    final accountId = (transaction.mt5AccountId ?? '').trim();
    final accountType = _formatType(transaction.type);
    final method = (transaction.paymentMethod ?? '').trim();
    final status = _formatType(transaction.status);

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 4.h, 2.w, 4.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            _buildDetailRow(
              'Date & time',
              _formatDateTime(transaction.createdAt ?? ''),
            ),
            if (reference.isNotEmpty)
              _buildDetailRow('Reference', reference, copyable: true),
            if (transactionId.isNotEmpty)
              _buildDetailRow('Transaction ID', transactionId, copyable: true),
            if (accountId.isNotEmpty)
              _buildDetailRow(
                'Account',
                accountType.isEmpty ? accountId : '$accountType: $accountId',
              ),
            if (method.isNotEmpty) _buildDetailRow('Payment method', method),
            if (status.isNotEmpty) _buildDetailRow('Status', status),
            if (_canDownloadReceipt(transaction))
              Padding(
                padding: EdgeInsets.fromLTRB(0, 6.h, 8.w, 6.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 36.h,
                  child: OutlinedButton.icon(
                    onPressed:
                        isBusy
                            ? null
                            : () => controller.viewReceipt(transaction.id!),
                    icon: Icon(Icons.download_rounded, size: 16.r),
                    label: Text(
                      'Download receipt',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.controlActive,
                      side: BorderSide(
                        color: AppColors.controlActive.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = false}) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 32.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: AppColors.textGrey),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              tooltip: 'Copy $label',
              visualDensity: VisualDensity.compact,
              iconSize: 14.r,
              color: AppColors.textGrey,
              icon: const Icon(Icons.copy_rounded),
              onPressed: () => _copyToClipboard(label, value),
            )
          else
            SizedBox(width: 8.w),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool hasAnyTransactions}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: AppColors.iconBgPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasAnyTransactions
                  ? Icons.filter_alt_off_rounded
                  : Icons.receipt_long_rounded,
              size: 26.r,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'No transactions found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            hasAnyTransactions
                ? 'Nothing matches these filters. Try another period or type.'
                : 'Your deposits, withdrawals and transfers will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
          ),
          if (hasAnyTransactions) ...[
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: Icon(Icons.refresh_rounded, size: 16.r),
              label: Text(
                'Clear filters',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.controlActive,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _transactionKey(Data transaction) =>
      transaction.id ??
      transaction.referenceNumber ??
      '${transaction.createdAt}-${transaction.amount}';

  DateTime? _parseDate(Data transaction) =>
      DateTime.tryParse(transaction.createdAt ?? '')?.toLocal();

  _TxStatus _statusOf(Data transaction) {
    final status = (transaction.status ?? '').trim().toLowerCase();
    if (const {'approved', 'success', 'completed'}.contains(status)) {
      return _TxStatus.completed;
    }
    if (status == 'rejected' || status == 'failed') return _TxStatus.failed;
    return _TxStatus.pending;
  }

  /// Receipt is available for any transaction with an id that is not a withdrawal.
  bool _canDownloadReceipt(Data transaction) {
    return (transaction.id ?? '').isNotEmpty &&
        !(transaction.amount?.trim().startsWith('-') ?? false) &&
        (transaction.transactionType?.toLowerCase() ?? '') != 'withdrawal';
  }

  String _formatAmount(Data transaction, bool isDeposit) {
    final amount = (transaction.amount ?? '').trim();
    if (amount.isEmpty) return '—';
    if (isDeposit || amount.startsWith('-')) return amount;
    return '-$amount';
  }

  String _formatType(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final v = raw.toLowerCase();
    if (v == 'mt5') return 'MT5';
    if (v == 'wallet') return 'Wallet';
    return v
        .split('_')
        .join(' ')
        .split(' ')
        .map(
          (w) =>
              w.isEmpty
                  ? w
                  : w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''),
        )
        .join(' ');
  }

  String _groupLabel(DateTime? date) {
    if (date == null) return 'Unknown date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (date.year == now.year) return '${date.day} ${_months[date.month - 1]}';
    return _formatDate(date);
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour24 = date.hour;
    final hour = hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDateTime(String dateStr) {
    final date = DateTime.tryParse(dateStr)?.toLocal();
    if (date == null) return dateStr.isEmpty ? '—' : dateStr;
    return '${_formatDate(date)}, ${_formatTime(date)}';
  }

  Future<void> _copyToClipboard(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    CustomToastService.showSuccess(message: '$label copied');
  }

  void _showCustomDatePicker(bool isStartDate) async {
    final DateTime? picked = await AppPickerTheme.showAppDatePicker(
      context,
      initialDate:
          isStartDate
              ? (customStartDate ??
                  DateTime.now().subtract(const Duration(days: 30)))
              : (customEndDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          customStartDate = picked;
          // Ensure end date is not before start date
          if (customEndDate != null && customEndDate!.isBefore(picked)) {
            customEndDate = null;
          }
        } else {
          customEndDate = picked;
          // Ensure start date is not after end date
          if (customStartDate != null && customStartDate!.isAfter(picked)) {
            customStartDate = null;
          }
        }
      });
    }
  }
}

// ─── Private widgets ──────────────────────────────────────────────────────────

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? AppColors.textPrimary : AppColors.textGrey;

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12.r, color: foreground),
                  SizedBox(width: 3.w),
                ],
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color:
            isSelected ? AppColors.selectedChipBackground : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color:
                isSelected
                    ? AppColors.selectedChipBackground
                    : AppColors.border.withValues(alpha: 0.7),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 30.h,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isSelected
                              ? AppColors.selectedChipForeground
                              : AppColors.textGrey,
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

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final bool isSet;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.isSet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(
          color:
              isSet
                  ? AppColors.controlActive.withValues(alpha: 0.5)
                  : AppColors.border.withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          child: Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 14.r,
                color: isSet ? AppColors.controlActive : AppColors.textGrey,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color:
                            isSet ? AppColors.textPrimary : AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _TxStatus status;
  final String label;

  const _StatusPill({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final (Color foreground, Color background) = switch (status) {
      _TxStatus.completed => (AppColors.successText, AppColors.successBg),
      _TxStatus.pending => (AppColors.warningText, AppColors.warningBg),
      _TxStatus.failed => (AppColors.errorText, AppColors.errorBg),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.isEmpty ? 'Pending' : label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

/// Placeholder that mirrors the final layout (summary + grouped rows) while loading.
class _TransactionSkeleton extends StatefulWidget {
  const _TransactionSkeleton();

  @override
  State<_TransactionSkeleton> createState() => _TransactionSkeletonState();
}

class _TransactionSkeletonState extends State<_TransactionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.neutralTrack,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  BoxDecoration get _panel => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(14.r),
    border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
  );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulse,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _bar(56.w, 9.h),
            ),
          ),
          Container(
            decoration: _panel,
            child: Column(
              children: [
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 11.h,
                    ),
                    child: Row(
                      children: [
                        _bar(36.r, 36.r, radius: 10.r),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _bar(100.w, 11.h),
                              SizedBox(height: 6.h),
                              _bar(64.w, 9.h),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _bar(54.w, 11.h),
                            SizedBox(height: 6.h),
                            _bar(40.w, 9.h),
                          ],
                        ),
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
