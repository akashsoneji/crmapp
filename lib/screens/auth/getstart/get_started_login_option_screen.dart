import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/widgets/brand_logo.dart';
import 'package:crm_app/widgets/social_button.dart';
import '../../../routes/app_pages.dart';

class GetStartedLoginOptionScreen extends StatelessWidget {
  GetStartedLoginOptionScreen({super.key});
  final LanguageService languageService = Get.find<LanguageService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: 135.h),
                      Center(
                        child: BrandLogo(
                          source: FlavorConfig.effectiveLogo,
                          height: 130.h,
                          width: 130.w,
                          color:
                              FlavorConfig.isONSA() &&
                                      !FlavorConfig.hasRemoteLogo
                                  ? AppColors.primary
                                  : null,
                        ),
                      ),
                      SizedBox(height: 50.h),
                      Text(
                        languageService.tr("welcome_login_title"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27.sp,
                          height: 34 / 27,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        languageService.tr("login_subtitle"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17.sp,
                          height: 24 / 17,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textGrey,
                        ),
                      ),
                      SizedBox(height: 50.h),
                      // SocialButton(
                      //   label: languageService.tr('login_google'),
                      //   icon: 'assets/svg/GoogleLogo.svg',
                      //   onPressed: () {
                      //     Get.toNamed(AppPages.LOGIN);
                      //   },
                      // ),
                      // const SizedBox(height: 12),
                      // SocialButton(
                      //   label: languageService.tr('login_apple'),
                      //   icon: 'assets/svg/apple_logo.svg',
                      //   onPressed: () {},
                      // ),
                      // const SizedBox(height: 12),
                      SocialButton(
                        label: languageService.tr('login_email'),
                        icon: 'assets/svg/emailLogo.svg',
                        onPressed: () {
                          Get.toNamed(AppPages.LOGIN);
                        },
                      ),
                      SizedBox(height: 30.h),
                      const Spacer(),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Get.toNamed(AppPages.LOGIN);
                          },
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(color: AppColors.textGrey),
                              text:
                                  "${languageService.tr("login_no_account")} ",
                              children: [
                                TextSpan(
                                  text:
                                      " ${languageService.tr("login_button")}",
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
