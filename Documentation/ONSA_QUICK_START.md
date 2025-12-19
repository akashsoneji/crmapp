# 🚀 ONSA Flavor - Quick Start Guide

## What's Been Added

Your ONSA flavor has been successfully integrated! Here's what you need to do:

## ✅ Completed Setup

- ✅ Created `main_onsa.dart` - Entry point for ONSA
- ✅ Added ONSA to flavor configuration
- ✅ Implemented gradient splash screen (#193FAD to #1E2244)
- ✅ Added Android build configuration
- ✅ Updated all build and run scripts

## 📸 Add Your Logo Image

**REQUIRED STEP:** You need to add your ONSA logo image:

1. Take the logo image you provided
2. Save it as: `assets/image/onsa_logo.png`
3. Make sure it's PNG format with transparency

The splash screen expects the logo at: `assets/image/onsa_logo.png`

## 🏃 How to Run

### Quick Run (PowerShell):
```powershell
.\run_flavor.ps1 onsa
```

### Manual Run:
```bash
flutter run -t lib/main_onsa.dart
```

### Build APK:
```powershell
.\build_flavor.ps1 onsa apk
```

### Build AAB (Play Store):
```powershell
.\build_flavor.ps1 onsa aab
```

## 🎨 What You'll See

- **Splash Screen:** Blue gradient background (diagonal from top-left to bottom-right)
  - Start: `#193FAD` (Bright Blue)
  - End: `#1E2244` (Dark Navy)
- **Theme:** Blue color scheme throughout the app
- **Logo:** Your ONSA logo centered with glow animation

## 🎯 Next Steps

1. **Add Logo:** Place `onsa_logo.png` in `assets/image/` folder
2. **Run:** Execute `.\run_flavor.ps1 onsa`
3. **Test:** Verify splash screen shows your logo with gradient
4. **Build:** Create APK/AAB when ready

## 📋 Summary

Your ONSA flavor is ready! Just add the logo image and you're good to go.

The gradient you requested:
- **Top Left:** `#193FAD` ✅
- **Bottom Right:** `#1E2244` ✅

Both images you provided are ready to be used - just copy the logo image to `assets/image/onsa_logo.png`.

---

**Need Help?** See `ONSA_FLAVOR_SETUP.md` for detailed documentation.

