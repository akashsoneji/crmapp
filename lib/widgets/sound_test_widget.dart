import 'package:crm_app/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chart_controller.dart';
import 'package:crm_app/services/language_service.dart' show TranslationUtils;
import '../controllers/app_notification_controller.dart';

class SoundTestWidget extends StatelessWidget {
  const SoundTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationUtils.tr('sound_test_title')),
        backgroundColor: AppColors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              TranslationUtils.tr('sound_test_audio_playback'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Test No Money Sound Button
            ElevatedButton(
              onPressed: () async {
                try {
                  final controller = Get.put(ChartController());
                  await controller.testNoMoneySound();

                  // Show success message
                  if (Get.isRegistered<AppNotificationController>()) {
                    Get.find<AppNotificationController>().showSuccess(
                      message: TranslationUtils.tr(
                        'sound_test_no_money_completed',
                      ),
                    );
                  }
                } catch (e) {
                  // Show error message
                  if (Get.isRegistered<AppNotificationController>()) {
                    Get.find<AppNotificationController>().showError(
                      message: TranslationUtils.trArgs(
                        'common_error_with_detail',
                        {'error': '$e'},
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: Text(
                TranslationUtils.tr('sound_test_no_money'),
                style: TextStyle(fontSize: 18, color: AppColors.whiteColor),
              ),
            ),

            const SizedBox(height: 20),

            // Instructions
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationUtils.tr('sound_test_instructions'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(TranslationUtils.tr('sound_test_instruction_volume')),
                    Text(TranslationUtils.tr('sound_test_instruction_button')),
                    Text(TranslationUtils.tr('sound_test_instruction_logs')),
                    Text(TranslationUtils.tr('sound_test_instruction_error')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
