# 🎨 Brand Switching System

This system allows you to easily switch between different brands (Pipze, Octa, Fleza) by changing just one value!

## 🚀 Quick Start

### Method 1: Manual Switch (Change 1 line)
1. Open `lib/constants/app_config.dart`
2. Change this line:
   ```dart
   const AppBrand currentBrand = AppBrand.pipze;  // Change to: octa or fleza
   ```
3. That's it! The app will now use the new brand colors and names.

### Method 2: Automatic Switch (Python Script)
1. Run the Python script:
   ```bash
   python switch_brand.py pipze    # Switch to Pipze (Purple)
   python switch_brand.py octa     # Switch to Octa (Orange)  
   python switch_brand.py fleza    # Switch to Fleza (Green)
   ```

## 🎯 What Gets Updated Automatically

When you switch brands, these files are updated:

1. **`lib/constants/app_config.dart`** - Brand colors and names
2. **`pubspec.yaml`** - Package name
3. **`android/app/src/main/AndroidManifest.xml`** - App label
4. **`flutter_launcher_icons.yaml`** - Launcher icon path

## 🌈 Brand Colors

| Brand | Primary Color | Secondary Color | Accent Color |
|-------|---------------|-----------------|--------------|
| **Pipze** | 🟣 Purple (#5F259E) | 🟣 Light Purple (#F8F3FF) | 🟣 Dark Purple (#9C27B0) |
| **Octa** | 🟠 Orange (#FF6B35) | 🟠 Light Orange (#FFF3E0) | 🟠 Dark Orange (#E65100) |
| **Fleza** | 🟢 Green (#4CAF50) | 🟢 Light Green (#E8F5E8) | 🟢 Dark Green (#2E7D32) |

## 📱 How to Use Brand Colors in Your Code

### Before (Hardcoded colors):
```dart
Container(
  color: const Color(0xFF5F259E),  // Hardcoded purple
  child: Text('Hello'),
)
```

### After (Brand-aware colors):
```dart
import 'package:pipze/constants/app_config.dart';

Container(
  color: AppConfig.primaryColor,    // Automatically uses current brand color
  child: Text('Hello'),
)
```

## 🔧 Available Brand Properties

```dart
// Get current brand colors
AppConfig.primaryColor      // Primary brand color
AppConfig.secondaryColor    // Secondary brand color  
AppConfig.accentColor       // Accent brand color

// Get brand information
AppConfig.appName           // Package name (pipze, octa, fleza)
AppConfig.displayName       // Display name (Pipze, Octa, Fleza)

// Get brand assets
AppConfig.launcherIcon      // Launcher icon path
AppConfig.splashLogo        // Splash logo path

// Get colors with opacity
AppConfig.getPrimaryColorWithOpacity(0.5)    // Primary color with 50% opacity
AppConfig.getSecondaryColorWithOpacity(0.3)  // Secondary color with 30% opacity
```

## 📁 Asset Requirements

For each brand, you need these assets:

```
assets/image/
├── splash_logo.png          # Pipze (default)
├── octa_launcher.png        # Octa launcher icon
├── octa_splash.png          # Octa splash logo
├── fleza_launcher.png       # Fleza launcher icon
└── fleza_splash.png         # Fleza splash logo
```

## 🚀 After Switching Brands

1. **Clean the project:**
   ```bash
   flutter clean
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate new launcher icons:**
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

4. **Build your app:**
   ```bash
   flutter build apk
   # or
   flutter build ios
   ```

## 💡 Tips

- **Always use `AppConfig.primaryColor`** instead of hardcoded colors
- **Test all screens** after switching brands to ensure colors look good
- **Keep brand assets organized** in the assets/image folder
- **Use the Python script** for quick brand switching during development

## 🔄 Switching Back

To switch back to Pipze:
```bash
python switch_brand.py pipze
```

Or manually change:
```dart
const AppBrand currentBrand = AppBrand.pipze;
```

## 📝 Example Usage in Widgets

```dart
import 'package:pipze/constants/app_config.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConfig.primaryColor,
        border: Border.all(
          color: AppConfig.getPrimaryColorWithOpacity(0.3),
        ),
      ),
      child: Text(
        'Welcome to ${AppConfig.displayName}!',
        style: TextStyle(
          color: AppConfig.primaryColor,
        ),
      ),
    );
  }
}
```

---

**That's it!** Now you can easily switch between brands by changing just one line of code! 🎉
