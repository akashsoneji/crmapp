import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';

class MyClientsScreen extends StatefulWidget {
  const MyClientsScreen({super.key});

  @override
  State<MyClientsScreen> createState() => _MyClientsScreenState();
}

class _MyClientsScreenState extends State<MyClientsScreen> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        scrolledUnderElevation: 0,
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
          icon: Icon(Icons.home, color: AppColors.textPrimary),
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
          // Statistics Cards - 2x2 Grid
          Container(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
            child: Column(
              children: [
                // First row
                Row(
                  children: [
                    Expanded(child: _buildStatCard('0', 'Total Deposits')),
                    SizedBox(width: 8.w),
                    Expanded(child: _buildStatCard('0', 'Total Withdrawals')),
                  ],
                ),
                SizedBox(height: 8.h),
                // Second row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('\$0.00', 'Total commissions'),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(child: _buildStatCard('\$0.00', 'Total Volume')),
                  ],
                ),
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
            child: Row(
              children: [
                Expanded(child: _buildTabButton('Client List', 0)),
                SizedBox(width: 8.w),
                Expanded(child: _buildTabButton('IB List', 1)),
                SizedBox(width: 8.w),
                Expanded(child: _buildTabButton('Trade History', 2)),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 22.w),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search name here...',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textGrey,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
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
          Expanded(child: _getTabContent()),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
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
              color: AppColors.primary,
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

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.primary, width: 1),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _getTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildClientList();
      case 1:
        return _buildIbList();
      case 2:
        return _buildTradeHistory();
      default:
        return _buildClientList();
    }
  }

  Widget _buildClientList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      physics: const BouncingScrollPhysics(),
      itemCount: _clientNames.length * 3, // Repeat for demo
      itemBuilder: (context, index) {
        final name = _clientNames[index % _clientNames.length];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Container(
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
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIbList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      physics: const BouncingScrollPhysics(),
      itemCount: _clientNames.length * 3, // Repeat for demo
      itemBuilder: (context, index) {
        final name = _clientNames[index % _clientNames.length];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Container(
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
