import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/controllers/ib_controller.dart';
import 'package:pipze/models/ib_models.dart';
import 'package:pipze/widgets/common_loading_widget.dart';

class IBClientsScreen extends StatefulWidget {
  const IBClientsScreen({super.key});

  @override
  State<IBClientsScreen> createState() => _IBClientsScreenState();
}

class _IBClientsScreenState extends State<IBClientsScreen>
    with SingleTickerProviderStateMixin {
  late IBController ibController;
  late TabController _tabController;
  String _searchQuery = '';
  List<IBClient> _ibHierarchy = [];

  @override
  void initState() {
    super.initState();
    ibController = Get.find<IBController>();
    _tabController = TabController(length: 3, vsync: this);
    // Reset hierarchy and search when screen initializes
    _ibHierarchy.clear();
    _searchQuery = '';
    // Reset to first tab
    _tabController.index = 0;
    _loadClientsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClientsData() async {
    await ibController.loadIBData(subIbId: ibController.selectedSubIBId);
  }

  Future<void> _onRefresh() async {
    await _loadClientsData();
  }

  void _onSubIBClicked(IBClient subIB) {
    if (subIB.id == null) return;

    setState(() {
      if (_ibHierarchy.isEmpty) {
        _ibHierarchy = [subIB];
      } else {
        _ibHierarchy.add(subIB);
      }
    });

    ibController.selectedSubIBId = subIB.id;
    ibController.loadIBData(subIbId: subIB.id);
  }

  void _backToPrevious() {
    if (_ibHierarchy.isNotEmpty) {
      setState(() {
        _ibHierarchy.removeLast();
      });

      final parentId = _ibHierarchy.isNotEmpty ? _ibHierarchy.last.id : null;
      ibController.selectedSubIBId = parentId;
      ibController.loadIBData(subIbId: parentId);
    }
  }

  void _backToMaster() {
    setState(() {
      _ibHierarchy.clear();
    });
    ibController.selectedSubIBId = null;
    ibController.loadIBData(subIbId: null);
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'N/A';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name[0].toUpperCase();
  }

  List<IBClient> _getFilteredClients() {
    final allClients = ibController.ibClients.toList();
    if (allClients.isEmpty) return [];

    final regularClients =
        allClients
            .where(
              (client) =>
                  !(client.ibType == 'sub-ib' &&
                      client.isSubIbApproved == true),
            )
            .toList();

    if (_searchQuery.isEmpty) return regularClients;
    return regularClients
        .where(
          (client) =>
              (client.name?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              (client.email?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  List<IBClient> _getFilteredSubIBs() {
    final allSubIBs = ibController.ibSubIBs.toList();
    if (allSubIBs.isEmpty) return [];

    if (_searchQuery.isEmpty) return allSubIBs;
    return allSubIBs
        .where(
          (subIB) =>
              (subIB.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false) ||
              (subIB.email?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  List<IBTradeHistory> _getFilteredTradeHistory() {
    final allTradeHistory = ibController.ibTradeHistory.toList();
    if (allTradeHistory.isEmpty) return [];

    if (_searchQuery.isEmpty) return allTradeHistory;
    return allTradeHistory
        .where(
          (trade) =>
              (trade.clientName?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              (trade.clientEmail?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              (trade.symbol?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        title: Text(
          'IB Clients',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Clients'),
            Tab(text: 'Sub-IBs'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        backgroundColor: Colors.white,
        color: AppColors.primary,
        child: GetBuilder<IBController>(
          id: 'ib_clients',
          builder: (controller) {
            return Column(
              children: [
                // Breadcrumb Navigation
                if (_ibHierarchy.isNotEmpty) ...[_buildBreadcrumb()],

                // Search Bar
                _buildSearchBar(),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildClientsTab(),
                      _buildSubIBsTab(),
                      _buildTransactionHistoryTab(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _backToMaster,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: AppColors.primary, size: 16.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Master IB',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ..._ibHierarchy.asMap().entries.map((entry) {
            return Row(
              children: [
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right,
                  size: 16.sp,
                  color: AppColors.textGrey,
                ),
                SizedBox(width: 8.w),
                Text(
                  entry.value.name ?? 'Sub-IB',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            );
          }),
          if (_ibHierarchy.isNotEmpty) ...[
            SizedBox(width: 8.w),
            InkWell(
              onTap: _backToPrevious,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.textGrey),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            size: 20.sp,
            color: AppColors.textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildClientsTab() {
    if (ibController.isLoading.value && ibController.ibClients.isEmpty) {
      return Center(
        child: CommonLoadingWidget(
          message: 'Loading clients...',
          size: 50.0,
          color: AppColors.primary,
        ),
      );
    }

    final filteredClients = _getFilteredClients();
    final displayClients = filteredClients.take(50).toList();

    if (displayClients.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            children: [
              Icon(
                Icons.person_outline,
                size: 64.sp,
                color: AppColors.textGrey,
              ),
              SizedBox(height: 16.h),
              Text(
                'No clients found',
                style: TextStyle(fontSize: 16.sp, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: displayClients.length,
      itemBuilder: (context, index) {
        final client = displayClients[index];
        return _buildClientCard(client);
      },
    );
  }

  Widget _buildSubIBsTab() {
    if (ibController.isLoading.value && ibController.ibSubIBs.isEmpty) {
      return Center(
        child: CommonLoadingWidget(
          message: 'Loading sub-IBs...',
          size: 50.0,
          color: AppColors.primary,
        ),
      );
    }

    final filteredSubIBs = _getFilteredSubIBs();
    final displaySubIBs = filteredSubIBs.take(50).toList();

    if (displaySubIBs.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64.sp,
                color: AppColors.textGrey,
              ),
              SizedBox(height: 16.h),
              Text(
                'No Sub-IBs found',
                style: TextStyle(fontSize: 16.sp, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: displaySubIBs.length,
      itemBuilder: (context, index) {
        final subIB = displaySubIBs[index];
        return _buildSubIBCard(subIB);
      },
    );
  }

  Widget _buildTransactionHistoryTab() {
    if (ibController.isHistoryLoading.value &&
        ibController.ibTradeHistory.isEmpty) {
      return Center(
        child: CommonLoadingWidget(
          message: 'Loading trade history...',
          size: 50.0,
          color: AppColors.primary,
        ),
      );
    }

    final filteredHistory = _getFilteredTradeHistory();
    final displayHistory = filteredHistory.take(100).toList();

    if (displayHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            children: [
              Icon(Icons.history, size: 64.sp, color: AppColors.textGrey),
              SizedBox(height: 16.h),
              Text(
                'No trade history found',
                style: TextStyle(fontSize: 16.sp, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: displayHistory.length,
      itemBuilder: (context, index) {
        final trade = displayHistory[index];
        return _buildTradeHistoryCard(trade);
      },
    );
  }

  Widget _buildClientCard(IBClient client) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(client.name),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name ?? 'N/A',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  client.email ?? '',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
                ),
                if (client.accountNumber != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Account: ${client.accountNumber}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (client.deposit != null || client.totalDeposit != null)
                Text(
                  '\$${(client.deposit ?? client.totalDeposit ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (client.rebate != null || client.totalRebate != null)
                Text(
                  'Rebate: \$${(client.rebate ?? client.totalRebate ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textGrey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubIBCard(IBClient subIB) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onSubIBClicked(subIB),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(subIB.name),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subIB.name ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subIB.email ?? '',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 12.sp,
                        color: AppColors.textGrey,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${subIB.totalClients ?? 0} Clients',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(Icons.star, size: 12.sp, color: AppColors.textGrey),
                      SizedBox(width: 4.w),
                      Text(
                        '${subIB.totalSubIBs ?? 0} Sub IBs',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeHistoryCard(IBTradeHistory trade) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trade.clientName ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      trade.symbol ?? '',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (trade.type == 'Buy' ? Colors.green : Colors.red)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  trade.type ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: trade.type == 'Buy' ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTradeDetail('Volume', '${trade.volume ?? 0}'),
              _buildTradeDetail('Commission', '\$${trade.commission ?? 0.0}'),
              _buildTradeDetail('Profit', '\$${trade.profit ?? 0.0}'),
            ],
          ),
          if (trade.closeTime != null) ...[
            SizedBox(height: 4.h),
            Text(
              'Closed: ${trade.closeTime}',
              style: TextStyle(fontSize: 11.sp, color: AppColors.textGrey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTradeDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: AppColors.textGrey),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
