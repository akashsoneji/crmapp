import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/controllers/ib_controller.dart';
import 'package:pipze/controllers/auth_controller.dart';
import 'package:pipze/models/ib_models.dart';
import 'package:pipze/widgets/common_loading_widget.dart';

class MyClientsScreen extends StatefulWidget {
  const MyClientsScreen({super.key});

  @override
  State<MyClientsScreen> createState() => _MyClientsScreenState();
}

class _MyClientsScreenState extends State<MyClientsScreen> {
  int _selectedTabIndex = 0; // 0: Client List, 1: IB List, 2: Trade History
  String _searchQuery = '';
  IBClient? _selectedSubIB;
  Map<int, bool> _expandedItems = {}; // Track expanded state for each item
  int _tradeHistoryDisplayLimit = 10; // Show 10 items initially
  bool _isLoadingMoreTrades = false;
  late IBController ibController;
  late AuthController authController;

  @override
  void initState() {
    super.initState();
    // Get or create IBController
    if (Get.isRegistered<IBController>()) {
      ibController = Get.find<IBController>();
    } else {
      ibController = Get.put(IBController());
    }
    authController = Get.find<AuthController>();
    // Load all data on screen load
    _loadMyClientsData();
  }

  Future<void> _loadMyClientsData({int? subIbId}) async {
    setState(() {
      _expandedItems.clear();
      _tradeHistoryDisplayLimit = 10; // Reset to 10 when loading new data
      _isLoadingMoreTrades = false;
    });

    // Update GetBuilder to show loading state
    ibController.update();

    await ibController.loadMyClientsData(subIbId: subIbId);

    if (mounted) {
      // First, show first 10 items immediately
      setState(() {
        final allTrades = ibController.ibTradeHistory;
        if (allTrades.length > 10) {
          _tradeHistoryDisplayLimit = 10; // Show only first 10
        } else {
          _tradeHistoryDisplayLimit =
              allTrades.length; // Show all if less than 10
        }
      });
      ibController.update(); // Update GetBuilder to show first 10 items

      // Then load remaining items in background
      _loadMoreTradesInBackground();
    }
  }

  Future<void> _loadMoreTradesInBackground() async {
    if (_isLoadingMoreTrades) return;

    final allTrades = ibController.ibTradeHistory;

    // If we already have all items displayed, no need to load more
    if (allTrades.length <= _tradeHistoryDisplayLimit) {
      return;
    }

    setState(() {
      _isLoadingMoreTrades = true;
    });

    // Wait a bit to ensure first 10 items are rendered
    await Future.delayed(const Duration(milliseconds: 800));

    // Now expand to show all remaining trades
    if (mounted) {
      setState(() {
        _tradeHistoryDisplayLimit = allTrades.length;
        _isLoadingMoreTrades = false;
      });
      ibController.update(); // Update GetBuilder to show all items
    }
  }

  void _onSubIBClicked(IBClient subIB) {
    setState(() {
      _selectedSubIB = subIB;
      _expandedItems.clear();
    });
    // Update GetBuilder immediately to show loading state
    ibController.update();
    _loadMyClientsData(subIbId: subIB.id);
  }

