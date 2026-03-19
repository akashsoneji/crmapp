import 'package:crm_app/screens/home/more/bonus/scratch_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/screens/home/more/widgets/more_menu_widgets.dart';
// import 'package:crm_app/screens/home/more/finance/payment_methods_screen.dart';

import '../../../../constants/color.dart';
import '../../../../constants/text_styles.dart';
// import '../../../../routes/app_pages.dart';
import '../../../../services/language_service.dart';

class PromotionalScreen extends StatelessWidget {
  const PromotionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
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
              MoreMenuCardGroup(
                children: [
                  MoreMenuTile(
                    iconName: 'scratch',
                    label: languageService.tr('general_scratch_card'),
                    onTap: () {
                      Get.to(
                        () => const ScratchCardListScreen(),
                        transition: Transition.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                      );
                    },
                    textColor: AppColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
