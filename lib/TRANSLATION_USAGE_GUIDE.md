# Translation System Usage Guide

## Overview

This guide explains how to use the multi-language translation system in the Pipze app without conflicts.

## ✅ **Recommended Approach: Use TranslationUtils**

To avoid extension conflicts, use the `TranslationUtils` class directly:

```dart
import 'package:pipze/services/language_service.dart' show TranslationUtils;

// ✅ Correct way to use translations
Text(TranslationUtils.tr('welcome_title'))
Text(TranslationUtils.trArgs('validation_password_min_length', {'min': '8'}))
Text(TranslationUtils.trf('optional_key', 'Default text'))
Text(TranslationUtils.trp('items_count', 5))
```

## ❌ **Avoid Extension Conflicts**

The extension approach may conflict with GetX's built-in translation system:

```dart
// ❌ May cause conflicts
Text('welcome_title'.tr)
Text('key'.trArgs({'arg': 'value'}))
```

## Complete Example Screen

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pipze/services/language_service.dart' show TranslationUtils;
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/utils/rtl_wrapper.dart';

class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(TranslationUtils.tr('screen_title')),
          leading: IconButton(
            icon: RTLIcon(icon: Icons.arrow_back_ios),
            onPressed: () => Get.back(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Basic translation
              Text(
                TranslationUtils.tr('welcome_message'),
                style: AppTextStyles.heading,
              ),
              
              const SizedBox(height: 16),
              
              // Translation with arguments
              Text(
                TranslationUtils.trArgs(
                  'validation_min_length', 
                  {'min': '8'}
                ),
                style: AppTextStyles.subheading,
              ),
              
              const SizedBox(height: 16),
              
              // Translation with fallback
              Text(
                TranslationUtils.trf(
                  'optional_key', 
                  'Default text if key not found'
                ),
                style: AppTextStyles.body,
              ),
              
              const SizedBox(height: 16),
              
              // RTL-aware container
              RTLContainer(
                padding: const EdgeInsets.all(16),
                child: Text(
                  TranslationUtils.tr('container_text'),
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Language Switching

```dart
import 'package:pipze/services/language_service.dart';

class LanguageController {
  final LanguageService _languageService = Get.find<LanguageService>();
  
  Future<void> changeLanguage(String languageCode) async {
    try {
      await _languageService.changeLanguage(languageCode);
      Get.snackbar(
        'Success',
        'Language changed successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to change language: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
  
  bool isRTL() => _languageService.isRTL();
  String getCurrentLanguage() => _languageService.currentLanguage.value;
}
```

## RTL Support

### Using RTL Wrappers

```dart
// Wrap your screen with RTL support
RTLWrapper(
  child: Scaffold(
    // Your content
  ),
)

// RTL-aware text
RTLText(
  text: TranslationUtils.tr('your_text'),
  style: AppTextStyles.heading,
)

// RTL-aware container with automatic padding adjustment
RTLContainer(
  padding: const EdgeInsets.all(16),
  child: YourWidget(),
)

// RTL-aware row with automatic alignment
RTLRow(
  children: [
    RTLIcon(icon: Icons.arrow_back_ios),
    Text('Back'),
  ],
)
```

## Translation Keys Structure

All translation keys should be defined in the JSON files:

```json
{
  "app_name": "Pipze",
  "welcome_title": "Hi, Welcome! 👋",
  "login_title": "Login",
  "validation_required": "This field is required",
  "validation_password_min_length": "Password must be at least {min} characters",
  "navigation_back": "Back",
  "common_loading": "Loading..."
}
```

## Best Practices

### 1. **Always Use TranslationUtils**
```dart
// ✅ Good
Text(TranslationUtils.tr('key'))

// ❌ Avoid (may cause conflicts)
Text('key'.tr)
```

### 2. **Use RTL Wrappers for Layout**
```dart
// ✅ Good
RTLWrapper(child: YourScreen())
RTLText(text: TranslationUtils.tr('text'))
RTLContainer(padding: EdgeInsets.all(16), child: Widget())

// ❌ Avoid
Directionality(textDirection: TextDirection.ltr, child: Widget())
```

### 3. **Handle Missing Translations**
```dart
// ✅ Good - with fallback
Text(TranslationUtils.trf('optional_key', 'Default text'))

// ✅ Good - check if translation exists
final translation = TranslationUtils.tr('key');
if (translation != 'key') {
  // Translation found
}
```

### 4. **Use Arguments for Dynamic Content**
```dart
// ✅ Good
Text(TranslationUtils.trArgs('welcome_user', {'name': userName}))

// JSON: "welcome_user": "Welcome, {name}!"
```

## Available Methods

### TranslationUtils Class

```dart
// Basic translation
TranslationUtils.tr('key')

// Translation with arguments
TranslationUtils.trArgs('key', {'arg': 'value'})

// Translation with fallback
TranslationUtils.trf('key', 'fallback text')

// Plural translation
TranslationUtils.trp('key', count)
```

### LanguageService Methods

```dart
final languageService = Get.find<LanguageService>();

// Change language
await languageService.changeLanguage('ar');

// Check RTL
bool isRTL = languageService.isRTL();

// Get current language
String currentLang = languageService.currentLanguage.value;

// Get supported languages
Map<String, String> languages = languageService.getSupportedLanguages();
```

## Troubleshooting

### Extension Conflicts
If you see errors like:
```
A member named 'tr' is defined in 'extension Trans on String' and 'extension PipzeTranslationExtension on String'
```

**Solution**: Use `TranslationUtils.tr()` instead of the extension method.

### Missing Translations
If a translation key is missing:
```dart
// Returns the key itself if translation not found
String result = TranslationUtils.tr('missing_key'); // Returns "missing_key"

// With fallback
String result = TranslationUtils.trf('missing_key', 'Default text'); // Returns "Default text"
```

### RTL Layout Issues
If RTL layout is not working properly:
1. Make sure you're using `RTLWrapper` for the screen
2. Use `RTLText` instead of `Text`
3. Use `RTLContainer` for padding adjustments
4. Use `RTLIcon` for icons that should mirror in RTL

## Testing

### Test Different Languages
```dart
// Test English
await languageService.changeLanguage('en');

// Test Arabic (RTL)
await languageService.changeLanguage('ar');

// Test Turkish
await languageService.changeLanguage('tr');
```

### Validate Translations
```dart
final errors = languageService.validateTranslations();
if (errors.isNotEmpty) {
  print('Translation errors: $errors');
}
```

## Summary

- ✅ Use `TranslationUtils.tr()` for translations
- ✅ Use RTL wrapper widgets for layout
- ✅ Handle missing translations with fallbacks
- ✅ Test with different languages
- ❌ Avoid extension methods that may conflict
- ❌ Don't hardcode text strings

This approach ensures a robust, conflict-free translation system that works across all supported languages including RTL support for Arabic. 