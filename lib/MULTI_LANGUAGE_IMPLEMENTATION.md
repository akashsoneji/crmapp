# Multi-Language Implementation with RTL Support

This document explains the comprehensive multi-language system implemented in the Pipze Flutter app with secure storage and RTL (Right-to-Left) support.

## Overview

The multi-language system supports:
- **English (en)** - Default language
- **Arabic (ar)** - RTL support
- **Turkish (tr)** - LTR support
- **Hindi (hi)** - LTR support
- **Spanish (es)** - LTR support

## Features

### ✅ Secure Storage
- Language preferences stored securely using `flutter_secure_storage`
- Automatic persistence across app sessions
- Fallback to system language if no preference set

### ✅ RTL Support
- Automatic text direction detection
- Layout adjustments for RTL languages (Arabic)
- Icon mirroring for navigation elements
- Proper alignment and padding adjustments

### ✅ Comprehensive Translations
- 200+ translation keys covering all app features
- Structured JSON files for easy maintenance
- Support for dynamic content with placeholders

### ✅ Easy Integration
- Simple extension methods for translations
- RTL-aware widget wrappers
- Automatic language switching

## File Structure

```
lib/
├── assets/translations/
│   ├── en.json          # English translations
│   ├── ar.json          # Arabic translations (RTL)
│   ├── tr.json          # Turkish translations
│   ├── hi.json          # Hindi translations
│   └── es.json          # Spanish translations
├── services/
│   └── language_service.dart    # Main language service
├── utils/
│   └── rtl_wrapper.dart         # RTL-aware widgets
└── screens/settings/
    └── language_selector_screen.dart  # Language selection UI
```

## Usage Examples

### 1. Basic Translation

```dart
// Simple translation
Text('login_title'.tr)

// Translation with arguments
Text('validation_password_min_length'.trArgs({'min': '8'}))

// Translation with fallback
Text('some_key'.trf('Default text'))
```

### 2. RTL-Aware Widgets

```dart
// Wrap your screen with RTL support
RTLWrapper(
  child: Scaffold(
    // Your content here
  ),
)

// RTL-aware text
RTLText(
  text: 'welcome_title'.tr,
  style: AppTextStyles.heading,
)

// RTL-aware container with automatic padding adjustment
RTLContainer(
  padding: EdgeInsets.all(16),
  child: YourWidget(),
)

// RTL-aware row with automatic alignment
RTLRow(
  children: [
    Icon(Icons.arrow_back),
    Text('Back'),
  ],
)
```

### 3. Language Service Usage

```dart
final languageService = Get.find<LanguageService>();

// Change language
await languageService.changeLanguage('ar');

// Check if current language is RTL
bool isRTL = languageService.isRTL();

// Get current language info
String currentLang = languageService.currentLanguage.value;
String langName = languageService.getCurrentLanguageName();

// Get supported languages
Map<String, String> languages = languageService.getSupportedLanguages();
```

### 4. Language Selection Screen

```dart
// Navigate to language selector
Get.to(() => const LanguageSelectorScreen());

// The screen automatically handles:
// - Language selection
// - RTL layout adjustments
// - Secure storage of preferences
// - Real-time language switching
```

## Translation Keys Structure

The translation files follow a structured approach:

```json
{
  "app_name": "Pipze",
  "welcome_title": "Hi, Welcome! 👋",
  "login_title": "Login",
  "login_subtitle": "Manage your trade with ease",
  "validation_required": "This field is required",
  "toast_login_success": "Login successful! Welcome back! 🎉",
  "dashboard_title": "Dashboard",
  "settings_language_title": "Language",
  "navigation_back": "Back",
  "common_loading": "Loading..."
}
```

## RTL Implementation Details

### Text Direction
- Arabic automatically uses `TextDirection.rtl`
- Other languages use `TextDirection.ltr`
- Automatic detection and application

### Layout Adjustments
- Padding and margin automatically flipped for RTL
- Icon positions adjusted (back button becomes forward)
- Alignment automatically adjusted

### Icon Mirroring
```dart
// Automatic icon mirroring for RTL
RTLIcon(
  icon: Icons.arrow_back_ios,
  onPressed: () => Get.back(),
)
```

## Secure Storage Implementation

