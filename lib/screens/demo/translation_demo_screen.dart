import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/utils/rtl_wrapper.dart';

// Import the translation utility to avoid extension conflicts
import 'package:pipze/services/language_service.dart' show TranslationUtils;

/// Demo screen showing how to use the translation system
class TranslationDemoScreen extends StatefulWidget {
  const TranslationDemoScreen({Key? key}) : super(key: key);

  @override
  State<TranslationDemoScreen> createState() => _TranslationDemoScreenState();
}

class _TranslationDemoScreenState extends State<TranslationDemoScreen> {
  final LanguageService _languageService = Get.find<LanguageService>();

  @override
  Widget build(BuildContext context) {
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
            text: TranslationUtils.tr('translation_demo_title'),
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
              // Current language info
              _buildCurrentLanguageInfo(),
              
              const SizedBox(height: 24),
              
              // Language switching section
              _buildLanguageSwitcher(),
              
              const SizedBox(height: 24),
              
              // Translation examples
              _buildTranslationExamples(),
              
              const SizedBox(height: 24),
              
              // RTL examples
              _buildRTLExamples(),
              
              const SizedBox(height: 24),
              
              // Advanced features
              _buildAdvancedFeatures(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLanguageInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RTLText(
            text: 'Current Language Information',
            style: AppTextStyles.heading.copyWith(
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Language Code', _languageService.currentLanguage.value),
          _buildInfoRow('Language Name', _languageService.getCurrentLanguageName()),
          _buildInfoRow('Text Direction', _languageService.isRTL() ? 'RTL' : 'LTR'),
          _buildInfoRow('Locale', _languageService.getCurrentLocale().toString()),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RTLText(
          text: 'Quick Language Switch',
          style: AppTextStyles.heading.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languageService.getSupportedLanguages().entries.map((entry) {
            final isCurrent = entry.key == _languageService.currentLanguage.value;
            return ElevatedButton(
              onPressed: () => _changeLanguage(entry.key),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? AppColors.primary : AppColors.backgroundLight,
                foregroundColor: isCurrent ? Colors.white : AppColors.textPrimary,
                side: BorderSide(
                  color: isCurrent ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(entry.value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTranslationExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RTLText(
          text: 'Translation Examples',
          style: AppTextStyles.heading.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        
        // Basic translation
        _buildTranslationCard(
          'Basic Translation',
          TranslationUtils.tr('welcome_title'),
          'welcome_title',
        ),
        
        // Translation with arguments
        _buildTranslationCard(
          'Translation with Arguments',
          TranslationUtils.trArgs('validation_password_min_length', {'min': '8'}),
          'validation_password_min_length',
        ),
        
        // Translation with fallback
        _buildTranslationCard(
          'Translation with Fallback',
          TranslationUtils.trf('non_existent_key', 'This is a fallback text'),
          'non_existent_key',
        ),
        
        // Plural translation
        _buildTranslationCard(
          'Plural Translation',
          TranslationUtils.trp('items_count', 5),
          'items_count',
        ),
      ],
    );
  }

  Widget _buildRTLExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RTLText(
          text: 'RTL Layout Examples',
          style: AppTextStyles.heading.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        
        // RTL-aware container
        RTLContainer(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: RTLText(
            text: 'This container automatically adjusts padding and margin for RTL languages',
            style: AppTextStyles.subheading,
          ),
        ),
        
        // RTL-aware row
        RTLRow(
          children: [
            RTLIcon(icon: Icons.arrow_back_ios),
            const SizedBox(width: 8),
            RTLText(text: 'Back button automatically mirrors in RTL'),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // RTL-aware list tile
        RTLListTile(
          leading: const Icon(Icons.language),
          title: RTLText(text: 'Language Settings'),
          subtitle: RTLText(text: 'Configure your preferred language'),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ],
    );
  }

  Widget _buildAdvancedFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RTLText(
          text: 'Advanced Features',
          style: AppTextStyles.heading.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        
        // Translation statistics
        ElevatedButton(
          onPressed: _showTranslationStats,
          child: const Text('Show Translation Statistics'),
        ),
        
        const SizedBox(height: 8),
        
        // Validate translations
        ElevatedButton(
          onPressed: _validateTranslations,
          child: const Text('Validate Translations'),
        ),
        
        const SizedBox(height: 8),
        
        // Reset to default
        ElevatedButton(
          onPressed: _resetToDefault,
          child: const Text('Reset to Default Language'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          RTLText(
            text: '$label: ',
            style: AppTextStyles.subheading.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          RTLText(
            text: value,
            style: AppTextStyles.subheading.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationCard(String title, String translation, String key) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
            text: title,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          RTLText(
            text: 'Key: $key',
            style: AppTextStyles.subheading.copyWith(
              color: AppColors.textGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          RTLText(
            text: 'Translation: $translation',
            style: AppTextStyles.subheading.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    try {
      await _languageService.changeLanguage(languageCode);
      Get.snackbar(
        'Success',
        'Language changed to ${_languageService.getCurrentLanguageName()}',
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

  void _showTranslationStats() {
    final stats = _languageService.getTranslationStats();
    String message = 'Translation Statistics:\n\n';
    
    stats.forEach((languageCode, data) {
      message += '${data['language_name']} ($languageCode):\n';
      message += '  Total keys: ${data['total_keys']}\n';
      message += '  Translated: ${data['translated_keys']}\n';
      message += '  Missing: ${data['missing_keys']}\n\n';
    });
    
    Get.dialog(
      AlertDialog(
        title: const Text('Translation Statistics'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _validateTranslations() {
    final errors = _languageService.validateTranslations();
    
    if (errors.isEmpty) {
      Get.snackbar(
        'Success',
        'All translations are valid!',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      String errorMessage = 'Translation validation errors:\n\n';
      for (String error in errors.take(10)) { // Show first 10 errors
        errorMessage += '• $error\n';
      }
      if (errors.length > 10) {
        errorMessage += '\n... and ${errors.length - 10} more errors';
      }
      
      Get.dialog(
        AlertDialog(
          title: const Text('Translation Validation Errors'),
          content: SingleChildScrollView(
            child: Text(errorMessage),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    try {
      await _languageService.resetToDefault();
      Get.snackbar(
        'Success',
        'Language reset to default',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reset language: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
} 