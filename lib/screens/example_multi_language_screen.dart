import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/utils/rtl_wrapper.dart';

class ExampleMultiLanguageScreen extends StatelessWidget {
  const ExampleMultiLanguageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    return RTLWrapper(
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: RTLIcon(
              icon: Icons.arrow_back_ios,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Get.back(),
          ),
          title: RTLText(
            text: 'settings_language_title'.tr,
            style: AppTextStyles.heading.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              RTLContainer(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RTLText(
                      text: 'welcome_title'.tr,
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RTLText(
                      text: 'welcome_subtitle'.tr,
                      style: AppTextStyles.subheading.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Language info section
              RTLContainer(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RTLText(
                      text: 'Current Language Information',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Language Code',
                      languageService.currentLanguage.value,
                    ),
                    _buildInfoRow(
                      'Language Name',
                      languageService.getCurrentLanguageName(),
                    ),
                    _buildInfoRow(
                      'Text Direction',
                      languageService.isRTL() ? 'RTL' : 'LTR',
                    ),
                    _buildInfoRow(
                      'Locale',
                      languageService.getCurrentLocale().toString(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Translation examples
              RTLText(
                text: 'Translation Examples',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildTranslationExample('login_title', 'login_title'.tr),
              _buildTranslationExample('register_title', 'register_title'.tr),
              _buildTranslationExample('dashboard_title', 'dashboard_title'.tr),
              _buildTranslationExample('settings_title', 'settings_title'.tr),

              const SizedBox(height: 24),

              // Language selector
              RTLText(
                text: 'Change Language',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              ...languageService.getSupportedLanguages().entries.map(
                (entry) => _buildLanguageOption(entry.key, entry.value),
              ),

              const SizedBox(height: 24),

              // RTL specific examples
              if (languageService.isRTL())
                RTLContainer(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RTLText(
                        text: 'RTL Layout Active',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RTLText(
                        text:
                            'This section shows RTL-specific content and layout adjustments.',
                        style: AppTextStyles.subheading.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Action buttons
              RTLRow(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showLanguageDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: RTLText(
                        text: 'Change Language',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showTranslationStats(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                      ),
                      child: RTLText(
                        text: 'Translation Stats',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RTLRow(
        children: [
          RTLText(
            text: '$label:',
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          RTLText(
            text: value,
            style: AppTextStyles.subheading.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationExample(String key, String translation) {
    return RTLContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RTLText(
            text: 'Key: $key',
            style: AppTextStyles.subheading.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          RTLText(text: translation, style: AppTextStyles.label),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    final languageService = Get.find<LanguageService>();
    final isCurrent = languageService.currentLanguage.value == code;

    return RTLContainer(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: RTLText(
              text: _getLanguageFlag(code),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: RTLText(
          text: name,
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: RTLText(
          text:
              languageService.getLanguageInfo(code)['isRTL']
                  ? 'RTL Layout'
                  : 'LTR Layout',
          style: AppTextStyles.subheading.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing:
            isCurrent
                ? Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                )
                : null,
        onTap: () => _changeLanguage(code),
      ),
    );
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇺🇸';
      case 'ar':
        return '🇸🇦';
      case 'tr':
        return '🇹🇷';
      case 'hi':
        return '🇮🇳';
      case 'es':
        return '🇪🇸';
      default:
        return '🌐';
    }
  }

  void _changeLanguage(String languageCode) async {
    try {
      final languageService = Get.find<LanguageService>();
      await languageService.changeLanguage(languageCode);

      Get.snackbar(
        'Success',
        'Language changed to ${languageService.getCurrentLanguageName()}',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to change language: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _showLanguageDialog() {
    final languageService = Get.find<LanguageService>();
    final languages = languageService.getSupportedLanguages();

    Get.dialog(
      AlertDialog(
        title: RTLText(text: 'Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              languages.entries.map((entry) {
                return ListTile(
                  leading: RTLText(text: _getLanguageFlag(entry.key)),
                  title: RTLText(text: entry.value),
                  onTap: () {
                    Get.back();
                    _changeLanguage(entry.key);
                  },
                );
              }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: RTLText(text: 'Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTranslationStats() {
    final languageService = Get.find<LanguageService>();
    final stats = languageService.getTranslationStats();

    Get.dialog(
      AlertDialog(
        title: RTLText(text: 'Translation Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              stats.entries.map((entry) {
                final data = entry.value as Map<String, dynamic>;
                return ListTile(
                  title: RTLText(text: entry.key.toUpperCase()),
                  subtitle: RTLText(
                    text:
                        'Total: ${data['total_keys']}, Translated: ${data['translated_keys']}, Missing: ${data['missing_keys']}',
                  ),
                );
              }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: RTLText(text: 'Close'),
          ),
        ],
      ),
    );
  }
}
