import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/ib_controller.dart';
import 'package:crm_app/models/ib_models.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';

class MyStructureScreen extends StatefulWidget {
  const MyStructureScreen({super.key});

  @override
  State<MyStructureScreen> createState() => _MyStructureScreenState();
}

class _MyStructureScreenState extends State<MyStructureScreen> {
  late IBController ibController;

  @override
  void initState() {
    super.initState();
    // Get or create IBController
    if (Get.isRegistered<IBController>()) {
      ibController = Get.find<IBController>();
    } else {
      ibController = Get.put(IBController());
    }
    _loadData();
  }

  Future<void> _loadData() async {
    await ibController.getIBStructure();
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  String _getCommissionValue(MasterGroup group, String categoryName) {
    if (group.commissions == null) return '0.00';
    final value = group.commissions![categoryName];
    if (value == null || value.isEmpty) return '0.00';
    return value;
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
          'My Structure',
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
            if (controller.isLoading.value &&
                controller.ibStructureData.value == null) {
              return Center(
                child: CommonLoadingWidget(
                  message: 'Loading structure...',
                  size: 50.0,
                  color: AppColors.primary,
                ),
              );
            }

            final structureData = controller.ibStructureData.value;
            if (structureData == null ||
                structureData.masterGroups == null ||
                structureData.masterGroups!.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_tree_outlined,
                        size: 64.sp,
                        color: AppColors.textGrey,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No structure data found',
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

            final masterGroups = structureData.masterGroups!;
            final symbolCategories = structureData.symbolCategories ?? [];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Standard Groups Tab (read-only, no tabs needed)
                  Container(
                    padding: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Standard Groups',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Description
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'These commission rates are used for your direct clients. Commission flows up the hierarchy: Your Rate - Sub-IB Rate = Your Profit.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Commission Groups Cards (Horizontal Scroll)
                  SizedBox(
                    height: 450.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: masterGroups.length,
                      itemBuilder: (context, index) {
                        final group = masterGroups[index];
                        return Container(
                          width: 300.w,
                          margin: EdgeInsets.only(right: 16.w),
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
                              // Header
                              Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12.r),
                                    topRight: Radius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  group.groupName?.toUpperCase() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: symbolCategories.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No categories available',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: AppColors.textGrey,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: symbolCategories.length,
                                          itemBuilder: (context, catIndex) {
                                            final category =
                                                symbolCategories[catIndex];
                                            final categoryName =
                                                category.categoryName ?? '';
                                            final commissionValue =
                                                _getCommissionValue(
                                                    group, categoryName);
                                            return Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 16.h),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      categoryName,
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Container(
                                                    width: 100.w,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 12.w,
                                                      vertical: 10.h,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.r),
                                                      border: Border.all(
                                                        color:
                                                            Colors.grey.shade300,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '\$$commissionValue',
                                                      textAlign: TextAlign.right,
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom padding for floating navigation bar (safe area + nav bar height + extra spacing)
                  SizedBox(height: 100.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
