# How to Setup Flavor-Specific Launcher Icons

This guide will help you set up different app launcher icons for each brand/flavor (Pipze, Octa, Fleza, ONSA).

## Overview
Each Android flavor needs its own launcher icon resources in the res/mipmap directories.

## Step-by-Step Process

### Step 1: Prepare Your Icon Images

You need PNG images in different sizes for each flavor:

#### Required Sizes:
- **mipmap-mdpi**: 48x48 px
- **mipmap-hdpi**: 72x72 px
- **mipmap-xhdpi**: 96x96 px
- **mipmap-xxhdpi**: 144x144 px
- **mipmap-xxxhdpi**: 192x192 px

#### Icon Images for Each Flavor:
- **ONSA**: ONSA logo (blue theme)
- **Pipze**: Purple logo
- **Octa**: Orange logo  
- **Fleza**: Green logo

### Step 2: Create Folder Structure

Create mipmap directories for each flavor:

```
android/app/src/
├── onsa/res/
│   └── mipmap-mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi/
│       ├── ic_launcher.png
│       ├── ic_launcher_background.png
│       └── ic_launcher_monochrome.png
├── pipze/res/
│   └── mipmap-mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi/
│       └── ic_launcher.png
├── octa/res/
│   └── mipmap-mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi/
│       └── ic_launcher.png
└── fleza/res/
    └── mipmap-mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi/
        └── ic_launcher.png
```

### Step 3: Use Flutter Launcher Icons Package (Easiest Method)

#### Option A: Automated Generation (Recommended)

Create a configuration file for each flavor:

**For ONSA**:
```yaml
# flutter_launcher_icons_onsa.yaml
flutter_launcher_icons:
  android: true
  image_path: "assets/image/onsa_logo.png"  # Your ONSA logo
  min_sdk_android: 21
  adaptive_icon_background: "#193FAD"  # ONSA blue
  adaptive_icon_foreground: "assets/image/onsa_logo.png"
```

**For Octa**:
```yaml
# flutter_launcher_icons_octa.yaml
flutter_launcher_icons:
  android: true
  image_path: "assets/image/octa_logo.png"  # Your Octa logo
  min_sdk_android: 21
  adaptive_icon_background: "#FF6B35"  # Octa orange
  adaptive_icon_foreground: "assets/image/octa_logo.png"
```

**For Fleza**:
```yaml
# flutter_launcher_icons_fleza.yaml
flutter_launcher_icons:
  android: true
  image_path: "assets/image/fleza_logo.png"  # Your Fleza logo
  min_sdk_android: 21
  adaptive_icon_background: "#4CAF50"  # Fleza green
  adaptive_icon_foreground: "assets/image/fleza_logo.png"
```

**For Pipze**:
```yaml
# flutter_launcher_icons_pipze.yaml
flutter_launcher_icons:
  android: true
  image_path: "assets/image/splash_logo.png"
  min_sdk_android: 21
  adaptive_icon_background: "#5F259E"  # Pipze purple
  adaptive_icon_foreground: "assets/image/splash_logo.png"
```

#### Option B: Manual Method

1. **Export your logo as PNG** at 1024x1024 px with transparent background
2. **Use an icon generator** like:
   - https://icon.kitchen
   - https://www.npmjs.com/package/app-icon
   - Or any Android icon generator

3. **Place the generated icons** in the appropriate mipmap folders

### Step 4: Generate Icons for Each Flavor

Run these commands:

```bash
# For ONSA
flutter pub run flutter_launcher_icons -f flutter_launcher_icons_onsa.yaml

# For Octa  
flutter pub run flutter_launcher_icons -f flutter_launcher_icons_octa.yaml

# For Fleza
flutter pub run flutter_launcher_icons -f flutter_launcher_icons_fleza.yaml

# For Pipze
flutter pub run flutter_launcher_icons -f flutter_launcher_icons_pipze.yaml
```

⚠️ **Important**: You need to **manually copy** the generated icons from `android/app/src/main/res/mipmap-*/` to each flavor's directory:
- `android/app/src/onsa/res/mipmap-*/`
- `android/app/src/pipze/res/mipmap-*/`
- `android/app/src/octa/res/mipmap-*/`
- `android/app/src/fleza/res/mipmap-*/`

### Step 5: Update AndroidManifest (Optional)

If you want different icon names for each flavor:

```xml
<!-- In android/app/src/onsa/AndroidManifest.xml -->
<application
    android:icon="@mipmap/ic_launcher_onsa"
    ...>
```

Then create `ic_launcher_onsa.png` in the mipmap folders.

However, **you don't need to modify the manifest** if you just use `ic_launcher.png` in each flavor's directory - Android will automatically use the flavor-specific icon.

### Step 6: Clean and Rebuild

After setting up the icons:

```bash
# Clean Flutter
flutter clean

# Clean Android
cd android && ./gradlew clean && cd ..

# Rebuild
flutter pub get
flutter build apk --flavor onsadb
# or whichever flavor you're building
```

## Quick Manual Setup (If You Have the PNG Files)

### For ONSA:

1. Create these directories if they don't exist:
   ```
   android/app/src/onsa/res/mipmap-mdpi/
   android/app/src/onsa/res/mipmap-hdpi/
   android/app/src/onsa/res/mipmap-xhdpi/
   android/app/src/onsa/res/mipmap-xxhdpi/
   android/app/src/onsa/res/mipmap-xxxhdpi/
   ```

2. Place your ONSA logo icons (PNG format) in each folder:
   - Name them `ic_launcher.png`
   - Use the correct size for each density

3. That's it! When you build the ONSA flavor, it will use these icons.

## Verification

To verify your setup:

1. Build the app with a specific flavor:
   ```bash
   flutter build apk --flavor onsadb
   ```

2. Install the APK on a device

3. Check the launcher icon on the home screen - it should show your brand's logo

## Troubleshooting

### Icons Not Changing?
- Make sure you cleaned the project (`flutter clean`)
- Make sure icons are in the correct flavor folder (`android/app/src/onsa/res/mipmap-*/`)
- Rebuild the app completely

### Icon Appears Blurry?
- Make sure you're using the correct sizes for each density
- Use high-resolution source images (1024x1024 or larger)

### Getting Build Errors?
- Verify all icon sizes are present
- Check file names match exactly: `ic_launcher.png`

## Current Status

Currently, all flavors are using the same icon from `assets/image/splash_logo.png`.

You need to:
1. **Create/obtain logo images** for each brand
2. **Generate icons** using the method above
3. **Copy to flavor directories**
4. **Rebuild and test**

