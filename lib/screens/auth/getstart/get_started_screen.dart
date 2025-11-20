import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/flavor_config.dart';
import 'package:pipze/services/language_service.dart';
import 'get_started_login_option_screen.dart';
import '../../../routes/app_pages.dart';

class GetStartedScreen extends StatelessWidget {
  GetStartedScreen({super.key});
  final LanguageService languageService = Get.find<LanguageService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      // appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 135.h),
              Center(
                child: SvgPicture.asset(
                  FlavorConfig.svgLogoAsset,
                  color: FlavorConfig.isONSA() ? AppColors.primary : null,
                  height: 180.h,
                  width: 180.w,
                  // color: AppColors.primary,
                  // semanticsLabel: 'Pipze Logo',
                ),
              ),
              SizedBox(height: 30.h),
              Text(
                languageService.tr("onboarding_slide1_description"),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(() => GetStartedLoginOptionScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    // padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    languageService.tr("onboarding_get_started"),
                    style: TextStyle(color: AppColors.secondary),
                  ),
                ),
              ),
              SizedBox(height: 15.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Get.toNamed(AppPages.CREATE_ACCOUNT);
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: Text(
                    languageService.tr("register_title"),
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(color: AppColors.textGrey),
                    text: "${languageService.tr("register_terms").tr}\n",
                    children: [
                      TextSpan(
                        text:
                            "${languageService.tr("register_terms_condition").tr}",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                Get.toNamed(AppPages.PRIVACY_POLICY);
                              },
                      ),
                      const TextSpan(text: " and "),
                      TextSpan(
                        text:
                            "${languageService.tr("privacy_policy_title").tr}",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                Get.toNamed(AppPages.PRIVACY_POLICY);
                              },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
