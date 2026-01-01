import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/ib_controller.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';

class IBMoreScreen extends StatefulWidget {
  const IBMoreScreen({super.key});

  @override
  State<IBMoreScreen> createState() => _IBMoreScreenState();
}

class _IBMoreScreenState extends State<IBMoreScreen> {
  late IBController ibController;

  @override
  void initState() {
    super.initState();
    ibController = Get.find<IBController>();
    _loadMoreData();
  }

  Future<void> _loadMoreData() async {
    await Future.wait([ibController.getIBStructure()]);
  }

  Future<void> _onRefresh() async {
    await _loadMoreData();
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
          'More',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        backgroundColor: Colors.white,
        color: AppColors.primary,
        child: GetBuilder<IBController>(
          id: 'ib_more',
          builder: (controller) {
            if (controller.isLoading.value &&
                controller.ibStructureData.value == null) {
              return Center(
                child: CommonLoadingWidget(
                  message: 'Loading...',
                  size: 50.0,
                  color: AppColors.primary,
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Commission Structure Section
                  if (controller.ibStructureData.value != null) ...[
                    _buildSectionTitle('Commission Structure'),
                    SizedBox(height: 12.h),
                    _buildCommissionStructureCard(
                      controller.ibStructureData.value!,
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Support Section
                  _buildSectionTitle('Support'),
                  SizedBox(height: 12.h),
                  _buildSupportCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCommissionStructureCard(dynamic structure) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
          if (structure.groupId != null)
            _buildDetailRow('Group ID', structure.groupId.toString()),
          if (structure.groupName != null)
            _buildDetailRow('Group Name', structure.groupName!),
          if (structure.mt5Groups != null && structure.mt5Groups!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                'MT5 Groups: ${structure.mt5Groups!.length}',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
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
        children: [
          _buildSupportItem(
            Icons.help_outline,
            'Help & Support',
            'Get assistance with your IB account',
          ),
          Divider(height: 24.h),
          _buildSupportItem(
            Icons.info_outline,
            'About IB Program',
            'Learn more about the IB program',
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {
        // Handle support item tap
      },
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textGrey, size: 20.sp),
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
}
