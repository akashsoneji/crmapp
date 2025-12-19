# ONSA Flavor Setup Guide 🚀

## Overview
The ONSA flavor has been successfully integrated into your Flutter project with a beautiful blue gradient theme.

## 🎨 Theme Configuration

**Colors:**
- Primary Color: `#193FAD` (Top Left - Bright Blue)
- Secondary Color: `#1E2244` (Bottom Right - Dark Navy)
- Accent Color: `#193FAD` (Bright Blue)

**Gradient Background:**
The splash screen uses a diagonal gradient from top-left to bottom-right:
- Starting Color: `#193FAD` (Bright Blue)
- Ending Color: `#1E2244` (Dark Navy)

## 📁 Files Created/Modified

### Dart Files:
1. ✅ `lib/main_onsa.dart` - Main entry point for ONSA flavor
2. ✅ `lib/flavor_config.dart` - Added ONSA configuration
3. ✅ `lib/constants/app_config.dart` - Added ONSA brand config
4. ✅ `lib/brand_switcher.dart` - Added ONSA brand switching
5. ✅ `lib/screens/auth/splash/splash_screen.dart` - Added gradient support

### Android Files:
1. ✅ `android/app/build.gradle.kts` - Added ONSA product flavor
2. ✅ `android/app/src/onsa/AndroidManifest.xml` - ONSA manifest
3. ✅ `android/app/src/onsa/res/values/colors.xml` - ONSA colors
4. ✅ `android/app/src/onsa/res/values/strings.xml` - ONSA strings

### Build Scripts:
1. ✅ `build_flavor.ps1` - Added ONSA build support
2. ✅ `run_flavor.ps1` - Added ONSA run support

## 📸 Adding ONSA Logo Images

You need to add your ONSA logo images to the assets folder. The splash screen is looking for:
- **File Path:** `assets/image/onsa_logo.png`

### Steps to Add Logo:

1. **Prepare Your Logo Image:**
   - Save your ONSA logo as PNG format
   - Recommended size: 512x512 pixels or higher
   - Transparent background preferred
   - File name: `onsa_logo.png`

2. **Copy to Assets Folder:**
   ```
   Copy the onsa_logo.png file to:
   assets/image/onsa_logo.png
   ```

3. **Image Requirements:**
   - Format: PNG (with transparency)
   - Size: 512x512 or larger
   - Content: ONSA logo (white/gray color works best on blue gradient)

## 🚀 Running ONSA Flavor

### Using PowerShell Script:
```powershell
# Run ONSA flavor
.\run_flavor.ps1 onsa

# Build ONSA APK
.\build_flavor.ps1 onsa apk

# Build ONSA AAB (for Play Store)
.\build_flavor.ps1 onsa aab
```

### Using Flutter Commands:
```bash
# Run ONSA flavor
flutter run -t lib/main_onsa.dart

# Build APK
flutter build apk --flavor onsa --release

# Build AAB
flutter build appbundle --flavor onsa --release
```

## 🎯 Current Status

✅ Flavor configuration added  
✅ Android build configuration added  
✅ Splash screen gradient implemented  
✅ Brand switcher updated  
✅ Build scripts updated  
⏳ **PENDING:** Add `onsa_logo.png` to `assets/image/` folder

## 🔧 Next Steps

1. **Add Logo Image:**
   - Place your ONSA logo at `assets/image/onsa_logo.png`
   - Run `flutter pub get` to regenerate assets

2. **Test the Flavor:**
   ```powershell
   .\run_flavor.ps1 onsa
   ```

3. **Customize (Optional):**
   - Update API base URL in `flavor_config.dart` if needed
   - Adjust colors if desired
   - Update app name in Android resources

## 📝 Notes

- The ONSA splash screen uses a gradient background instead of solid color
- Logo should be white or light colored for best visibility on blue gradient
- The gradient direction is from top-left to bottom-right
- All existing features work with ONSA flavor automatically

## 🎨 Visual Preview

The splash screen will display:
- **Background:** Blue diagonal gradient (bright to dark navy)
- **Logo:** ONSA logo centered with glow animation
- **Colors:** Theme uses blue color scheme throughout

---

**Tip:** After adding your logo image, run `flutter pub get` and then test with `.\run_flavor.ps1 onsa`

