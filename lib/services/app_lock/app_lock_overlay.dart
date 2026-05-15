import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/services/app_lock_service.dart';
import 'package:crm_app/services/biometric_service.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/controllers/auth_controller.dart';

class AppLockOverlay extends StatefulWidget {
  const AppLockOverlay({super.key});

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay> {
  bool _autoPromptedForCurrentLock = false;

  @override
  Widget build(BuildContext context) {
    final lockService = Get.find<AppLockService>();
    final languageService = Get.find<LanguageService>();

    return Obx(() {
      if (!lockService.isLocked.value) {
        _autoPromptedForCurrentLock = false;
        return const SizedBox.shrink();
      }

      // Auto-trigger auth prompt once per lock session.
      if (!_autoPromptedForCurrentLock &&
          !lockService.isUnlocking.value &&
          !lockService.authUnavailable.value) {
        _autoPromptedForCurrentLock = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await lockService.unlock(
            reason: languageService.tr('biometric_auth_reason_login'),
          );
        });
      }

      return Positioned.fill(
        child: Material(
          color: AppColors.backgroundLight,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fingerprint_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        languageService.tr('biometric_login'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        if (lockService.authUnavailable.value) {
                          return Text(
                            languageService.tr('biometric_not_enabled_message'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey,
                              height: 1.35,
                            ),
                          );
                        }
                        return Text(
                          languageService.tr('biometric_auth_reason_login'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGrey,
                            height: 1.35,
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      Obx(() {
                        final busy = lockService.isUnlocking.value;
                        final unavailable = lockService.authUnavailable.value;

                        if (busy) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          );
                        }

                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: unavailable
                                    ? () async {
                                        await BiometricService.instance
                                            .openDeviceSecuritySettings();
                                      }
                                    : () async {
                                        await lockService.unlock(
                                          reason: languageService.tr(
                                            'biometric_auth_reason_login',
                                          ),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.whiteColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  unavailable
                                      ? languageService.tr(
                                          'biometric_open_settings',
                                        )
                                      : languageService.tr('navigation_retry'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () async {
                                  // Logout so user can go back to login screen.
                                  try {
                                    await lockService.clearLock();
                                    await Get.find<AuthController>()
                                        .logoutWithOutApi();
                                  } catch (_) {}
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(
                                    color: AppColors.error.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(languageService.tr('more_logout')),
                              ),
                            ),
                            if (unavailable) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await lockService.disableAppLock();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    languageService.tr('common_close'),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

