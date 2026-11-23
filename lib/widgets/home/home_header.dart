import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';

import 'package:crm_app/services/language_service.dart';

/// Purple top bar of the home tab: brand logo, search pill and bell.
///
/// `TradingMainScreen` drops its top `SafeArea` for this tab, so the header
/// adds the status-bar inset itself and the gradient runs under the status bar.
class HomeHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  const HomeHeader({
    super.key,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final onHeader = AppColors.onColoredBackground;

    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        height: HomeHeader.height + topInset,
        padding: EdgeInsetsDirectional.fromSTEB(16.w, topInset, 16.w, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              AppColors.homeHeaderGradientStart,
              AppColors.homeHeaderGradientEnd,
            ],
          ),
        ),
        child: Row(
          children: [
            _BrandLogo(),
            SizedBox(width: 10.w),
            Expanded(
              child: Semantics(
                button: true,
                label: languageService.tr('home_search_hint'),
                excludeSemantics: true,
                child: InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    height: 40.h,
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: onHeader.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: onHeader.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/new_svg/search-normal.svg',
                          width: 20.r,
                          height: 20.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            languageService.tr('home_search_hint'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subheading.copyWith(
                              fontSize: 14.sp,
                              color: onHeader.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            IconButton(
              onPressed: onNotificationTap,
              tooltip: languageService.tr('home_notifications'),
              icon: SvgPicture.asset(
                'assets/svg/new_svg/bell.svg',
                width: 24.r,
                height: 24.r,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double get height => 64.h;
}

class _BrandLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // The design asset already includes the translucent circle behind the mark.
    return ExcludeSemantics(
      child: SvgPicture.asset(
        'assets/svg/new_svg/home_logo.svg',
        width: 40.r,
        height: 40.r,
      ),
    );
  }
}
