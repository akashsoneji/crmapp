import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/ib_controller.dart';
import 'package:crm_app/models/ib_models.dart';

import '../../../../core/widgets/common_loading_widget.dart';

class CommissionGroupFormScreen extends StatefulWidget {
  final CommissionGroup? group;

  const CommissionGroupFormScreen({super.key, this.group});

  @override
  State<CommissionGroupFormScreen> createState() =>
      _CommissionGroupFormScreenState();
}

class _CommissionGroupFormScreenState extends State<CommissionGroupFormScreen> {
  late IBController ibController;
  final TextEditingController _groupNameController = TextEditingController();
  final Map<String, TextEditingController> _commissionControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Get or create IBController
    if (Get.isRegistered<IBController>()) {
      ibController = Get.find<IBController>();
    } else {
      ibController = Get.put(IBController());
    }
    _loadStructureDataAndInitialize();
  }

  Future<void> _loadStructureDataAndInitialize() async {
    // Always load structure data to ensure we have latest data
    await ibController.getIBStructure(showLoading: true);
    if (mounted) {
      setState(() {
        // Force rebuild after data loads
      });
      _initializeForm();
    }
  }

  void _initializeForm() {
    if (widget.group != null) {
      _groupNameController.text = widget.group!.groupName ?? '';
      _loadExistingCommissionData();
    } else {
      _initializeEmptyForm();
    }
  }

  void _initializeEmptyForm() {
    final structureData = ibController.ibStructureData.value;
    if (structureData?.masterGroups != null &&
        structureData?.symbolCategories != null) {
      for (var masterGroup in structureData!.masterGroups!) {
        for (var category in structureData.symbolCategories!) {
          final key = '${masterGroup.id}_${category.id}';
          _commissionControllers[key] = TextEditingController(text: '0');
        }
      }
    }
  }

  void _loadExistingCommissionData() {
    if (widget.group?.parsedCommissionData != null) {
      final data = widget.group!.parsedCommissionData!;
      for (var masterId in data.keys) {
        final masterData = data[masterId];
        if (masterData is Map && masterData['commission'] != null) {
          final commissions = masterData['commission'] as Map;
          for (var categoryId in commissions.keys) {
            final key = '${masterId}_$categoryId';
            final value = commissions[categoryId];
            _commissionControllers[key] = TextEditingController(
              text: value?.toString() ?? '0',
            );
          }
        }
      }
    } else {
      _initializeEmptyForm();
    }
  }

  double? _getMaxValue(int masterId, int categoryId) {
    final structureData = ibController.ibStructureData.value;
    if (structureData?.masterGroups != null) {
      final masterGroup = structureData!.masterGroups!.firstWhere(
        (g) => g.id == masterId,
        orElse: () => MasterGroup(),
      );
      if (masterGroup.commissions != null) {
        final category = structureData.symbolCategories?.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => SymbolCategory(),
        );
        if (category?.categoryName != null) {
          final commissionStr =
              masterGroup.commissions![category!.categoryName!];
          if (commissionStr != null &&
              commissionStr.isNotEmpty &&
              commissionStr != '0.00') {
            final value = double.tryParse(commissionStr);
            if (value != null && value > 0) {
              return value;
            }
          }
        }
      }
    }
    return null;
  }

  Future<void> _saveGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a group name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final structureData = ibController.ibStructureData.value;
      if (structureData?.masterGroups == null) {
        throw Exception('Structure data not loaded');
      }

      final masterIds = structureData!.masterGroups!.map((g) => g.id!).toList();
      final commissionRates = <String, dynamic>{};

      // Ensure all commission rates are included (even if 0)
      for (var masterGroup in structureData.masterGroups!) {
        for (var category in structureData.symbolCategories!) {
          final key = '${masterGroup.id}_${category.id}';
          final controller = _commissionControllers[key];
          if (controller != null) {
            final value = controller.text.trim();
            final numValue = double.tryParse(value) ?? 0;
            commissionRates['${masterGroup.id}_${category.id}'] =
                numValue.toInt();
          } else {
            commissionRates['${masterGroup.id}_${category.id}'] = 0;
          }
        }
      }

      final success = await ibController.manageCommissionGroup(
        groupName: _groupNameController.text.trim(),
        masterIds: masterIds,
        structureType: 'standard',
        commissionRates: commissionRates,
        groupId: widget.group?.id,
      );

      if (success) {
        Get.back();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save group: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (var controller in _commissionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.group != null ? 'Edit Standard Group' : 'Add Standard Group',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: GetBuilder<IBController>(
        id: 'ib_structure',
        builder: (controller) {
          return Obx(() {
            final isLoading = controller.isLoading.value;
            final structureData = controller.ibStructureData.value;

            if (isLoading) {
              return Center(
                child: CommonLoadingWidget(
                  message: 'Loading structure data...',
                  size: 50.0,
                  color: AppColors.primary,
                ),
              );
            }

            if (structureData == null ||
                structureData.masterGroups == null ||
                structureData.masterGroups!.isEmpty ||
                structureData.symbolCategories == null ||
                structureData.symbolCategories!.isEmpty) {
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Text(
                        controller.errorMessage.value.isNotEmpty
                            ? controller.errorMessage.value
                            : 'Failed to load structure data',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        _loadStructureDataAndInitialize();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Standard Group Structure',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Standard Group Structure: Create commission groups for Sub-IBs. Commission rates cannot exceed your own rates.',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Group Name Section
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Group Name',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: _groupNameController,
                          decoration: InputDecoration(
                            hintText: 'Enter group name',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14.sp,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.r),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.r),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.r),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Commission Rates Section
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Commission Rates (Category-wise)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildCommissionGrid(
                          structureData.masterGroups!,
                          structureData.symbolCategories!,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 80.h), // Space for bottom buttons
                ],
              ),
            );
          });
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'Save Standard Group',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommissionGrid(
    List<MasterGroup> masterGroups,
    List<SymbolCategory> categories,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            masterGroups.map((masterGroup) {
              return _buildMasterGroupColumn(masterGroup, categories);
            }).toList(),
      ),
    );
  }

  Widget _buildMasterGroupColumn(
    MasterGroup masterGroup,
    List<SymbolCategory> categories,
  ) {
    return Container(
      width: 280.w,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            child: Text(
              masterGroup.planTitle?.toUpperCase() ?? 'N/A',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Categories
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children:
                  categories.map((category) {
                    return _buildCategoryInput(masterGroup, category);
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInput(MasterGroup masterGroup, SymbolCategory category) {
    final key = '${masterGroup.id}_${category.id}';
    final controller =
        _commissionControllers[key] ??= TextEditingController(text: '0');
    final maxValue = _getMaxValue(masterGroup.id!, category.id!);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.categoryName ?? 'N/A',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: TextStyle(
                color: Colors.black87,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              isDense: true,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            maxValue != null
                ? 'Max: \$${maxValue.toStringAsFixed(2)}'
                : 'Max: \$0.00',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
