# iOS App Icon Not Aligning with Flavor - Fix Guide

## Problem
The app icon is not updating correctly when switching between flavors on iOS.

## Root Cause
The `update_ios_flavor.sh` script was being called without the flavor parameter in some cases, causing it to read the flavor from `main.dart` instead of using the actual flavor being run.

## Solution Applied

### 1. Fixed Scripts to Pass Flavor Parameter
All scripts now pass the flavor parameter to `update_ios_flavor.sh`:
- ✅ `smart_run.sh` - Removed duplicate call, now only calls with flavor
- ✅ `prepare_flutter_run.sh` - Now passes detected flavor
- ✅ `setup_and_prepare_flavor.sh` - Now passes detected flavor
- ✅ `flutter_pre_build.sh` - Now tries to detect flavor from environment or main.dart

### 2. Icon Mapping
Current icon mappings:
- `profx` → `profx_app_icon` ✅
- `onsa` → `onsa_app_icon` ✅
- `tenax` → `tenax_app_icon` ✅
- `pipze` → `AppIcon` (default - no custom icon set yet)
- `octa` → `AppIcon` (default - no custom icon set yet)
- `fleza` → `AppIcon` (default - no custom icon set yet)
- `afx` → `AppIcon` (default - no custom icon set yet)

## How to Use

### Method 1: Use the dedicated script (Recommended)
```bash
bash scripts/run_ios_flavor.sh profx
```
This script:
1. Updates iOS config with the correct flavor
2. Detects iOS simulator
3. Runs with the correct icon

### Method 2: Manual update then run
```bash
# Step 1: Update icon for your flavor
bash scripts/update_ios_flavor.sh profx

# Step 2: Clean and rebuild
bash scripts/clean_ios_build.sh

# Step 3: Delete app from simulator/device

# Step 4: Run
flutter run --dart-define=FLAVOR=profx -d <device>
```

## Verification Steps

1. **Check project file is updated:**
   ```bash
   grep "ASSETCATALOG_COMPILER_APPICON_NAME" ios/Runner.xcodeproj/project.pbxproj
   ```
   Should show your flavor's icon (e.g., `profx_app_icon`)

2. **Check icon asset exists:**
   ```bash
   ls -la ios/Runner/Assets.xcassets/profx_app_icon.appiconset/
   ```

3. **Clean and rebuild:**
   ```bash
   bash scripts/clean_ios_build.sh
   ```

4. **Delete app from simulator/device** (important - iOS caches icons)

5. **Rebuild and run**

## Troubleshooting

If icon still doesn't update:

1. **Verify the project file was updated:**
   ```bash
   grep "ASSETCATALOG_COMPILER_APPICON_NAME" ios/Runner.xcodeproj/project.pbxproj
   ```
   All 3 occurrences should show your flavor's icon name.

2. **Open Xcode and verify:**
   - Open `ios/Runner.xcworkspace`
   - Select Runner target
   - Build Settings → Search "Asset Catalog App Icon Set Name"
   - Should show your flavor's icon (e.g., `profx_app_icon`)

3. **Reset simulator completely:**
   ```bash
   xcrun simctl erase all
   ```

4. **Clean Xcode derived data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

5. **Rebuild from scratch:**
   ```bash
   bash scripts/clean_ios_build.sh
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter run --dart-define=FLAVOR=profx -d <device>
   ```

## Important Notes

- **iOS caches app icons aggressively** - You MUST delete the app from simulator/device before rebuilding
- The icon update happens in the Xcode project file, so Xcode needs to recognize the change
- If you're using Xcode directly, make sure to close and reopen the project after the script runs
- The icon asset catalog must exist in `ios/Runner/Assets.xcassets/<icon_name>.appiconset/`

