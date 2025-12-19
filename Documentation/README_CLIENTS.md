# Centralized Client Asset & Configuration Management

This system provides a **centralized, automated way** to manage client-specific assets, configurations, and branding for the Flutter multi-tenant app.

## 🎯 Key Features

- ✅ **Single source of truth** - All client configs in one place
- ✅ **Automated asset management** - Assets copied automatically during build
- ✅ **Auto-generated launcher icons** - No manual icon generation needed
- ✅ **Auto-generated splash screens** - Native splash with client colors
- ✅ **Centralized main.dart** - Auto-detects flavor, no duplicate main files
- ✅ **One-command build** - Everything automated with `./build.sh`
- ✅ **Debug mode with logging** - Full debugging with `./debug.sh` or `debug.bat`

---

## ⚡ Quick Commands

### Build Commands
```bash
# macOS/Linux
./build.sh {flavor} apk release        # Build release APK
./build.sh {flavor} appbundle release   # Build release AAB

# Windows
build.bat {flavor} apk release          # Build release APK
build.bat {flavor} appbundle release    # Build release AAB
```

### Debug Commands
```bash
# macOS/Linux
./debug.sh {flavor}                     # Run in debug mode
./debug.sh {flavor} emulator-5554       # Run on specific device
./debug.sh {flavor} --verbose           # Run with verbose logs

# Windows
debug.bat {flavor}                      # Run in debug mode
debug.bat {flavor} emulator-5554        # Run on specific device
debug.bat {flavor} --verbose            # Run with verbose logs
```

**Available flavors:** `afx`, `pipze`, `onsa`, `tenax`, `profx`

---

## 📁 Directory Structure

```
lib/clients/
├── base_config.dart              # Base template for all clients
├── afx/
│   ├── config.dart               # AFX configuration
│   ├── launcher_icons.yaml       # Icon generation config
│   └── assets/
│       ├── app_icon.png          # Launcher icon source (512x512)
│       ├── logo.svg              # Main logo
│       └── splash_logo.svg       # Splash screen logo
├── pipze/
│   ├── config.dart
│   ├── launcher_icons.yaml
│   └── assets/
│       ├── app_icon.png
│       ├── logo.svg
│       └── splash_logo.svg
└── ... (other clients: octa, tenax, onsa, profx)
```

---

## 🚀 Quick Start

### Build & Install

**macOS/Linux:**
```bash
# Build release APK
./build.sh afx apk release

# Build release AAB (for Play Store)
./build.sh afx appbundle release

# Build debug APK
./build.sh afx apk debug
```

**Windows:**
```cmd
REM Build release APK
build.bat afx apk release

REM Build release AAB (for Play Store)
build.bat afx appbundle release

REM Build debug APK
build.bat afx apk debug
```

### What Happens Automatically

When you run `./build.sh afx apk release`:

