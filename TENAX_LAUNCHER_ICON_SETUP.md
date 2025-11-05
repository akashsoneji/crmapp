# 📱 Tenax Launcher Icon Setup Guide

This guide will help you set up the launcher icon for the **Tenax** flavor, similar to how it's done for other flavors like Fleza, ONSA, etc.

## ✅ What's Already Done

1. ✅ Created `flutter_launcher_icons_tenax.yaml` configuration file
2. ✅ Created Tenax Android directory structure (`android/app/src/tenax/`)
3. ✅ Created AndroidManifest.xml for Tenax
4. ✅ Created values/strings.xml and values/colors.xml for Tenax

## 📋 Step-by-Step Instructions

### Step 1: Create Mipmap Directories

First, create the mipmap directories for Tenax. You can either:

**Option A: Use the PowerShell script (Recommended)**
```powershell
.\setup_launcher_icons.ps1
```

This will create all the required directories:
- `android/app/src/tenax/res/mipmap-mdpi/`
- `android/app/src/tenax/res/mipmap-hdpi/`
- `android/app/src/tenax/res/mipmap-xhdpi/`
- `android/app/src/tenax/res/mipmap-xxhdpi/`
- `android/app/src/tenax/res/mipmap-xxxhdpi/`

**Option B: Create manually**
```powershell
New-Item -ItemType Directory -Path "android\app\src\tenax\res\mipmap-mdpi" -Force
New-Item -ItemType Directory -Path "android\app\src\tenax\res\mipmap-hdpi" -Force
New-Item -ItemType Directory -Path "android\app\src\tenax\res\mipmap-xhdpi" -Force
New-Item -ItemType Directory -Path "android\app\src\tenax\res\mipmap-xxhdpi" -Force
New-Item -ItemType Directory -Path "android\app\src\tenax\res\mipmap-xxxhdpi" -Force
```

### Step 2: Generate Launcher Icons

Run the Flutter Launcher Icons package to generate icons from your logo:

```bash
flutter pub run flutter_launcher_icons -f flutter_launcher_icons_tenax.yaml
```

This will:
- Read the logo from `assets/tenaxCode/App_logo.png`
- Generate icons in all required sizes
- Use the purple color `#4A0C54` as the adaptive icon background
- Place generated icons in `android/app/src/main/res/mipmap-*/`

### Step 3: Copy Icons to Tenax Flavor Directory

After generation, you need to **manually copy** the generated icons from the main directory to the Tenax flavor directory:

**On Windows (PowerShell):**
```powershell
# Copy all mipmap icons from main to tenax
Copy-Item "android\app\src\main\res\mipmap-*\ic_launcher*.png" -Destination "android\app\src\tenax\res\" -Recurse -Force
```

**Or manually copy these files:**
- From: `android/app/src/main/res/mipmap-mdpi/`
  - `ic_launcher.png`
  - `ic_launcher_background.png`
  - `ic_launcher_monochrome.png`
- To: `android/app/src/tenax/res/mipmap-mdpi/`

Repeat for all densities:
- `mipmap-hdpi`
- `mipmap-xhdpi`
- `mipmap-xxhdpi`
- `mipmap-xxxhdpi`

### Step 4: Clean and Rebuild

After copying the icons:

```bash
# Clean Flutter
flutter clean

# Clean Android
cd android
.\gradlew clean
cd ..

# Rebuild with Tenax flavor
flutter pub get
flutter build apk --flavor tenax --release
```

### Step 5: Verify

1. Install the APK on a device
2. Check the launcher icon on the home screen
3. It should show the Tenax logo with purple background

## 🎨 Configuration Details

**Tenax Configuration:**
- **Logo Path**: `assets/tenaxCode/App_logo.png`
- **Background Color**: `#4A0C54` (Purple)
- **App Name**: "Tenax"
- **Primary Color**: `#4A0C54`

## 🔧 Troubleshooting

### Icons Not Appearing?
- Make sure you ran `flutter clean`
- Verify icons are in `android/app/src/tenax/res/mipmap-*/`
- Check that file names are exactly `ic_launcher.png`, `ic_launcher_background.png`, etc.

### Build Errors?
- Make sure all mipmap directories exist
- Verify all icon sizes are present (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- Check that `AndroidManifest.xml` exists in `android/app/src/tenax/`

### Logo Not Found?
- Verify `assets/tenaxCode/App_logo.png` exists
- Check the path in `flutter_launcher_icons_tenax.yaml`
- Make sure the logo is a PNG file (not SVG for launcher icons)

## 📝 Quick Command Summary

```bash
# 1. Create directories (if not done already)
.\setup_launcher_icons.ps1

# 2. Generate icons
flutter pub run flutter_launcher_icons -f flutter_launcher_icons_tenax.yaml

# 3. Copy icons to tenax folder
Copy-Item "android\app\src\main\res\mipmap-*\ic_launcher*.png" -Destination "android\app\src\tenax\res\" -Recurse -Force

# 4. Clean and rebuild
flutter clean
cd android && .\gradlew clean && cd ..
flutter build apk --flavor tenax --release
```

## ✅ Checklist

- [ ] Mipmap directories created for Tenax
- [ ] `flutter_launcher_icons_tenax.yaml` exists and is configured
- [ ] Icons generated using `flutter pub run flutter_launcher_icons`
- [ ] Icons copied to `android/app/src/tenax/res/mipmap-*/`
- [ ] Project cleaned and rebuilt
- [ ] Icon appears correctly on device

---

**Note**: If you need to add Tenax as a product flavor in `build.gradle.kts`, you'll need to add it there as well. Currently, only pipze, octa, fleza, and onsa are defined as product flavors.

