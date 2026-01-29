import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/ib_controller.dart';
import 'package:crm_app/models/ib_models.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
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
    final sponsoredApproved = (request.spApproveRejectBy ?? '').isNotEmpty
        ? request.spApproveRejectBy!
        : 'N/A';
    final assignedPlan = (request.assignedPlan ?? '').isNotEmpty
        ? request.assignedPlan!
        : 'N/A';
    final submissionDate = _formatSubmissionDate(request.createdAt);
    final kycColor = _getKycColor(request.kycStatus);
    final kycLabel =
        request.kycStatus?.isNotEmpty == true ? request.kycStatus! : 'N/A';

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
              // Index
              // Container(
              //   padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              //   decoration: BoxDecoration(
              //     color: AppColors.primary.withOpacity(0.08),
              //     borderRadius: BorderRadius.circular(8.r),
              //   ),
              //   child: Text(
              //     '#${request.dtRowIndex ?? ''}',
              //     style: TextStyle(
              //       fontSize: 12.sp,
              //       fontWeight: FontWeight.w700,
              //       color: AppColors.primary,
              //     ),
              //   ),
              // ),
              // SizedBox(width: 10.w),
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'N',
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
                      name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
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
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 28.h,
                    child: OutlinedButton(
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
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      child: Text(
                        'Change Plan',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 12.h),
          _buildDetailRow('Phone', phone),
          _buildDetailRow(
            'KYC Status',
            kycLabel,
            valueColor: kycColor,
          ),
          _buildDetailRow('Sponsored Approved', sponsoredApproved),
          _buildDetailRow('Assigned Plan', assignedPlan),
          _buildDetailRow('Submission Date', submissionDate),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
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
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
