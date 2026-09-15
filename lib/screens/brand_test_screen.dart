import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crm_app/services/language_service.dart';
import '../../constants/color.dart';
import '../../flavor_config.dart';
import '../../brand_switcher.dart';
import '../../controllers/app_notification_controller.dart';

class BrandTestScreen extends StatelessWidget {
  const BrandTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🎨 ${FlavorConfig.instance.appName} ${languageService.tr('brand_test_title')}',
        ),
        backgroundColor: FlavorConfig.instance.primaryColor,
        foregroundColor: AppColors.whiteColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Brand Info
            Card(
              color: FlavorConfig.instance.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 ${languageService.tr('brand_current')}: ${FlavorConfig.instance.appName}',
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${languageService.tr('brand_app_title')}: ${FlavorConfig.instance.appTitle}',
                      style: TextStyle(color: AppColors.whiteColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Color Samples
            Text(
              '🎨 ${languageService.tr('brand_colors')}:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Primary Color
            _buildColorSample(
              languageService.tr('brand_primary_color'),
              FlavorConfig.instance.primaryColor,
              languageService.tr('brand_primary_color_description'),
            ),

            // Secondary Color
            _buildColorSample(
              languageService.tr('brand_secondary_color'),
              FlavorConfig.instance.secondaryColor,
              languageService.tr('brand_secondary_color_description'),
            ),

            // Accent Color
            _buildColorSample(
              languageService.tr('brand_accent_color'),
              FlavorConfig.instance.accentColor,
              languageService.tr('brand_accent_color_description'),
            ),

            const SizedBox(height: 30),

            // Brand Switching Buttons
            Text(
              '🔄 ${languageService.tr('brand_switch')}:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      BrandSwitcher.switchToPipze();
                      if (Get.isRegistered<AppNotificationController>()) {
                        Get.find<AppNotificationController>().showSuccess(
                          message: languageService.tr(
                            'brand_switched_to_pipze',
                          ),
                          title: languageService.tr('brand_changed'),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F259E),
                      foregroundColor: AppColors.whiteColor,
                    ),
                    child: const Text('🟣 Pipze'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      BrandSwitcher.switchToOcta();
                      if (Get.isRegistered<AppNotificationController>()) {
                        Get.find<AppNotificationController>().showSuccess(
                          message: languageService.tr('brand_switched_to_octa'),
                          title: languageService.tr('brand_changed'),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: AppColors.whiteColor,
                    ),
                    child: const Text('🟠 Octa'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      BrandSwitcher.switchToFleza();
                      if (Get.isRegistered<AppNotificationController>()) {
                        Get.find<AppNotificationController>().showSuccess(
                          message: languageService.tr(
                            'brand_switched_to_fleza',
                          ),
                          title: languageService.tr('brand_changed'),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: AppColors.whiteColor,
                    ),
                    child: const Text('🟢 Fleza'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  BrandSwitcher.quickSwitchBrand();
                  if (Get.isRegistered<AppNotificationController>()) {
                    Get.find<AppNotificationController>().showSuccess(
                      message: languageService.tr('brand_switched_to_next'),
                      title: languageService.tr('brand_quick_switch'),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlavorConfig.instance.primaryColor,
                  foregroundColor: AppColors.whiteColor,
                ),
                child: Text(
                  '🔄 ${languageService.tr('brand_quick_switch_to_next')}',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test using AppColors
            Text(
              '🧪 ${languageService.tr('brand_testing_app_colors')}:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                languageService.tr('brand_primary_color_test'),
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSample(String name, Color color, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