### Language Preferences
```dart
// Stored securely using flutter_secure_storage
static const String _languageKey = 'selected_language';
static const String _localeKey = 'selected_locale';

// Automatic encryption and decryption
await _storage.write(key: _languageKey, value: languageCode);
final savedLanguage = await _storage.read(key: _languageKey);
```

### Persistence
- Language choice persists across app restarts
- Automatic fallback to system language
- Secure storage prevents tampering

## Adding New Languages

### 1. Create Translation File
Create `assets/translations/[language_code].json`:

```json
{
  "app_name": "Your App Name",
  "welcome_title": "Welcome message",
  // ... all other keys
}
```

### 2. Update Language Service
Add to `supportedLanguages` map in `language_service.dart`:

```dart
static const Map<String, String> supportedLanguages = {
  'en': 'English',
  'ar': 'العربية',
  'tr': 'Türkçe',
  'hi': 'हिंदी',
  'es': 'Español',
  'new_lang': 'New Language', // Add here
};
```

### 3. Add RTL Support (if needed)
If the language is RTL, add to `rtlLanguages` list:

```dart
static const List<String> rtlLanguages = ['ar', 'new_rtl_lang'];
```

## Best Practices

### 1. Use Translation Keys Consistently
```dart
// ✅ Good
Text('login_title'.tr)
Text('validation_required'.tr)

// ❌ Avoid
Text('Login')
Text('This field is required')
```

### 2. Handle Dynamic Content
```dart
// ✅ Good - with placeholders
Text('validation_password_min_length'.trArgs({'min': '8'}))

// ✅ Good - with fallback
Text('optional_key'.trf('Default text'))
```

### 3. Use RTL Wrappers
```dart
// ✅ Good - RTL-aware
RTLWrapper(child: YourScreen())
RTLText(text: 'Your text')
RTLContainer(padding: EdgeInsets.all(16), child: Widget())

// ❌ Avoid - may break RTL layout
Directionality(textDirection: TextDirection.ltr, child: Widget())
```

### 4. Test RTL Layouts
- Always test with Arabic language
- Verify text alignment and flow
- Check icon positioning
- Ensure proper navigation flow

## Error Handling

### Translation Missing
```dart
// Returns the key if translation not found
String translation = 'missing_key'.tr; // Returns "missing_key"

// With fallback
String translation = 'missing_key'.trf('Default text'); // Returns "Default text"
```

### Language Service Errors
```dart
try {
  await languageService.changeLanguage('invalid_lang');
} catch (e) {
  // Handle unsupported language
  Get.snackbar('Error', 'Unsupported language');
}
```

## Performance Considerations

### Translation Loading
- Translations loaded once at app startup
- Cached in memory for fast access
- No network requests for translations

### RTL Performance
- RTL calculations done at build time
- Minimal runtime overhead
- Efficient widget tree updates

## Testing

### Translation Coverage
```dart
// Get translation statistics
final stats = languageService.getTranslationStats();
print(stats); // Shows missing translations per language

// Validate translations
final errors = languageService.validateTranslations();
print(errors); // Shows validation errors
```

### RTL Testing
```dart
// Test RTL layout
await languageService.changeLanguage('ar');
// Verify layout adjustments

// Test LTR layout
await languageService.changeLanguage('en');
// Verify normal layout
```

## Troubleshooting

### Common Issues

1. **Translation not found**
   - Check if key exists in JSON file
   - Verify JSON syntax
   - Use fallback with `.trf()`

2. **RTL layout issues**
   - Wrap with `RTLWrapper`
   - Use `RTLText` instead of `Text`
   - Use `RTLContainer` for padding adjustments

3. **Language not changing**
   - Check if language code is supported
   - Verify secure storage permissions
   - Check for errors in console

### Debug Information
```dart
// Get current language info
print('Current language: ${languageService.currentLanguage.value}');
print('Is RTL: ${languageService.isRTL()}');
print('Text direction: ${languageService.getTextDirection()}');

// Get all supported languages
print('Supported languages: ${languageService.getSupportedLanguages()}');
```

## Conclusion

This multi-language implementation provides:
- ✅ Complete RTL support for Arabic
- ✅ Secure storage of language preferences
- ✅ Easy-to-use translation system
- ✅ Comprehensive widget wrappers
- ✅ Automatic layout adjustments
- ✅ Support for 5 languages (expandable)
- ✅ Modern UI with proper theming

The system is production-ready and can be easily extended to support additional languages and features. 