1. ✅ **Copies assets** from `lib/clients/afx/assets/` to `assets/clients/afx/`
2. ✅ **Updates pubspec.yaml** to include client assets
3. ✅ **Generates native splash** with AFX color (#182430)
4. ✅ **Generates launcher icons** from `lib/clients/afx/assets/app_icon.png`
5. ✅ **Builds APK** using centralized `main.dart` with auto flavor detection

**Output:**
```
🚀 Building afx flavor (apk, release mode)

📦 Step 1: Preparing client assets...
  ✓ Copied: /app_icon.png
  ✓ Copied: /splash_logo.svg
  ✓ Copied: /logo.svg
  ✓ Client assets already in pubspec.yaml
  ✓ Created launch_background.xml
  ✓ Splash color: #182430
  ✓ Launcher icons generated successfully

🔨 Step 2: Building Flutter app...
✓ Built build/app/outputs/flutter-apk/app-afx-release.apk (78.0MB)

✅ Build completed successfully!
```

---

## 🐛 Debug Mode (Run with Logging)

### Run in Debug Mode

**macOS/Linux:**
```bash
# Run in debug mode (auto-detects device)
./debug.sh afx

# Run on specific device
./debug.sh afx emulator-5554

# Run with verbose Flutter logs
./debug.sh afx --verbose

# Run on specific device with verbose logs
./debug.sh afx emulator-5554 --verbose
```

**Windows:**
```cmd
REM Run in debug mode (auto-detects device)
debug.bat afx

REM Run on specific device
debug.bat afx emulator-5554

REM Run with verbose Flutter logs
debug.bat afx --verbose

REM Run on specific device with verbose logs
debug.bat afx emulator-5554 --verbose
```

### What Happens in Debug Mode

When you run `./debug.sh afx`:

1. ✅ **Prepares assets** - Copies client assets automatically
2. ✅ **Enables all logs** - Trading, Chart, WebSocket, API, Order, Price, Debug
3. ✅ **Hot reload enabled** - Press 'r' to reload, 'R' to restart
4. ✅ **Debugger attached** - Full debugging capabilities
5. ✅ **Shows device list** - If no device specified, lists available devices

**Debug Commands:**
- Press `r` - Hot reload (fast refresh)
- Press `R` - Hot restart (full restart)
- Press `q` - Quit debug session
- Press `h` - Show help menu

**Log Categories:**
- `[Trading]` - Trading operations and orders
- `[Chart]` - Chart updates and rendering
- `[WebSocket]` - WebSocket connections and messages
- `[API]` - API calls and responses
- `[Order]` - Order placement and management
- `[Price]` - Price updates and quotes
- `[Debug]` - Debug information (only in debug mode)
- `[Error]` - Errors and exceptions

### Viewing Logs

**In Terminal:**
All logs appear in the terminal where you ran `./debug.sh` or `debug.bat`.

**Filter Logs:**
You can filter logs by category in your IDE or terminal:
```bash
# Filter WebSocket logs only
flutter logs | grep "WebSocket"

# Filter Error logs only
flutter logs | grep "Error"
```

**In VS Code:**
- Open Debug Console to see all logs
- Use the Debug panel to set breakpoints
- Logs are color-coded by category

**In Android Studio:**
- Open Logcat to see all logs
- Filter by tag (Trading, Chart, WebSocket, etc.)
- Use the Debugger tab for breakpoints

### Manual Debug Command

If you prefer to run manually:
```bash
# Prepare assets first
dart run scripts/prepare_flavor.dart afx

# Then run in debug mode
flutter run --flavor afx -t lib/main.dart --dart-define=FLAVOR=afx --debug -d emulator-5554
```

---

## 📝 Adding a New Client

### Step 1: Create Client Configuration

Create `lib/clients/newclient/config.dart`:

```dart
import 'package:flutter/material.dart';
import '../base_config.dart';

class NewClientConfig extends BaseClientConfig {
  const NewClientConfig()
      : super(
          brandName: 'NewClient',
          appTitle: 'NewClient Trading',
          primaryColor: const Color(0xFF123456),
          secondaryColor: const Color(0xFFABCDEF),
          accentColor: const Color(0xFF654321),
          logoSvgPath: 'logo.svg',
          splashLogoPath: 'splash_logo.svg',
          appIconPath: 'app_icon.png',
          apiBaseUrl: 'https://api.newclient.com/api/',
          websocketUrl: 'wss://api.newclient.com/trade-engine',
          chartBaseUrl: 'https://api.newclient.com',
        );
}
```

### Step 2: Add Client Assets

Create `lib/clients/newclient/assets/` and add:
- `app_icon.png` - Launcher icon source (512x512px)
- `logo.svg` - Main brand logo
- `splash_logo.svg` - Splash screen logo

### Step 3: Create Launcher Icons Config

Create `lib/clients/newclient/launcher_icons.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "lib/clients/newclient/assets/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#123456"
  adaptive_icon_foreground: "lib/clients/newclient/assets/app_icon.png"
```

### Step 4: Register in FlavorConfig

Add to `lib/flavor_config.dart`:

```dart
// 1. Add to enum
enum Flavor { pipze, octa, tenax, onsa, profx, afx, newclient }

// 2. Add import
import 'clients/newclient/config.dart';

// 3. Add getter
static FlavorConfig get newclient {
  _selectedFlavor = Flavor.newclient;
  const config = NewClientConfig();
  return FlavorConfig(
    flavor: Flavor.newclient,
    appName: config.brandName,
    appTitle: config.appTitle,
    primaryColor: config.primaryColor,
    secondaryColor: config.secondaryColor,
    accentColor: config.accentColor,
    apiBaseUrl: config.apiBaseUrl,
    websocketUrl: config.websocketUrl,
    chartBaseUrl: config.chartBaseUrl,
    appIconPath: config.getAssetPath('newclient', config.appIconPath),
    svgLogoPath: config.getAssetPath('newclient', config.logoSvgPath),
    splashLogoPath: config.getAssetPath('newclient', config.splashLogoPath),
  );
}

// 4. Add to _initializeFlavorByName in main.dart
case 'newclient':
  FlavorConfig.newclient;
  break;
```

### Step 5: Add Android Flavor

Update `android/app/build.gradle.kts`:

```kotlin
create("newclient") {
    dimension = "brand"
    applicationId = "com.newclient.trade"
    resValue("string", "app_name", "NewClient")
    resValue("color", "primary_color", "#123456")
    resValue("color", "secondary_color", "#ABCDEF")
    resValue("color", "accent_color", "#654321")
    buildConfigField("String", "FLAVOR", "\"newclient\"")
    manifestPlaceholders["FLAVOR"] = "newclient"
}
```

### Step 6: Build!

```bash
./build.sh newclient apk release
```

Done! ✅

---

## 🎨 Asset Guidelines

### Launcher Icon (`app_icon.png`)
- **Format**: PNG with transparency
- **Size**: 512x512px minimum
- **Usage**: Generated into all Android launcher icon sizes
- **Location**: `lib/clients/{flavor}/assets/app_icon.png`

### Main Logo (`logo.svg`)
- **Format**: SVG
- **Usage**: Main app screens, navigation, GetStartedScreen
- **Recommended**: Transparent background, works on light/dark
- **Location**: `lib/clients/{flavor}/assets/logo.svg`

### Splash Logo (`splash_logo.svg`)
- **Format**: SVG
- **Usage**: Splash screen (before Flutter loads)
- **Recommended**: Works on brand color background
- **Location**: `lib/clients/{flavor}/assets/splash_logo.svg`

---

## 🔧 Configuration Files

### Client Config (`config.dart`)

Defines all client-specific settings:
- Brand name and app title
- Primary, secondary, accent colors
- API URLs (base, websocket, chart)
- Asset paths (logo, splash, icon)

**Example:**
```dart
class AfxConfig extends BaseClientConfig {
  const AfxConfig()
      : super(
          brandName: 'AFX',
          primaryColor: const Color(0xFF182430),
          apiBaseUrl: 'https://member.alibabafx.com/api/',
          // ... all config values
        );
}
```

### Launcher Icons Config (`launcher_icons.yaml`)

Defines icon generation settings:
- Image source path
- Adaptive icon background color
- Platform targets (Android/iOS)

**Example:**
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "lib/clients/afx/assets/app_icon.png"
  adaptive_icon_background: "#182430"
```

---

## 🛠️ Manual Commands

### Prepare Assets Only
```bash
dart run scripts/prepare_flavor.dart afx
```

### Build Only (after preparation)
```bash
flutter build apk --flavor afx -t lib/main.dart --dart-define=FLAVOR=afx --release
```

### Install on Device
```bash
flutter install --flavor afx -d {DEVICE_ID}
```

---

## 📊 Benefits

### Before: Manual & Duplicated

- ❌ 6 separate `main_{flavor}.dart` files (1,308 lines duplicated)
- ❌ Manual asset copying
- ❌ Manual icon generation with `flutter pub run flutter_launcher_icons -f ...`
- ❌ Manual splash screen configuration
- ❌ Config values in multiple places

### After: Automated & Centralized

- ✅ 1 centralized `main.dart` with auto flavor detection
- ✅ Automatic asset copying
- ✅ Automatic icon generation
- ✅ Automatic splash screen generation
- ✅ Single source of truth for all configs

---

## 🔍 Troubleshooting

### Assets not found after build
Run the preparation script:
```bash
dart run scripts/prepare_flavor.dart {flavor}
```

### Icons not updating
Delete old icons and regenerate:
```bash
rm -rf android/app/src/{flavor}/res/mipmap-*
dart run scripts/prepare_flavor.dart {flavor}
```

### Splash screen shows wrong color
Check `lib/clients/{flavor}/config.dart` has correct `primaryColor`.

### Build fails with "flavor not found"
Ensure flavor is defined in `android/app/build.gradle.kts`.

---

## 📚 File Locations

| File Type | Location | Purpose |
|-----------|----------|---------|
| **Client Config** | `lib/clients/{flavor}/config.dart` | All client settings |
| **Launcher Icons Config** | `lib/clients/{flavor}/launcher_icons.yaml` | Icon generation |
| **Client Assets** | `lib/clients/{flavor}/assets/` | Source assets |
| **Generated Assets** | `assets/clients/{flavor}/` | Auto-generated during build |
| **Build Script** | `./build.sh` | One-command build |
| **Preparation Script** | `scripts/prepare_flavor.dart` | Asset preparation |
| **Main Entry** | `lib/main.dart` | Centralized entry point |

---

## 🎉 Summary

This centralized system provides:
- **Zero duplication** - Single source of truth
- **Full automation** - One command does everything
- **Easy maintenance** - Update once, applies everywhere
- **Consistent structure** - Same pattern for all clients
- **Simple workflow** - `./build.sh {flavor} apk release`

**No more manual steps!** Everything is automated. 🚀
