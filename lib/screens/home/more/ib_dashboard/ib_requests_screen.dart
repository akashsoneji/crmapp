import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/ib_controller.dart';
import 'package:crm_app/models/ib_models.dart';
import 'package:intl/intl.dart';

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

  String _formatSubmissionDate(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'N/A';
    try {
      final dt = DateTime.tryParse(createdAt);
      if (dt == null) return createdAt;
      return DateFormat('MMM d, yyyy').format(dt.toLocal());
    } catch (_) {
      return createdAt;
    }
  }

  String _getRequestName(IBApprovalRequest request) {
    final name = (request.fullname ?? '').trim();
    if (name.isNotEmpty) return name;
    final user = request.user;
    final fallback = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    return fallback.isNotEmpty ? fallback : 'N/A';
  }

  String _getRequestEmail(IBApprovalRequest request) {
    final email = (request.email ?? '').trim();
    if (email.isNotEmpty) return email;
    return (request.user?.email ?? '').trim();
  }

  Color _getKycColor(String? kycStatus) {
    switch (kycStatus?.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'unverified':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.textGrey;
    }
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
                Expanded(child: _buildRequestsList()),
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
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              statuses.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textGrey,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inbox_outlined,
                  size: 48.sp,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'No requests found',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'There are no $_selectedStatus requests at the moment',
                style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Bottom padding for floating navigation bar (safe area + nav bar height + extra spacing)
    final bottomPadding = 100.h;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, bottomPadding),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(IBApprovalRequest request) {
    final statusColor = _getStatusColor(request.status);
    final name = _getRequestName(request);
    final email = _getRequestEmail(request);
    final phone = request.mobile?.toString() ?? 'N/A';
    final assignedPlan =
        (request.assignedPlan ?? '').isNotEmpty
            ? request.assignedPlan!
            : 'Not Assigned';
    final submissionDate = _formatSubmissionDate(request.createdAt);
    final kycColor = _getKycColor(request.kycStatus);
    final kycLabel =
        request.kycStatus?.isNotEmpty == true ? request.kycStatus! : 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with Avatar, Name, Status
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.03),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'N',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(request.status),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details Section
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildInfoGrid([
                  _buildInfoItem(Icons.phone_outlined, 'Phone', phone),
                  _buildInfoItem(
                    Icons.assignment_outlined,
                    'Plan',
                    assignedPlan,
                  ),
                ]),
                // SizedBox(height: 12.h),
                // _buildInfoGrid([
                //   _buildInfoItem(
                //     Icons.calendar_today_outlined,
                //     'Submitted',
                //     submissionDate,
                //   ),

                // ]),
              ],
            ),
          ),
          // Action Button Section
          if (request.status?.toLowerCase() == 'approved')
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.snackbar(
                    'Change Plan',
                    'Coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.black.withOpacity(0.85),
                    colorText: Colors.white,
                    margin: EdgeInsets.all(12.w),
                    duration: const Duration(seconds: 2),
                  );
                },
                icon: Icon(
                  Icons.edit_outlined,
                  size: 16.sp,
                  color: Colors.white,
                ),
                label: Text(
                  'Change Plan',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  // padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<Widget> children) {
    return Row(
      children: children.map((child) => Expanded(child: child)).toList(),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 16.sp,
            color: AppColors.primary.withOpacity(0.7),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
