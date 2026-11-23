import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/services/language_service.dart';

/// "Invite friends" referral card shown under the home header.
class InviteBannerCard extends StatelessWidget {
  final VoidCallback onInviteTap;

  const InviteBannerCard({super.key, required this.onInviteTap});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final onCard = AppColors.onColoredBackground;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 16.h, 12.w, 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            AppColors.homeInviteGradientStart,
            AppColors.homeInviteGradientEnd,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageService.tr('home_invite_title'),
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: onCard,
                  ),
                ),
                SizedBox(height: 12.h),
                OutlinedButton(
                  onPressed: onInviteTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onCard,
                    backgroundColor: onCard.withValues(alpha: 0.15),
                    side: BorderSide(color: onCard.withValues(alpha: 0.6)),
                    minimumSize: Size(88.w, 36.h),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    languageService.tr('home_invite_button'),
                    style: AppTextStyles.input.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: onCard,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Placeholder until the wallet illustration asset is delivered.
          ExcludeSemantics(
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 72.sp,
              color: onCard.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
