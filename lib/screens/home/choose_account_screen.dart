import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/plan_controller.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/screens/home/create_pipze_account_screen.dart';
import 'package:pipze/widgets/dashBorder.dart';

class ChooseAccountScreen extends StatefulWidget {
  const ChooseAccountScreen({Key? key}) : super(key: key);

  @override
  State<ChooseAccountScreen> createState() => _ChooseAccountScreenState();
}

class _ChooseAccountScreenState extends State<ChooseAccountScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;

  final PlanController planController = Get.put(PlanController());

  @override
  void initState() {
    super.initState();
    planController.fetchPlan(groupId: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: AppColors.grey)),
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
        ),
        title: Text('Choose your account', style: AppTextStyles.heading),
      ),
      // backgroundColor: AppColors.whiteColor,
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Instructional Text
            _buildInstructionalText(),

            // Account Cards with proper spacing
            Container(
              height: 540.h,

              margin: EdgeInsets.symmetric(vertical: 16),
              child: _buildAccountCards(),
            ),

            // Page Indicator
            // _buildPageIndicator(),
            // SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionalText() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Text(
        'Choose an account type you\'d like to start trading with',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17.sp,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w400,
          height: 1.59,
        ),
      ),
    );
  }

  Widget _buildAccountCards() {
    return Obx(() {
      if (planController.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }
      if (planController.errorMessage.isNotEmpty) {
        return Center(child: Text(planController.errorMessage.value));
      }
      if (planController.plan.value != null) {
        return _buildAccountCard(planController.plan.value!, 0);
      }
      if (planController.plans.isNotEmpty) {
        print('planController.plans.length ${planController.plans.length}');
        return PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: planController.plans.length,
          itemBuilder: (context, index) {
            return _buildAccountCard(planController.plans[index], index);
          },
        );
      }
      return Center(child: Text("No plans available"));
    });
  }

  Widget _buildAccountCard(PlanModel accountType, int index) {
    bool isCurrentCard = index == _currentIndex;
    print('accountType.planTitle ${accountType.commission}');
    return Container(
      height: 465.h, // Removed fixed height so the card can size itself
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary,
          width: isCurrentCard ? 1 : 1,
        ),
        boxShadow:
            isCurrentCard
                ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with name and icon
          Row(
            children: [
              Expanded(
                child: Text(
                  '${accountType.tradingPlatform ?? ''} ${accountType.planTitle ?? ''}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              // Container(
              //   width: 28.w,
              //   height: 24.h,
              //   decoration: BoxDecoration(
              //     color: AppColors.primary,
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: Center(
              //     child: Text(
              //       accountType.icon,
              //       style: TextStyle(
              //         fontSize: 18,
              //         fontWeight: FontWeight.bold,
              //         color: Colors.white,
              //       ),
              //     ),
              //   ),
              // ),
              SvgPicture.asset(
                "assets/svg/deshboard/mt5_chose_account.svg",
                height: 24.h,
                width: 28.w,
              ),
            ],
          ),

          SizedBox(height: 10),

          // Account specifications
          _buildSpecificationRow(
            'Spread from',
            accountType.spread.toString() ?? "",
          ),
          _buildDivider(),
          _buildSpecificationRow(
            maxLine: 2,
            'Instruments',
            accountType.tradingInstruments ?? "",
          ),
          _buildDivider(),
          _buildSpecificationRow(
            'Min deposit',
            accountType.minimumDeposit ?? "",
          ),
          _buildDivider(),
          _buildSpecificationRow(
            'Maximum leverage',
            accountType.leverage ?? "",
          ),
          _buildDivider(),
          _buildSpecificationRow('Margin call', ""),
          // _buildSpecificationRow('Margin call', "accountType.margincall"),
          _buildDivider(),
          _buildSpecificationRow(
            'Stop Out level',
            accountType.stopOutLevel ?? "",
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: _buildDivider(),
          ),
          // Instead of Spacer, use a SizedBox to prevent expansion
          // SizedBox(height: .h),
          // Open Account Button
          Container(
            width: double.maxFinite,
            height: 44.h,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _onOpenAccount(accountType),
                child: Center(
                  child: Text(
                    'Open Account',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.71,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationRow(String label, String value, {int maxLine = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 18.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.38,
            ),
          ),
          SizedBox(
            // height: 40.h,
            width: 130.w,
            child: Text(
              value,
              maxLines: value.toString().split(",").length,
              style: TextStyle(
                fontSize: 14.sp,
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.w500,
                color: AppColors.icongrey,
                height: 1.57,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return DashedUnderline();
    // return Container(height: 1, color: Colors.grey[200]);
  }

  Widget _buildPageIndicator() {
    return Container();
  }

  void _onOpenAccount(PlanModel accountType) {
    // Navigate to the new Pipze account creation screen
    Get.to(
      () => CreatePipzeAccountScreen(
        accountType: accountType.planTitle ?? "",
        isDemo: false,
      ),
    );
  }
}
