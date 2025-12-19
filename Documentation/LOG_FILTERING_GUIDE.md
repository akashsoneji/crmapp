# Log Filtering Guide

This guide explains how to suppress WebView and GPU system logs that appear in your console.

## What Was Implemented

### 1. Native Android Suppression ✅
Enhanced `MainActivity.kt` to suppress logs at the Android system level:
- `I/View: setRequestedFrameRate` logs
- `W/ImageReader_JNI: Unable to acquire a buffer item` warnings
- `E/GPUAUX: [AUX]GuiExtAuxCheckAuxPath` errors

**Note**: After making these changes, rebuild your app:
```bash
flutter clean
flutter pub get
flutter run
```

### 2. VS Code/Cursor Debug Console Filtering ✅

The Debug Console in VS Code/Cursor has a built-in filter box at the top (visible in your screenshot).

**To filter logs:**
1. Click in the filter box at the top of the Debug Console
2. Enter: `!setRequestedFrameRate !ImageReader_JNI !GPUAUX`
3. This will hide all logs containing these patterns

The `!` prefix means "exclude" - so `!setRequestedFrameRate` hides any log containing "setRequestedFrameRate".

### 3. Android Studio Logcat Filtering ✅

**Option 1: Quick Filter (Temporary)**
1. Open Logcat in Android Studio
2. In the search box, type: `!setRequestedFrameRate !ImageReader_JNI !GPUAUX`
3. This filters logs temporarily while you're viewing

**Option 2: Create Permanent Filter (Recommended)**
1. Open Logcat in Android Studio
2. Click the filter dropdown (funnel icon) at the top
3. Click "Edit Filter Configuration"
4. Click the "+" button to add a new filter
5. Configure as follows:
   - **Name**: `Hide WebView Noise`
   - **Log Tag**: `^(?!.*(View|ImageReader_JNI|GPUAUX)).*$`
   - **Log Level**: `Verbose` (to catch all levels)
6. Click OK
7. Select "Hide WebView Noise" from the filter dropdown

**Option 3: Use Filter File**
See `android_studio_logcat_filters.xml` for XML configuration examples (manual import required).

## Quick Reference

### Filter Patterns for Debug Console/Logcat:
```
!setRequestedFrameRate !ImageReader_JNI !GPUAUX
```

### Regex Pattern for Android Studio:
```
^(?!.*(View|ImageReader_JNI|GPUAUX)).*$
```

## Testing

After rebuilding the app with the MainActivity changes:
1. Run the app
2. Check Android Studio Logcat - logs should be significantly reduced
3. Check Cursor Debug Console - use the filter box if any logs still appear

## Troubleshooting

If logs still appear:
1. **Make sure you rebuilt the app** after MainActivity.kt changes
2. **Use the filter box** in Debug Console (Cursor/VS Code)
3. **Create a filter** in Android Studio Logcat
4. The native suppression reduces logs at the source, but some may still appear in development consoles

## Notes

- Native suppression works at the Android system level and affects all console outputs
- IDE filters provide an additional layer for development environments
- Some logs may still appear occasionally, but should be significantly reduced

