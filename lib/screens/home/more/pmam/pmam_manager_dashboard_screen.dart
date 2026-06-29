import 'package:crm_app/widgets/app_svg_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/pmam/pmam_controller.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:fl_chart/fl_chart.dart';

class PmamManagerDashboardScreen extends StatefulWidget {
  const PmamManagerDashboardScreen({super.key});

  @override
  State<PmamManagerDashboardScreen> createState() =>
      _PmamManagerDashboardScreenState();
}

class _PmamManagerDashboardScreenState extends State<PmamManagerDashboardScreen> {
  late final PmamController _ctrl;
  String _selectedChartTab = 'Equity';

  @override
  void initState() {
    if (Get.isRegistered<PmamController>()) {
      _ctrl = Get.find<PmamController>();
    } else {
      _ctrl = Get.put(PmamController());
    }
    _ctrl.loadManagerDashboard();
    super.initState();
  }

  String _fmt(dynamic val) {
    if (val == null) return '\$0';
    final d = double.tryParse(val.toString()) ?? 0.0;
    if (d.abs() >= 1000000) return '\$${(d / 1000000).toStringAsFixed(1)}M';
    if (d.abs() >= 1000) return '\$${(d / 1000).toStringAsFixed(1)}K';
    return '\$${d.toStringAsFixed(2)}';
  }

