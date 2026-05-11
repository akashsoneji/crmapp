import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/pmam/pmam_controller.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:crm_app/models/pmam_model.dart';
import 'package:crm_app/screens/home/more/pmam/pmam_widgets.dart';

class PmamManagerDetailScreen extends StatefulWidget {
  const PmamManagerDetailScreen({super.key});

  @override
  State<PmamManagerDetailScreen> createState() =>
      _PmamManagerDetailScreenState();
}

class _PmamManagerDetailScreenState extends State<PmamManagerDetailScreen> {
  late final PmamController _ctrl;
  late PmamManager _manager;
  PmamPlan? _selectedPlan;

  // For Invest Now sheet
  Map<String, dynamic>? _selectedAccount;

  @override
  void initState() {
    super.initState();
    if (Get.arguments is PmamManager) {
      _manager = Get.arguments as PmamManager;
      if (_manager.plans.isNotEmpty) {
        _selectedPlan = _manager.plans.first;
      }
    } else {
      Get.back();
      return;
    }

    if (Get.isRegistered<PmamController>()) {
      _ctrl = Get.find<PmamController>();
    } else {
      _ctrl = Get.put(PmamController());
    }

    if (_selectedPlan != null) {
      _ctrl.loadEligibleAccounts(_selectedPlan!.id);
    }
  }

  String _fmt(double val) {
    return '\$${val.toStringAsFixed(2)}';
  }