  void _backToMasterIB() {
    setState(() {
      _selectedSubIB = null;
      _expandedItems.clear();
    });
    _loadMyClientsData();
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'N/A';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  List<IBClient> _getFilteredClients() {
    final clients = ibController.ibClients;
    if (clients.isEmpty) return [];
    if (_searchQuery.isEmpty) return clients;
    return clients
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
    final subIBs = ibController.ibSubIBs;
    if (subIBs.isEmpty) return [];
    if (_searchQuery.isEmpty) return subIBs;
    return subIBs
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
    final allTradeHistory = ibController.ibTradeHistory;
    if (allTradeHistory.isEmpty) return [];

    List<IBTradeHistory> filtered;

    if (_searchQuery.isEmpty) {
      filtered = allTradeHistory;
    } else {
      filtered =
          allTradeHistory
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

    // Limit displayed items (for performance)
    // If search is active, show all filtered results
    if (_searchQuery.isEmpty && filtered.length > _tradeHistoryDisplayLimit) {
      return filtered.take(_tradeHistoryDisplayLimit).toList();
    }
    return filtered;
  }

  void _toggleExpand(int index) {
    setState(() {
      _expandedItems[index] = !(_expandedItems[index] ?? false);
    });
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
          'My Client',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GetBuilder<IBController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return Center(
              child: CommonLoadingWidget(
                message: 'Loading data...',
                size: 50.0,
                color: AppColors.primary,
              ),
            );
          }

          final stats = controller.ibStats.value;
          final userFullName = authController.userFullName ?? 'User';

          // Ensure we have data before rendering
          if (stats == null && !controller.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48.sp,
                    color: AppColors.textGrey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No data available',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Master IB Button or Selected Sub-IB Button
                if (_selectedSubIB == null)
                  _buildMasterIBButton(userFullName)
                else
                  _buildSelectedSubIBButton(),

                // Tabs
                _buildTabs(),

                // Search Bar
                _buildSearchBar(),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Statistics Cards Grid (10 cards)
                        _buildStatisticsGrid(stats, userFullName),

                        SizedBox(height: 16.h),

                        // Tab Content
                        _getTabContent(controller),

                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMasterIBButton(String userFullName) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              '$userFullName (You)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSubIBButton() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: Row(
        children: [
          InkWell(
            onTap: _backToMasterIB,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: AppColors.primary, size: 18.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Back to Master IB',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _onSubIBClicked(_selectedSubIB!),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group, color: Colors.white, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  _selectedSubIB?.name ?? 'Sub IB',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Client List', 0, Icons.person)),
          SizedBox(width: 8.w),
          Expanded(child: _buildTabButton('IB List', 1, Icons.star)),
          SizedBox(width: 8.w),
          Expanded(child: _buildTabButton('Trade History', 2, Icons.list)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          _expandedItems.clear();
        });
        // If switching to Trade History tab, trigger background loading if needed
        if (index == 2) {
          _loadMoreTradesInBackground();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.primary, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            SizedBox(width: 4.w),
            Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final hintText =
        _selectedSubIB == null
            ? 'Search Sub IBs...'
            : 'Search Sub IB\'s Sub IBs...';
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
            _expandedItems.clear();
          });
        },
        decoration: InputDecoration(
          hintText: hintText,
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

  Widget _buildStatisticsGrid(dynamic stats, String userFullName) {
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.8,
        children: [
          _buildStatCard(
            icon: Icons.account_balance_wallet,
            label: _selectedSubIB == null ? 'Master IB' : 'Sub IB',
            value: _selectedSubIB?.name ?? userFullName,
          ),
          _buildStatCard(
            icon: Icons.trending_up,
            label: 'Total Clients',
            value: (stats.totalClients ?? 0).toString(),
          ),
          _buildStatCard(
            icon: Icons.arrow_downward,
            label: 'Total Depo...',
            value: '\$${(stats.totalDeposited ?? 0).toStringAsFixed(2)}',
          ),
          _buildStatCard(
            icon: Icons.arrow_upward,
            label: 'Total Withd...',
            value: '\$${(stats.totalWithdrawal ?? 0).toStringAsFixed(2)}',
          ),
          _buildStatCard(
            icon: Icons.desktop_windows,
            label: 'Total Equity',
            value: '\$${(stats.totalEquity ?? 0).toStringAsFixed(2)}',
          ),
          _buildStatCard(
            icon: Icons.group,
            label: 'Total Sub IB',
            value: (ibController.ibSubIBs.length).toString(),
          ),
          _buildStatCard(
            icon: Icons.grid_view,
            label: 'Total Lots',
            value: (stats.totalLots ?? 0).toStringAsFixed(2),
          ),
          _buildStatCard(
            icon: Icons.account_balance_wallet,
            label: 'Total Rebate',
            value: '\$${stats.totalRebateGenerated ?? '0.00'}',
          ),
          _buildStatCard(
            icon: Icons.account_balance_wallet,
            label: 'Total Withd...',
            value: '\$${(stats.ibWithdrawalRebate ?? 0).toStringAsFixed(2)}',
          ),
          _buildStatCard(
            icon: Icons.account_balance_wallet,
            label: 'Available R...',
            value: '\$${stats.availableRebate ?? '0.00'}',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border:
            isHighlighted
                ? Border.all(color: Colors.green, width: 2)
                : Border.all(color: AppColors.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(icon, size: 18.sp, color: AppColors.primary),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10.sp, color: AppColors.textGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? Colors.green : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTabContent(IBController controller) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildClientList(controller);
      case 1:
        return _buildIbList(controller);
      case 2:
        return _buildTradeHistory(controller);
      default:
        return _buildClientList(controller);
    }
  }

  Widget _buildClientList(IBController controller) {
    final filteredClients = _getFilteredClients();
    if (filteredClients.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Center(
          child: Text(
            'No clients found',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: filteredClients.length,
      itemBuilder: (context, index) {
        final client = filteredClients[index];
        final isExpanded = _expandedItems[index] ?? false;
        return _buildExpandableClientCard(client, index, isExpanded);
      },
    );
  }

  Widget _buildExpandableClientCard(
    IBClient client,
    int index,
    bool isExpanded,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpand(index),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  // Avatar
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
                  // Name and Email
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
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.r),
                  bottomRight: Radius.circular(8.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Total Clients',
                    '${client.totalClients ?? 0}',
                  ),
                  _buildDetailRow(
                    'Total Deposit',
                    '\$${client.totalDeposit?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  _buildDetailRow(
                    'Total Rebate',
                    '\$${client.totalRebate?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  _buildDetailRow(
                    'Total Sub IBs',
                    '${client.totalSubIBs ?? 0}',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
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
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIbList(IBController controller) {
    final filteredSubIBs = _getFilteredSubIBs();
    if (filteredSubIBs.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Center(
          child: Text(
            'No Sub-IBs found',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: filteredSubIBs.length,
      itemBuilder: (context, index) {
        final subIB = filteredSubIBs[index];
        final isExpanded = _expandedItems[index] ?? false;
        return _buildExpandableSubIBCard(subIB, index, isExpanded);
      },
    );
  }

  Widget _buildExpandableSubIBCard(IBClient subIB, int index, bool isExpanded) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpand(index),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  // Avatar
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
                  // Name and Email
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
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.r),
                  bottomRight: Radius.circular(8.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Total Clients',
                    '${subIB.totalClients ?? 0}',
                  ),
                  _buildDetailRow(
                    'Total Deposit',
                    '\$${subIB.totalDeposit?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  _buildDetailRow(
                    'Total Rebate',
                    '\$${subIB.totalRebate?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  _buildDetailRow('Total Sub IBs', '${subIB.totalSubIBs ?? 0}'),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.visibility_outlined,
                          size: 18.sp,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          // View details
                        },
                      ),
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_forward,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                          onPressed: () => _onSubIBClicked(subIB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTradeHistory(IBController controller) {
    final allTradeHistory = controller.ibTradeHistory;
    final filteredTradeHistory = _getFilteredTradeHistory();
    final hasMore =
        allTradeHistory.length > _tradeHistoryDisplayLimit &&
        _searchQuery.isEmpty;

    // Show loading if controller is loading and no data yet
    if (controller.isLoading.value && allTradeHistory.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (filteredTradeHistory.isEmpty && !controller.isLoading.value) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Center(
          child: Text(
            'No trade history found',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Display filtered trade history (limited to _tradeHistoryDisplayLimit)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: filteredTradeHistory.length,
          itemBuilder: (context, index) {
            final trade = filteredTradeHistory[index];
            final isExpanded = _expandedItems[index] ?? false;
            return _buildExpandableTradeCard(trade, index, isExpanded);
          },
        ),
        // Show loading indicator if loading more in background
        if (_isLoadingMoreTrades && hasMore)
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Loading more trades...',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        // Show message if all trades are loaded
        if (!_isLoadingMoreTrades &&
            hasMore &&
            filteredTradeHistory.length >= allTradeHistory.length)
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Text(
              'All ${allTradeHistory.length} trades loaded',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandableTradeCard(
    IBTradeHistory trade,
    int index,
    bool isExpanded,
  ) {
    final isProfit = (trade.profit ?? 0) >= 0;
    // Calculate deposit and withdrawal from trade data
    // Assuming profit > 0 means deposit, profit < 0 means withdrawal
    final deposit = isProfit ? (trade.profit ?? 0) : 0.0;
    final withdrawal = !isProfit ? ((trade.profit ?? 0) * -1) : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpand(index),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(trade.clientName),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Name and Symbol
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
                          '${trade.symbol ?? ''} - ${trade.type ?? ''}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profit/Loss
                  Text(
                    '\$${trade.profit?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isProfit ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.r),
                  bottomRight: Radius.circular(8.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Client Email', trade.clientEmail ?? 'N/A'),
                  _buildDetailRow('MT5 Account', trade.mt5Account ?? 'N/A'),
                  _buildDetailRow('Volume', '${trade.volume ?? 0}'),
                  _buildDetailRow(
                    'Commission',
                    '\$${trade.commission ?? '0.00'}',
                  ),
                  if (trade.openTime != null)
                    _buildDetailRow('Open Time', trade.openTime!),
                  if (trade.closeTime != null)
                    _buildDetailRow('Close Time', trade.closeTime!),
                  SizedBox(height: 8.h),
                  // Deposit and Withdrawal with colors
                  if (deposit > 0)
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                size: 16.sp,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Deposit',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${deposit.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (withdrawal > 0) ...[
                    if (deposit > 0) SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: 16.sp,
                                color: Colors.red,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Withdrawal',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${withdrawal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