  String _fmtNum(dynamic val) {
    if (val == null) return '0';
    final d = double.tryParse(val.toString()) ?? 0.0;
    if (d.abs() >= 1000000) return '${(d / 1000000).toStringAsFixed(1)}M';
    if (d.abs() >= 1000) return '${(d / 1000).toStringAsFixed(1)}K';
    if (d % 1 == 0) return d.toInt().toString();
    return d.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('MANAGER DASHBOARD', style: AppTextStyles.heading.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        centerTitle: true,
        leading: AppSvgBackButton(
          onPressed: () => Get.back(closeOverlays: true),
          iconWidth: 30.w,
          iconHeight: 30.h,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22.sp),
            onPressed: _ctrl.loadManagerDashboard,
          ),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) {
          return Center(child: CommonLoadingWidget(size: 40, color: AppColors.primary));
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _ctrl.loadManagerDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopFilters(),
                SizedBox(height: 16.h),
                _buildHeroCards(),
                SizedBox(height: 16.h),
                _buildPerformanceChart(),
                SizedBox(height: 16.h),
                _buildInvestorHealth(),
                SizedBox(height: 16.h),
                _buildPlanPerformance(),
                SizedBox(height: 16.h),
                _buildPayouts(),
                SizedBox(height: 16.h),
                _buildRecentTrades(),
                SizedBox(height: 80.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Today', '7d', '30d', '90d', '1y', 'all'].map((range) {
          final isSelected = _ctrl.dashboardRange.value == range;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(range.toUpperCase()),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  _ctrl.dashboardRange.value = range;
                  _ctrl.loadManagerDashboard();
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.card,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.whiteColor : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroCards() {
    final hero = _ctrl.heroStats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.35,
      children: [
        _HeroCard(
          title: 'Total AUM',
          value: _fmt(hero['aum']?['current']),
          delta: hero['aum']?['delta_pct']?.toString(),
          icon: Icons.account_balance_wallet_outlined,
          sparklineData: hero['aum']?['series']?['data'],
        ),
        _HeroCard(
          title: 'Active Investors',
          value: _fmtNum(hero['investors']?['current']),
          delta: hero['investors']?['delta']?.toString(),
          icon: Icons.people_outline,
          sparklineData: hero['investors']?['series']?['data'],
          deltaIsAbsolute: true,
        ),
        _HeroCard(
          title: 'Commission Earned',
          value: _fmt(hero['earnings']?['current']),
          delta: hero['earnings']?['delta_pct']?.toString(),
          icon: Icons.payments_outlined,
          sparklineData: hero['earnings']?['series']?['data'],
        ),
        _HeroCard(
          title: 'ROI (Window)',
          value: '${_fmtNum(hero['roi']?['current_pct'])}%',
          delta: hero['roi']?['delta_pct']?.toString(),
          icon: Icons.trending_up,
          sparklineData: hero['roi']?['series']?['data'],
        ),
      ],
    );
  }

  Widget _buildPerformanceChart() {
    final chartData = _ctrl.mainChartData;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Equity', 'AUM', 'Net P&L'].map((tab) {
                final isSelected = _selectedChartTab == tab;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChartTab = tab;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 12.w),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 200.h,
            child: _buildLineChart(chartData),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(Map<dynamic, dynamic> chartData) {
    // Determine which data array to use based on selected tab
    String dataKey = 'equity';
    if (_selectedChartTab == 'AUM') dataKey = 'aum';
    if (_selectedChartTab == 'Net P&L') dataKey = 'pnl';
    
    final series = chartData[dataKey]?['series'];
    if (series == null || series['data'] == null || (series['data'] as List).isEmpty) {
      return Center(child: Text('No data available for $_selectedChartTab', style: TextStyle(color: AppColors.textGrey)));
    }

    final rawData = series['data'] as List;
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < rawData.length; i++) {
      final y = double.tryParse(rawData[i].toString()) ?? 0.0;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      spots.add(FlSpot(i.toDouble(), y));
    }
    
    if (spots.isEmpty) return const SizedBox();
    
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY - (maxY - minY) * 0.2,
        maxY: maxY + (maxY - minY) * 0.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorHealth() {
    final health = _ctrl.investorHealth;
    final active = int.tryParse(health['active']?.toString() ?? '0') ?? 0;
    final pending = int.tryParse(health['pending']?.toString() ?? '0') ?? 0;
    final inactive = int.tryParse(health['inactive']?.toString() ?? '0') ?? 0;
    final total = active + pending + inactive;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investor Health',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              SizedBox(
                width: 100.w,
                height: 100.w,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30.r,
                    sections: total == 0 ? [
                      PieChartSectionData(
                        color: AppColors.textGrey.withOpacity(0.2),
                        value: 1,
                        title: '',
                        radius: 12.r,
                      )
                    ] : [
                      PieChartSectionData(
                        color: AppColors.green,
                        value: active.toDouble(),
                        title: '',
                        radius: 12.r,
                      ),
                      PieChartSectionData(
                        color: AppColors.warning,
                        value: pending.toDouble(),
                        title: '',
                        radius: 12.r,
                      ),
                      PieChartSectionData(
                        color: AppColors.textGrey,
                        value: inactive.toDouble(),
                        title: '',
                        radius: 12.r,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  children: [
                    _HealthRow(color: AppColors.green, label: 'Active', value: active.toString()),
                    SizedBox(height: 8.h),
                    _HealthRow(color: AppColors.warning, label: 'Pending', value: pending.toString()),
                    SizedBox(height: 8.h),
                    _HealthRow(color: AppColors.textGrey, label: 'Inactive', value: inactive.toString()),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'New (Period)', value: _fmtNum(health['new_this_period'])),
              _StatItem(label: 'Churned', value: _fmtNum(health['churned'])),
              _StatItem(label: 'Avg Age', value: '${_fmtNum(health['avg_age_days'])}d'),
              _StatItem(label: 'Retention', value: '${_fmtNum(health['retention_rate'])}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanPerformance() {
    final plans = _ctrl.managerPlans;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plan Performance',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(
                  AppPages.PMAM_MANAGER_PORTAL,
                  arguments: {'initialTab': 1},
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (plans.isEmpty)
            Text('No plans available', style: TextStyle(color: AppColors.textGrey))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plans.length > 3 ? 3 : plans.length,
              separatorBuilder: (_, __) => Divider(color: AppColors.border.withOpacity(0.1)),
              itemBuilder: (context, i) {
                final p = plans[i];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['plan_name'] ?? 'Unnamed',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${p['active_investors'] ?? 0} Investors',
                              style: TextStyle(fontSize: 11.sp, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _fmt(p['total_locked_aum']),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'AUM',
                            style: TextStyle(fontSize: 11.sp, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPayouts() {
    final payouts = _ctrl.payoutsData;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payouts',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earned (30d)',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _fmt(payouts['earned_period']),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _fmt(payouts['pending']),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrades() {
    final trades = _ctrl.recentDashboardTrades;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Trades',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (trades.isEmpty)
            Text('No recent trades', style: TextStyle(color: AppColors.textGrey))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trades.length > 5 ? 5 : trades.length,
              separatorBuilder: (_, __) => Divider(color: AppColors.border.withOpacity(0.1)),
              itemBuilder: (context, i) {
                final t = trades[i];
                final pnl = double.tryParse(t['profit']?.toString() ?? '0') ?? 0.0;
                final isProfit = pnl >= 0;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: isProfit ? AppColors.green.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14.sp,
                          color: isProfit ? AppColors.green : AppColors.error,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['symbol'] ?? 'UNKNOWN',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              t['close_time']?.toString().split(' ').first ?? '-',
                              style: TextStyle(fontSize: 11.sp, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _fmt(pnl),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isProfit ? AppColors.green : AppColors.error,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Vol: ${t['volume'] ?? 0}',
                            style: TextStyle(fontSize: 11.sp, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _HealthRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(fontSize: 13.sp, color: AppColors.textGrey)),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String value;
  final String? delta;
  final IconData icon;
  final dynamic sparklineData;
  final bool deltaIsAbsolute;

  const _HeroCard({
    required this.title,
    required this.value,
    this.delta,
    required this.icon,
    this.sparklineData,
    this.deltaIsAbsolute = false,
  });

  @override
  Widget build(BuildContext context) {
    double d = double.tryParse(delta ?? '0') ?? 0.0;
    bool isPositive = d >= 0;
    Color dColor = isPositive ? AppColors.green : AppColors.error;
    String dText = isPositive ? '+${d.toStringAsFixed(1)}' : d.toStringAsFixed(1);
    if (!deltaIsAbsolute) dText += '%';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey, fontWeight: FontWeight.w500),
              ),
              Icon(icon, size: 16.sp, color: AppColors.primary.withOpacity(0.6)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacer(),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: dColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  dText,
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: dColor),
                ),
              ),
              if (sparklineData != null && sparklineData is List && (sparklineData as List).isNotEmpty)
                Expanded(
                  child: SizedBox(
                    height: 20.h,
                    child: _MiniSparkline(data: sparklineData as List, color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List data;
  final Color color;
  const _MiniSparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    
    double minY = double.infinity;
    double maxY = -double.infinity;
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final y = double.tryParse(data[i].toString()) ?? 0.0;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      spots.add(FlSpot(i.toDouble(), y));
    }
    
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
