import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/trade_win/trade_win_controller.dart';
import 'package:crm_app/models/trade_win/trade_win_past_win_model.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/utils/trade_win_format.dart';
import 'package:crm_app/screens/trade_win/widgets/trade_win_product_image.dart';
import 'package:crm_app/screens/trade_win/widgets/trade_win_status_badge.dart';

class TradeWinMyWinsTab extends StatelessWidget {
  const TradeWinMyWinsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final controller = Get.find<TradeWinController>();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: SvgPicture.asset(
                  'assets/svg/trade/arro_back.svg',
                  colorFilter: ColorFilter.mode(
                    AppColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  languageService.tr('tw_my_past_wins'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading,
                ),
              ),
              SizedBox(width: 48.w),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final wins = controller.pastWins;
            if (wins.isEmpty) {
              return Center(
                child: Text(
                  languageService.tr('tw_no_past_wins'),
                  style: AppTextStyles.subheading,
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
              itemCount: wins.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) => _PastWinCard(
                win: wins[index],
                languageService: languageService,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PastWinCard extends StatelessWidget {
  final TradeWinPastWinModel win;
  final LanguageService languageService;

  const _PastWinCard({required this.win, required this.languageService});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.icongrey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TradeWinProductImage(
                imagePath: win.imagePath,
                width: 64.w,
                height: 64.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            win.productName,
                            style: AppTextStyles.headingblack,
                          ),
                        ),
                        TradeWinStatusBadge(status: win.status),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      TradeWinFormat.categoryLabel(win.category),
                      style: AppTextStyles.subheading.copyWith(
                        color: AppColors.primary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '${languageService.tr('tw_reference')}: ${win.referenceCode}',
            style: AppTextStyles.label.copyWith(fontSize: 13.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            '${languageService.tr('tw_submitted')}: ${win.claimDate}',
            style: AppTextStyles.subheading.copyWith(fontSize: 12.sp),
          ),
          Divider(height: 20.h, color: AppColors.icongrey.withValues(alpha: 0.2)),
          InkWell(
            onTap: () => Get.toNamed(
              AppPages.TRADE_WIN_PAST_WIN_DETAIL,
              arguments: {'win': win},
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageService.tr('tw_view_details'),
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.primary, size: 20.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
