import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/pmam/pmam_controller.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:crm_app/models/pmam_model.dart';

class PmamInvestorPortalScreen extends StatefulWidget {
  const PmamInvestorPortalScreen({super.key});

  @override
  State<PmamInvestorPortalScreen> createState() =>
      _PmamInvestorPortalScreenState();
}

class _PmamInvestorPortalScreenState extends State<PmamInvestorPortalScreen>
    with SingleTickerProviderStateMixin {
  late final PmamController _ctrl;
  late final TabController _tabCtrl;

  String _searchQuery = '';
  String _myFilter = 'all';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (Get.isRegistered<PmamController>()) {
      _ctrl = Get.find<PmamController>();
    } else {
      _ctrl = Get.put(PmamController());
    }
    // Load managers via datatable API + my investments
    _ctrl.loadManagersDataTable();
    _ctrl.loadInvestorPortal();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _ctrl.loadManagersDataTable(search: value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
        ),

        title: Text('Investor Portal', style: AppTextStyles.heading),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(46.h),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(fontSize: 14.sp),
              tabs: const [
                Tab(text: 'Fund Managers'),
                Tab(text: 'My Investments'),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value && _ctrl.myInvestments.isEmpty) {
          return Center(
            child: CommonLoadingWidget(size: 40, color: AppColors.primary),
          );
        }
        return TabBarView(
          controller: _tabCtrl,
          children: [_buildFundManagersTab(), _buildMyInvestmentsTab()],
        );
      }),
    );
  }

  Widget _buildFundManagersTab() {
    return Column(
      children: [
        SizedBox(height: 12.h),
        // Search bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _onSearchChanged(v);
              },
              style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search managers by name or code…',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textGrey,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textGrey,
                  size: 20.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 13.h,
                  horizontal: 16.w,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // Content
        Expanded(
          child: Obx(() {
            if (_ctrl.isManagersLoading.value) {
              return Center(
                child: CommonLoadingWidget(size: 36, color: AppColors.primary),
              );
            }
            final managers = _ctrl.managersList;
            if (managers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      size: 48.sp,
                      color: AppColors.textGrey.withOpacity(0.4),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No fund managers available'
                          : 'No results for "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh:
                  () => _ctrl.loadManagersDataTable(search: _searchQuery),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: managers.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, i) {
                  // Map model properties
                  final PmamManager manager = managers[i];
                  final name = manager.managerName ?? 'Unknown';
                  final code = manager.managerCode;
                  final initials =
                      name
                          .split(' ')
                          .take(2)
                          .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                          .join();
                  final profit = manager.profitPercentage;
                  final profitIsPos = profit >= 0;
                  final totalAum = manager.totalAum.toStringAsFixed(0);
                  final investorsCount = manager.totalInvestors;
                  final avgCommission = manager.avgCommission.toStringAsFixed(
                    0,
                  );
                  final memberSince = manager.memberSince ?? '';

                  return GestureDetector(
                    onTap:
                        () => Get.toNamed(
                          AppPages.PMAM_MANAGER_DETAIL,
                          arguments: manager,
                        ),
                    child: Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 22.r,
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.15,
                                ),
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (code.isNotEmpty)
                                      Text(
                                        code,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if (memberSince.isNotEmpty)
                                      Text(
                                        'Since $memberSince',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textGrey,
                                size: 24.sp,
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          // Stats chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _PerfChip(
                                  label: 'Profit %',
                                  value:
                                      '${profitIsPos ? '+' : ''}${profit.toStringAsFixed(2)}%',
                                  color:
                                      profitIsPos
                                          ? AppColors.green
                                          : AppColors.red,
                                ),
                                SizedBox(width: 8.w),
                                _PerfChip(label: 'AUM', value: '\$$totalAum'),
                                SizedBox(width: 8.w),
                                _PerfChip(
                                  label: 'Investors',
                                  value: '$investorsCount',
                                ),
                                SizedBox(width: 8.w),
                                _PerfChip(
                                  label: 'Commission',
                                  value: '$avgCommission%',
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMyInvestmentsTab() {
    final all = _ctrl.myInvestments;

    double totalInvested = 0, totalPnl = 0, netBalance = 0;
    int activePlans = 0;
    for (final inv in all) {
      totalInvested +=
          double.tryParse(
            (inv['invested_amount'] ?? inv['amount'] ?? 0).toString(),
          ) ??
          0;
      totalPnl +=
          double.tryParse((inv['pnl'] ?? inv['profit'] ?? 0).toString()) ?? 0;
      netBalance +=
          double.tryParse(
            (inv['net_balance'] ?? inv['balance'] ?? 0).toString(),
          ) ??
          0;
      if ((inv['status'] ?? '') == 'active') activePlans++;
    }

    final filtered =
        _myFilter == 'all'
            ? all
            : all.where((i) => i['status'] == _myFilter).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),
          // Summary stats
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SummaryChip(
                  label: 'Total Invested',
                  value: '\$${totalInvested.toStringAsFixed(2)}',
                ),
                SizedBox(width: 10.w),
                _SummaryChip(
                  label: 'Total P&L',
                  value:
                      '${totalPnl >= 0 ? '+' : ''}\$${totalPnl.toStringAsFixed(2)}',
                  valueColor: totalPnl >= 0 ? AppColors.green : AppColors.red,
                ),
                SizedBox(width: 10.w),
                _SummaryChip(
                  label: 'Net Balance',
                  value: '\$${netBalance.toStringAsFixed(2)}',
                ),
                SizedBox(width: 10.w),
                _SummaryChip(
                  label: 'Active Plans',
                  value: '$activePlans',
                  valueColor: AppColors.primary,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Filter chips
          Row(
            children: [
              _SmallFilterChip(
                label: 'All',
                selected: _myFilter == 'all',
                onTap: () => setState(() => _myFilter = 'all'),
              ),
              SizedBox(width: 8.w),
              _SmallFilterChip(
                label:
                    'Active (${all.where((i) => i['status'] == 'active').length})',
                selected: _myFilter == 'active',
                onTap: () => setState(() => _myFilter = 'active'),
              ),
              SizedBox(width: 8.w),
              _SmallFilterChip(
                label:
                    'Inactive (${all.where((i) => i['status'] != 'active').length})',
                selected: _myFilter == 'inactive',
                onTap: () => setState(() => _myFilter = 'inactive'),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          if (filtered.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: Center(
                child: Text(
                  'No investments yet.\nBrowse Fund Managers to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, i) {
                final inv = filtered[i];
                final status = (inv['status'] ?? '').toString();
                final pnl =
                    double.tryParse(
                      (inv['pnl'] ?? inv['profit'] ?? 0).toString(),
                    ) ??
                    0;
                final statusColor =
                    status == 'active' ? AppColors.green : AppColors.textGrey;
                return Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inv['plan_name'] ??
                                      inv['plan']?['plan_name'] ??
                                      'Unnamed Plan',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Manager: ${inv['manager_name'] ?? inv['manager']?['name'] ?? '-'}  •  ${inv['commission_percentage'] ?? 0}% commission',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              status == 'active' ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      _InvestmentInfoRow(
                        'Account',
                        inv['investor_account_number'] ?? '-',
                      ),
                      _InvestmentInfoRow(
                        'Invested',
                        '\$${inv['invested_amount'] ?? inv['amount'] ?? 0}',
                      ),
                      _InvestmentInfoRow(
                        'Total P&L',
                        '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                        valueColor: pnl >= 0 ? AppColors.green : AppColors.red,
                      ),
                      _InvestmentInfoRow(
                        'Net Balance',
                        '\$${inv['net_balance'] ?? 0}',
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                              ),
                              child: Text(
                                'View P&L Trades',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (status == 'active') ...[
                            SizedBox(width: 8.w),
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    () => _ctrl.unsubscribe(
                                      inv['id'] ?? inv['investor_id'] ?? 0,
                                    ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: AppColors.red.withOpacity(0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                ),
                                child: Text(
                                  'Unsubscribe',
                                  style: TextStyle(
                                    color: AppColors.red,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}

class _PerfChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _PerfChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.tradeBackgroundCenterColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9.sp, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryChip({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _SmallFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SmallFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

class _InvestmentInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InvestmentInfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
