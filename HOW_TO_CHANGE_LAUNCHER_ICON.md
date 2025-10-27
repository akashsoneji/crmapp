# How to Change App Launcher Icon for Each Flavor

## ✅ What I've Done For You

### 1. Created Directory Structure
I've created the necessary mipmap directories for all flavors:
- ✅ `android/app/src/onsa/res/mipmap-mdpi/`, `-hdpi/`, `-xhdpi/`, `-xxhdpi/`, `-xxxhdpi/`
- ✅ `android/app/src/pipze/res/mipmap-mdpi/`, etc.
- ✅ `android/app/src/octa/res/mipmap-mdpi/`, etc.
- ✅ `android/app/src/fleza/res/mipmap-mdpi/`, etc.

### 2. Created Configuration Files
Created YAML configuration files for each flavor:
- `flutter_launcher_icons_onsa.yaml` - for ONSA
- `flutter_launcher_icons_octa.yaml` - for Octa
- `flutter_launcher_icons_fleza.yaml` - for Fleza
- `flutter_launcher_icons_pipze.yaml` - for Pipze

### 3. Updated Splash Screen Colors
Fixed the splash screen to show the correct brand color for each flavor.

## 🎨 What You Need to Do Now

### Step 1: Get Your Logo Images

You need PNG images (1024x1024 recommended) for each brand:

1. **ONSA** - Your ONSA logo (blue theme)
2. **Octa** - Your Octa logo (orange theme)
3. **Fleza** - Your Fleza logo (green theme)
4. **Pipze** - Already have splash_logo.png

Save these in the `assets/image/` folder:
- `onsa_logo.png`
- `octa_logo.png`  
- `fleza_logo.png`

### Step 2: Update the YAML Config Files

Open each YAML file and update the image_path:

**flutter_launcher_icons_onsa.yaml:**
```yaml
image_path: "assets/image/onsa_logo.png"  # Change this
```

**flutter_launcher_icons_octa.yaml:**
```yaml
image_path: "assets/image/octa_logo.png"  # Change this
```

**flutter_launcher_icons_fleza.yaml:**
```yaml
image_path: "assets/image/fleza_logo.png"  # Change this
```

### Step 3: Generate Icons for Each Flavor

Run these commands one by one:

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

### Step 4: Copy Icons to Flavor Directories

After generating icons, they will be in:
```
android/app/src/main/res/mipmap-mdpi/ic_launcher.png
android/app/src/main/res/mipmap-hdpi/ic_launcher.png
# ... etc for all densities
```

**You need to copy these to each flavor's directory:**

Copy from `android/app/src/main/res/mipmap-*/` to:
- `android/app/src/onsa/res/mipmap-*/`
- `android/app/src/pipze/res/mipmap-*/`  
- `android/app/src/octa/res/mipmap-*/`
- `android/app/src/fleza/res/mipmap-*/`

#### Quick Copy Script

You can do this manually or use Windows Explorer to copy-paste the files.

### Step 5: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter build apk --flavor onsadb  # Test with ONSA
```

## 📋 Summary

**Current Status:**
- ✅ Directories created for all flavors
- ✅ Configuration files ready
- ✅ Splash colors fixed

**What You Need:**
- ❌ Logo image files (PNG format)
- ❌ Generate and copy the icons
- ❌ Rebuild and test

## 🎯 Quick Start for ONSA (Example)

If you want to test with ONSA right now:

1. Get/create `onsa_logo.png` (1024x1024 PNG)
2. Place it in `assets/image/onsa_logo.png`
3. Run: `flutter pub run flutter_launcher_icons -f flutter_launcher_icons_onsa.yaml`
4. Copy generated icons from `android/app/src/main/res/mipmap-*/` to `android/app/src/onsa/res/mipmap-*/`
5. Build: `flutter build apk --flavor onsadb`
6. Install and check the launcher icon

## 💡 Tips

- **Icon Size**: Use at least 1024x1024 px source image
- **Format**: PNG with transparent background works best
- **Colors**: Icons should work well on light and dark backgrounds
- **Testing**: You can install multiple flavors at once to see different icons

## 🆘 Troubleshooting

**Icon doesn't change?**
- Make sure you copied icons to the correct flavor directory
- Run `flutter clean` before rebuilding
- Check file names are exactly `ic_launcher.png`

**Build errors?**
- Make sure all density folders have icons
- Verify image_path in YAML points to valid file
- Check for syntax errors in YAML files

## 📱 Expected Results

When you build each flavor and install on Android:
- **ONSA**: Blue background with ONSA logo
- **Pipze**: Purple background with Pipze logo
- **Octa**: Orange background with Octa logo
- **Fleza**: Green background with Fleza logo

Each app will show its brand's unique icon on the home screen!