  void _showInvestSheet() {
    if (_selectedPlan == null) return;
    _selectedAccount = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setSheetState) {
              final double balance =
                  double.tryParse(
                    _selectedAccount?['available_balance']?.toString() ?? '0',
                  ) ??
                  0;
              final double minInvest = _selectedPlan?.minimumInvestment ?? 0;
              final bool isBalanceEnough = balance >= minInvest;
              final bool canInvest =
                  isBalanceEnough && _selectedAccount != null;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22.r),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: 20.h,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 30.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      'Invest Now',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Plan Selection Dropdown
                    if (_manager.plans.length > 1) ...[
                      Text(
                        'Select Plan',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGrey,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: AppColors.tradeBackgroundCenterColor,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PmamPlan>(
                            isExpanded: true,
                            value: _selectedPlan,
                            items:
                                _manager.plans.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      p.planName,
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() {
                                  _selectedPlan = val;
                                  _selectedAccount = null;
                                  _ctrl.loadEligibleAccounts(val.id);
                                });
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    Text(
                      'Select Trading Account',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Obx(() {
                      if (_ctrl.isLoading.value) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(10.h),
                            child: CommonLoadingWidget(
                              size: 24,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: AppColors.tradeBackgroundCenterColor,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Map<String, dynamic>>(
                            isExpanded: true,
                            value: _selectedAccount,
                            hint: Text(
                              'Choose an account',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            items:
                                _ctrl.eligibleAccounts.map((acc) {
                                  final accNo =
                                      acc['meta_account_number'] ?? '-';
                                  final bal =
                                      double.tryParse(
                                        acc['balance']?.toString() ?? '0',
                                      ) ??
                                      0;
                                  final availBal =
                                      double.tryParse(
                                        acc['available_balance']?.toString() ??
                                            '0',
                                      ) ??
                                      0;
                                  return DropdownMenuItem(
                                    value: acc,
                                    child: Text(
                                      '$accNo — Balance: \$${bal.toStringAsFixed(2)} (Available: \$${availBal.toStringAsFixed(2)})',
                                      style: TextStyle(fontSize: 13.sp),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              setSheetState(() => _selectedAccount = val);
                            },
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 20.h),

                    // Info Card: Min Invest vs Balance
                    if (_selectedPlan != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Min. Investment:',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                Text(
                                  _fmt(_selectedPlan!.minimumInvestment),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedAccount != null) ...[
                              SizedBox(height: 6.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Your Balance:',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  Text(
                                    _fmt(balance),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isBalanceEnough
                                              ? AppColors.green
                                              : AppColors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                    if (_selectedAccount != null && !isBalanceEnough)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          'Insufficient balance for this plan.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    SizedBox(height: 24.h),

                    // Confirm Invest Button
                    SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        height: 44.h,
                        child: ElevatedButton(
                          onPressed:
                              canInvest
                                  ? () {
//                                     print('''
//  _selectedAccount!['id'],${ _selectedAccount!['id']},
                                     
//                                       _selectedPlan!.id,${ _selectedPlan!.id},
//                                       invest_amount(balance),$balance,''');
                                    Navigator.pop(ctx);
                                    _ctrl.joinPlan(
                                      _selectedAccount!['id'],
                                      _selectedPlan!.id,
                                      balance, // invest full available balance
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.textGrey
                                .withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Confirm Invest',
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(height: kBottomNavigationBarHeight),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _manager.managerName ?? 'Fund Manager';
    final initials =
        name
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join();

    final gain = _manager.profitPercentage;
    final aum = _fmt(_manager.totalAum);
    final commission = '${_selectedPlan?.commissionPercentage ?? 0}%';
    final investors = '${_manager.totalInvestors}';
    final minInvest = _fmt(_selectedPlan?.minimumInvestment ?? 0);

    return Scaffold(
      backgroundColor: PmamColors.scaffoldBg,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: PmamColors.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
        ),
        title: Text('Manager Detail', style: AppTextStyles.heading),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          children: [
            // Profile header card
            PmamCard(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  PmamAvatar(name: name, size: 64, fontSize: 22),
                  SizedBox(height: 10.h),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: PmamColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: PmamColors.primaryPurpleLight,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'FUND MANAGER',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: PmamColors.primaryPurple,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _showInvestSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PmamColors.primaryPurple,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 18.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'INVEST NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Min. Investment: $minInvest',
                    style: TextStyle(fontSize: 12.sp, color: PmamColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _DetailStatCard(
                    label: 'GAIN',
                    value: '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(2)}%',
                    icon: Icons.trending_up_rounded,
                    color: gain >= 0 ? PmamColors.approvedGreenText : PmamColors.rejectedRedText,
                  ),
                  SizedBox(width: 8.w),
                  _DetailStatCard(
                    label: 'TOTAL AUM',
                    value: aum,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  SizedBox(width: 8.w),
                  _DetailStatCard(
                    label: 'INVESTORS',
                    value: investors,
                    icon: Icons.people_rounded,
                  ),
                  SizedBox(width: 8.w),
                  _DetailStatCard(
                    label: 'COMMISSION',
                    value: commission,
                    icon: Icons.percent_rounded,
                    color: PmamColors.primaryPurple,
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            if (_selectedPlan != null)
              PmamCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Plan Details',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: PmamColors.textPrimary,
                          ),
                        ),
                        if (_manager.plans.length > 1)
                          GestureDetector(
                            onTap: _showInvestSheet,
                            child: Text(
                              'Change Plan',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: PmamColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    PmamInfoRow(label: 'Plan Name', value: _selectedPlan!.planName),
                    SizedBox(height: 8.h),
                    PmamInfoRow(label: 'Manager Code', value: _manager.managerCode),
                    SizedBox(height: 8.h),
                    PmamInfoRow(label: 'Commission', value: commission),
                    SizedBox(height: 8.h),
                    PmamInfoRow(label: 'Min. Investment', value: minInvest),
                    if (_selectedPlan!.strategyDescription != null &&
                        _selectedPlan!.strategyDescription!.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Text(
                        'Strategy',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: PmamColors.primaryPurple,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _selectedPlan!.strategyDescription!,
                        style: TextStyle(fontSize: 13.sp, color: PmamColors.textSecondary, height: 1.4),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                    if (_selectedPlan!.riskInformation != null &&
                        _selectedPlan!.riskInformation!.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Text(
                        'Risk Information',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: PmamColors.primaryPurple,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _selectedPlan!.riskInformation!,
                        style: TextStyle(fontSize: 13.sp, color: PmamColors.textSecondary, height: 1.4),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ],
                ),
              ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _DetailStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Container(
      width: 100.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: c.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 18.sp),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: c,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
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
