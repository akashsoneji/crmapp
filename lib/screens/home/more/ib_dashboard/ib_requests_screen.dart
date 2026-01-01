import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/ib_controller.dart';
import 'package:crm_app/models/ib_models.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';

class IBRequestsScreen extends StatefulWidget {
  const IBRequestsScreen({super.key});

  @override
  State<IBRequestsScreen> createState() => _IBRequestsScreenState();
}

class _IBRequestsScreenState extends State<IBRequestsScreen> {
  late IBController ibController;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    ibController = Get.find<IBController>();
    // Reset filter when screen initializes
    _selectedStatus = 'All';
    _loadApprovalRequests();
  }

  Future<void> _loadApprovalRequests() async {
    await ibController.getIBApprovalRequests();
  }

  Future<void> _onRefresh() async {
    await _loadApprovalRequests();
  }

  List<IBApprovalRequest> _getFilteredRequests() {
    final allRequests = ibController.ibApprovalRequests.toList();
    if (_selectedStatus == 'All') return allRequests;
    return allRequests
        .where((request) => request.status == _selectedStatus.toLowerCase())
        .toList();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'inreview':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.textGrey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'inreview':
        return 'In Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status ?? 'Unknown';
    }
  }

  String _getInitials(String? firstName, String? lastName) {
    if (firstName == null && lastName == null) return 'N/A';
    final first = firstName?.isNotEmpty == true ? firstName![0] : '';
    final last = lastName?.isNotEmpty == true ? lastName![0] : '';
    return '${first.toUpperCase()}${last.toUpperCase()}';
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
          'IB Requests',
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
          id: 'ib_requests',
          builder: (controller) {
            if (controller.isLoading.value &&
                controller.ibApprovalRequests.isEmpty) {
              return Center(
                child: CommonLoadingWidget(
                  message: 'Loading requests...',
                  size: 50.0,
                  color: AppColors.primary,
                ),
              );
            }

            return Column(
              children: [
                // Status Filter Tabs
                _buildStatusFilter(),

                // Requests List
                Expanded(
                  child: _buildRequestsList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = ['All', 'In Review', 'Approved', 'Rejected'];
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = _selectedStatus == status;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textGrey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                checkmarkColor: AppColors.primary,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    final filteredRequests = _getFilteredRequests();

    if (filteredRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            children: [
              Icon(
                Icons.notifications_none,
                size: 64.sp,
                color: AppColors.textGrey,
              ),
              SizedBox(height: 16.h),
              Text(
                'No requests found',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(IBApprovalRequest request) {
    final user = request.user;
    final statusColor = _getStatusColor(request.status);

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
                    _getInitials(user?.firstName, user?.lastName),
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
                      '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      user?.email ?? '',
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  _getStatusLabel(request.status),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (request.expectedClient != null) ...[
            _buildDetailRow('Expected Clients', request.expectedClient!),
          ],
          if (request.country != null && request.country!.isNotEmpty) ...[
            _buildDetailRow(
              'Countries',
              request.country!.join(', '),
            ),
          ],
          if (request.createdAt != null) ...[
            _buildDetailRow('Created', request.createdAt!),
          ],
          if (request.updatedAt != null) ...[
            _buildDetailRow('Updated', request.updatedAt!),
          ],
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
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
