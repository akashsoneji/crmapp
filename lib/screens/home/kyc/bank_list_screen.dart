import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/kyc/kyc_bank_controller.dart';
import 'package:pipze/models/bank_withdralList_model.dart';
import 'package:pipze/routes/app_pages.dart';

class BankListScreen extends StatefulWidget {
  const BankListScreen({Key? key}) : super(key: key);

  @override
  State<BankListScreen> createState() => _BankListScreenState();
}

class _BankListScreenState extends State<BankListScreen> {
  final KycBankController controller = Get.put(KycBankController());
  final RxMap<int, bool> expandedItems = <int, bool>{}.obs;

  @override
  void initState() {
    super.initState();
    // Fetch withdrawal list when screen loads
    controller.fetchWithdrawalList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
        ),
        title: Text(
          'Bank List',
          style: AppTextStyles.heading.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to KYC bank screen to add new withdrawal method
              Get.toNamed(
                AppPages.KYC_BANK,
                arguments: {'screen_name': 'Bank List', 'isFromKYC': false},
              );
            },
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.add, color: AppColors.textPrimary, size: 20.sp),
            ),
          ),
        ],
      ),
      body: Obx(() {
        // Show loading indicator while fetching data
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // After loading completes, show data or empty state
        final list = controller.bankWithdrawalList;

        if (list.isEmpty) {
          return _buildEmptyState();
        }

        return _buildWithdrawalList();
      }),
    );
  }

  // Empty state when no withdrawal methods exist
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 60.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Withdrawal Methods',
              style: AppTextStyles.heading.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You haven\'t added any withdrawal methods yet.\nAdd your first withdrawal method to get started.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subheading.copyWith(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () {
                Get.toNamed(
                  AppPages.KYC_BANK,
                  arguments: {'screen_name': 'Bank List', 'isFromKYC': false},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Add Withdrawal Method',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // List of withdrawal methods
  Widget _buildWithdrawalList() {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.fetchWithdrawalList();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: controller.bankWithdrawalList.length,
          itemBuilder: (context, index) {
            final method = controller.bankWithdrawalList[index];
            return _buildWithdrawalItem(method);
          },
        ),
      ),
    );
  }

  // Individual withdrawal method item
  Widget _buildWithdrawalItem(WithdrawalMethods method) {
    final isExpanded =
        method.id != null ? (expandedItems[method.id!] ?? false) : false;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Main item content
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            onTap: () {
              if (method.id != null) {
                setState(() {
                  expandedItems[method.id!] = !isExpanded;
                });
              }
            },
            title: Text(
              _getDisplayTitle(method),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _getDisplaySubtitle(method),
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusBadge(method.status),
                SizedBox(width: 8.w),
                AnimatedRotation(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  turns: isExpanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.icongrey,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
          ),

          // Expanded details with smooth animation
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                isExpanded ? _buildExpandedDetails(method) : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Status badge
  Widget _buildStatusBadge(String? status) {
    Color badgeColor;
    switch (status?.toLowerCase()) {
      case 'approved':
        badgeColor = const Color(0xFF4CAF50);
        break;
      case 'rejected':
        badgeColor = const Color(0xFFF44336);
        break;
      case 'pending':
        badgeColor = const Color(0xFFFF9800);
        break;
      default:
        badgeColor = const Color(0xFF9E9E9E);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        status?.toUpperCase() ?? 'UNKNOWN',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // Expanded details section
  Widget _buildExpandedDetails(WithdrawalMethods method) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12.r),
          bottomRight: Radius.circular(12.r),
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow('Bank Account No.', method.bankAccountNo ?? 'N/A'),
          _buildDetailRow('IBAN/IFSC Code', method.ifscIban ?? 'N/A'),
          _buildDetailRow('Account Holder Name', method.holderName ?? 'N/A'),
          _buildDetailRow('Currency', method.currency ?? 'N/A'),
          // if (method.proofImg != null && method.proofImg!.isNotEmpty) ...[
          //   SizedBox(height: 12.h),
          //   GestureDetector(
          //     onTap: () {
          //       // TODO: Implement view proof functionality
          //       _showProofDialog(method.proofImg!);
          //     },
          //     child: Container(
          //       width: double.infinity,
          //       padding: EdgeInsets.symmetric(vertical: 12.h),
          //       decoration: BoxDecoration(
          //         color: AppColors.primary.withOpacity(0.1),
          //         borderRadius: BorderRadius.circular(8.r),
          //         border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          //       ),
          //       child: Text(
          //         'View Attached Proof',
          //         textAlign: TextAlign.center,
          //         style: TextStyle(
          //           fontSize: 14.sp,
          //           fontWeight: FontWeight.w600,
          //           color: AppColors.primary,
          //         ),
          //       ),
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  // Detail row widget
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get display title for withdrawal method
  String _getDisplayTitle(WithdrawalMethods method) {
    switch (method.withdrawalMethod?.toLowerCase()) {
      case 'bank':
        final accountNo = method.bankAccountNo ?? '';
        final last4 =
            accountNo.length > 4
                ? accountNo.substring(accountNo.length - 4)
                : accountNo;
        return '${method.bankName ?? 'Bank'} - $last4';
      case 'upi':
        return 'UPI';
      case 'crypto':
        return 'Crypto';
      default:
        final methodName = method.withdrawalMethod ?? 'Unknown';
        return methodName[0].toUpperCase() + methodName.substring(1);
    }
  }

  // Get display subtitle for withdrawal method
  String _getDisplaySubtitle(WithdrawalMethods method) {
    switch (method.withdrawalMethod?.toLowerCase()) {
      case 'bank':
        return method.holderName ?? '';
      case 'upi':
        return method.upiAddress ?? '';
      case 'crypto':
        return method.cryptoAddress ?? '';
      default:
        return '';
    }
  }

  // Show proof dialog
  void _showProofDialog(String proofUrl) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Attached Proof'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Proof URL: $proofUrl'),
                SizedBox(height: 16.h),
                // TODO: Add image viewer or download functionality
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          ),
    );
  }
}
