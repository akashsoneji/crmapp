import 'package:crm_app/screens/home/more/bonus/scratch_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/screens/home/more/finance/payment_methods_screen.dart';

import '../../../../constants/color.dart';
import '../../../../constants/text_styles.dart';
import '../../../../routes/app_pages.dart';
import '../../../../services/language_service.dart';

class PromotionalScreen extends StatelessWidget {
  const PromotionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: Text(
          languageService.tr('general_promotional'),
          style: AppTextStyles.heading,
        ),
        leading: IconButton(
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MenuItem(
                icon: 'scratch-card',
                label: languageService.tr('general_scratch_card'),
                onTap: () {
                  Get.to(
                    () => const ScratchCardListScreen(),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 300),
                  );
                },
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool showTopBorder;
  final bool showBottomBorder;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.showTopBorder = false,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top:
                showTopBorder
                    ? BorderSide(color: Colors.grey.shade300, width: 1)
                    : BorderSide.none,
            bottom:
                showBottomBorder
                    ? BorderSide(color: Colors.grey.shade300, width: 1)
                    : BorderSide.none,
          ),
        ),
        child: SizedBox(
          height: 56.h,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: 0,
            leading: SvgPicture.asset(
              'assets/svg/more/$icon.svg',
              height: 24.h,
              width: 24.w,
              color: AppColors.primary,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
                color: color,
              ),
            ),
            trailing:
                showBottomBorder
                    ? Icon(
                      Icons.arrow_forward_ios_sharp,
                      size: 14.h,
                      color: AppColors.icongrey,
                    )
                    : null,
            onTap: onTap,
            minLeadingWidth: 10,
            horizontalTitleGap: 8.w,
          ),
        ),
      ),
    );
  }
}
