import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/widgets/brand_logo.dart';
import '../../../routes/app_pages.dart';

class GetStartedScreen extends StatelessWidget {
  GetStartedScreen({super.key});
  final LanguageService languageService = Get.find<LanguageService>();

  Future<bool> _isTenaxBrokerFlowEnabled() async {
    if (!FlavorConfig.isMultiBrokerEnabled) return false;
    return await SecureStorageService.getTenaxBrokerSelectionFlag();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // SizedBox(height: 105.h),
                      Center(
                        child: BrandLogo(
                          source: FlavorConfig.effectiveLogo,
                          color:
                              FlavorConfig.isONSA() &&
                                      !FlavorConfig.hasRemoteLogo
                                  ? AppColors.primary
                                  : null,
                          height: 100.h,
                          width: 180.w,
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Text(
                        languageService.tr("onboarding_slide1_description"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 50.h),
                      SizedBox(
                        width: double.infinity,
                        height: 46.h,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.toNamed(AppPages.LOGIN);
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
                            style: TextStyle(color: AppColors.whiteColor),
                          ),
                        ),
                      ),
                      SizedBox(height: 15.h),
                      SizedBox(
                        width: double.infinity,
                        height: 46.h,
                        child: OutlinedButton(
                          onPressed: () {
                            Get.toNamed(AppPages.CREATE_ACCOUNT);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // padding: const EdgeInsets.all(14),
                          ),
                          child: Text(
                            languageService.tr("register_title"),
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      FutureBuilder<bool>(
                        future: _isTenaxBrokerFlowEnabled(),
                        builder: (context, snapshot) {
                          if (snapshot.data != true) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              TextButton(
                                onPressed: () {
                                  // if (Get.previousRoute ==
                                  //     AppPages.TENAX_BROKER_SELECTION) {
                                  //   Get.back();
                                  // } else {
                                  //   Get.offAllNamed(
                                  //     AppPages.TENAX_BROKER_SELECTION,
                                  //     arguments: {'allowBack': false},
                                  //   );
                                  // }
                                   Get.offAllNamed(
                                    AppPages.TENAX_BROKER_SELECTION,
                                    arguments: {'allowBack': false},
                                  );
                                },
                                child: Text(
                                  "Back to search",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: AppColors.textGrey),
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
                            ..onTap = () async {
                              final brokerData =
                                  await SecureStorageService.getTenaxBrokerSelection();
                              final urlStr =
                                  brokerData?['broker_runtime_config']?['terms_of_use_url']
                                      ?.toString();
                              print("objecturl is $urlStr");
                              if (urlStr != null && urlStr.isNotEmpty) {
                                final uri = Uri.parse(urlStr);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  return;
                                }
                              }
                              Get.toNamed(AppPages.PRIVACY_POLICY);
                            },
                    ),
                    const TextSpan(text: " and "),
                    TextSpan(
                      text: "${languageService.tr("privacy_policy_title").tr}",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () async {
                              final brokerData =
                                  await SecureStorageService.getTenaxBrokerSelection();
                              final urlStr =
                                  brokerData?['broker_runtime_config']?['privacy_policy_url']
                                      ?.toString();
                              if (urlStr != null && urlStr.isNotEmpty) {
                                final uri = Uri.parse(urlStr);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  return;
                                }
                              }
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
    );
  }
}
