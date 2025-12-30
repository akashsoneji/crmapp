import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/controllers/ib_controller.dart';
import 'package:pipze/models/ib_models.dart';
import 'package:pipze/widgets/common_loading_widget.dart';

class IBStructureScreen extends StatefulWidget {
  const IBStructureScreen({super.key});

  @override
  State<IBStructureScreen> createState() => _IBStructureScreenState();
}

class _IBStructureScreenState extends State<IBStructureScreen> {
  late IBController ibController;
  List<IBClient> _ibHierarchy = [];

  @override
  void initState() {
    super.initState();
    ibController = Get.find<IBController>();
    // Reset hierarchy when screen initializes
    _ibHierarchy.clear();
    // Reset selected sub-IB if we're on structure screen
    if (ibController.selectedSubIBId != null) {
      ibController.selectedSubIBId = null;
    }
    _loadStructureData();
  }

  Future<void> _loadStructureData() async {
    await Future.wait([
      ibController.getIBStructure(),
      ibController.getIBSubIBs(),
    ]);
  }

  Future<void> _onRefresh() async {
    await _loadStructureData();
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
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
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
          'IB Structure',
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
          id: 'ib_structure',
          builder: (controller) {
            if (controller.isLoading.value && controller.ibSubIBs.isEmpty) {
              return Center(
                child: CommonLoadingWidget(
                  message: 'Loading structure...',
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
                  // Breadcrumb Navigation
                  if (_ibHierarchy.isNotEmpty) ...[
                    _buildBreadcrumb(),
                    SizedBox(height: 16.h),
                  ],

                  // Commission Structure
                  if (controller.ibStructureData.value != null) ...[
                    _buildCommissionStructure(controller.ibStructureData.value!),
                    SizedBox(height: 16.h),
                  ],

                  // Sub-IBs List
                  Text(
                    'Sub-IBs',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  if (controller.ibSubIBs.isEmpty)
                    Center(
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
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...controller.ibSubIBs.take(50).map((subIB) {
                      return _buildSubIBCard(subIB);
                    }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
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
                  Icon(
                    Icons.arrow_back,
                    color: AppColors.primary,
                    size: 16.sp,
                  ),
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
                Icon(Icons.chevron_right, size: 16.sp, color: AppColors.textGrey),
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

  Widget _buildCommissionStructure(IBStructureData structure) {
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
          Text(
            'Commission Structure',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          if (structure.groupId != null)
            _buildDetailRow('Group ID', structure.groupId.toString()),
          if (structure.groupName != null)
            _buildDetailRow('Group Name', structure.groupName!),
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
                      Icon(Icons.person, size: 12.sp, color: AppColors.textGrey),
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
}
