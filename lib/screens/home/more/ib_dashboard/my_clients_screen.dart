import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pipze/constants/color.dart';

class MyClientsScreen extends StatefulWidget {
  const MyClientsScreen({super.key});

  @override
  State<MyClientsScreen> createState() => _MyClientsScreenState();
}

class _MyClientsScreenState extends State<MyClientsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  String? _selectedFilter;

  final List<String> _clientNames = [
    'Shaikh Ganim Mohammed Iqbal',
    'Mer Rajdip Tansukhbhai',
    'Adhvaryu Chirag Pareshbhai',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: Text(
          'My Clients',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              size: 24.sp,
              color: AppColors.textPrimary,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          Container(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('0', 'Total Deposits')),
                SizedBox(width: 8.w),
                Expanded(child: _buildStatCard('0', 'Total Withdrawals')),
                SizedBox(width: 8.w),
                Expanded(child: _buildStatCard('\$0.00', 'Total commissions')),
                SizedBox(width: 8.w),
                Expanded(child: _buildStatCard('\$0.00', 'Total Volume')),
              ],
            ),
          ),

          // Active Filter Tag
          if (_selectedFilter != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedFilter!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = null;
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Tabs
          Container(
            margin: EdgeInsets.symmetric(horizontal: 22.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textGrey,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(text: 'Client List'),
                Tab(text: _selectedTabIndex == 1 ? 'Sub IB List' : 'IB List'),
                Tab(text: 'Trade History'),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Search Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 22.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search name here...',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textGrey,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  size: 20.sp,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClientList(),
                _buildIbList(),
                _buildTradeHistory(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(fontSize: 10.sp, color: AppColors.textGrey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClientList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      itemCount: _clientNames.length * 3, // Repeat for demo
      itemBuilder: (context, index) {
        final name = _clientNames[index % _clientNames.length];
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20.sp,
                color: AppColors.textGrey,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIbList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      itemCount: _clientNames.length * 3, // Repeat for demo
      itemBuilder: (context, index) {
        final name = _clientNames[index % _clientNames.length];
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20.sp,
                color: AppColors.textGrey,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTradeHistory() {
    return Center(
      child: Text(
        'Trade History',
        style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Bar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Sub IB',
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textGrey,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Filter List
                ...List.generate(_clientNames.length, (index) {
                  final name = _clientNames[index];
                  final isSelected = _selectedFilter == name;

                  return Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFilter = isSelected ? null : name;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 20.sp,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
