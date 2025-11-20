# 🚀 Flutter Flavors System for Android

This system allows you to build different versions of your app (Pipze, Octa, Fleza) with different app icons, names, colors, and configurations using Flutter flavors.

## 🎯 What You Get

- **Different app icons** for each brand
- **Different app names** (Pipze, Octa, Fleza)
- **Different colors** (Purple, Orange, Green)
- **Different package IDs** for Play Store
- **Separate builds** for each brand

## 🏗️ Project Structure

```
android/app/src/
├── main/                    # Default configuration
├── pipze/                   # Pipze brand configuration
│   ├── res/
│   │   ├── values/
│   │   │   ├── strings.xml  # App name: "Pipze"
│   │   │   └── colors.xml   # Purple colors
│   │   └── mipmap-*/        # Pipze app icons
│   └── AndroidManifest.xml  # Pipze manifest
├── octa/                    # Octa brand configuration
│   ├── res/
│   │   ├── values/
│   │   │   ├── strings.xml  # App name: "Octa"
│   │   │   └── colors.xml   # Orange colors
│   │   └── mipmap-*/        # Octa app icons
│   └── AndroidManifest.xml  # Octa manifest
└── fleza/                   # Fleza brand configuration
    ├── res/
    │   ├── values/
    │   │   ├── strings.xml  # App name: "Fleza"
    │   │   └── colors.xml   # Green colors
    │   └── mipmap-*/        # Fleza app icons
    └── AndroidManifest.xml  # Fleza manifest
```

## 🎨 Brand Colors

| Brand | Primary Color | Secondary Color | Accent Color |
|-------|---------------|-----------------|--------------|
| **Pipze** | 🟣 Purple (#5A2DD8) | 🟣 Light Purple (#F8F3FF) | 🟣 Dark Purple (#9C27B0) |
| **Octa** | 🟠 Orange (#FF6B35) | 🟠 Light Orange (#FFF3E0) | 🟠 Dark Orange (#E65100) |
| **Fleza** | 🟢 Green (#4CAF50) | 🟢 Light Green (#E8F5E8) | 🟢 Dark Green (#2E7D32) |
| **ProFX** | 🟢 Teal (#0D7064) | 🟢 Mist (#E6F5F2) | 🟢 Deep Sea (#132E37) |

## 🚀 How to Build Different Flavors

### 1. Build Pipze (Purple)
```bash
flutter build apk --flavor pipze
# or
flutter build appbundle --flavor pipze
```

### 2. Build Octa (Orange)
```bash
flutter build apk --flavor octa
# or
flutter build appbundle --flavor octa
```

### 3. Build Fleza (Green)
```bash
flutter build apk --flavor fleza
# or
flutter build appbundle --flavor fleza
```

### 4. Build ProFX (Teal)
```bash
flutter build apk --flavor profx -t lib/main_profx.dart
# or
flutter build appbundle --flavor profx -t lib/main_profx.dart
```

## 🏃‍♂️ How to Run Different Flavors

### 1. Run Pipze
```bash
flutter run --flavor pipze
```

### 2. Run Octa
```bash
flutter run --flavor octa
```

### 3. Run Fleza
```bash
flutter run --flavor fleza
```

### 4. Run ProFX
```bash
flutter run --flavor profx -t lib/main_profx.dart
```

## 📱 Using Flavor Configuration in Code

### Import the flavor config
```dart
import 'package:pipze/flavor_config.dart';
```

### Access brand properties
```dart
// Get current brand colors
Color primaryColor = FlavorConfig.instance.primaryColor;
Color secondaryColor = FlavorConfig.instance.secondaryColor;
Color accentColor = FlavorConfig.instance.accentColor;

// Get brand information
String appName = FlavorConfig.instance.appName;
String appTitle = FlavorConfig.instance.appTitle;
String apiBaseUrl = FlavorConfig.instance.apiBaseUrl;

// Check current flavor
if (FlavorConfig.isProduction()) {
  // Pipze specific logic
} else if (FlavorConfig.isDevelopment()) {
  // Octa specific logic
} else if (FlavorConfig.isStaging()) {
  // Fleza specific logic
}
```

## 🎨 Example Usage in Widgets

```dart
import 'package:flutter/material.dart';
import 'package:pipze/flavor_config.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlavorConfig.instance.primaryColor,
        border: Border.all(
          color: FlavorConfig.instance.accentColor,
        ),
      ),
      child: Text(
        'Welcome to ${FlavorConfig.instance.appName}!',
        style: TextStyle(
          color: FlavorConfig.instance.primaryColor,
        ),
      ),
    );
  }
}
```

## 🔧 Setup Instructions

### 1. Add App Icons
For each brand, add your app icons to the respective mipmap folders:

```
android/app/src/pipze/res/mipmap-hdpi/ic_launcher.png     # 72x72 px
android/app/src/pipze/res/mipmap-mdpi/ic_launcher.png     # 48x48 px
android/app/src/pipze/res/mipmap-xhdpi/ic_launcher.png    # 96x96 px
android/app/src/pipze/res/mipmap-xxhdpi/ic_launcher.png   # 144x144 px
android/app/src/pipze/res/mipmap-xxxhdpi/ic_launcher.png  # 192x192 px
```

Do the same for `octa/` and `fleza/` folders.

#### ProFX launcher icons
1. Convert/update the artwork if needed:
   ```bash
   dart run tool/generate_profx_icon.dart
   ```
2. Regenerate the launcher assets:
   ```bash
   flutter pub run flutter_launcher_icons -f flutter_launcher_icons_profx.yaml
   ```
3. Copy the generated assets into the flavor-specific folders:
   ```bash
   dart run tool/copy_profx_launcher_assets.dart
   ```

### 2. Update Package Names (Optional)
If you want different package names for each brand, update the `applicationId` in `build.gradle.kts`:

```kotlin
create("pipze") {
    applicationId = "com.yourcompany.pipze"
}
create("octa") {
    applicationId = "com.yourcompany.octa"
}
create("fleza") {
    applicationId = "com.yourcompany.fleza"
}
```

### 3. Update API URLs
Update the API URLs in `lib/flavor_config.dart` for each brand:

```dart
static FlavorConfig get pipze => FlavorConfig(
  apiBaseUrl: 'https://api.pipze.com',
  // ... other properties
);
```

## 🚀 Build Scripts

Create these scripts in your project root for easy building:

### build_all.sh (Linux/Mac)
```bash
#!/bin/bash
echo "Building all flavors..."

echo "Building Pipze..."
flutter build apk --flavor pipze

echo "Building Octa..."
flutter build apk --flavor octa

echo "Building Fleza..."
flutter build apk --flavor fleza

echo "All builds completed!"
```

### build_all.bat (Windows)
```batch
@echo off
echo Building all flavors...

echo Building Pipze...
flutter build apk --flavor pipze

echo Building Octa...
flutter build apk --flavor octa

echo Building Fleza...
flutter build apk --flavor fleza

echo All builds completed!
pause
```

## 📱 Installing Multiple Flavors

You can install multiple flavors on the same device:

```bash
# Install Pipze
flutter install --flavor pipze

# Install Octa
flutter install --flavor octa

# Install Fleza
flutter install --flavor fleza
```

Each will appear as a separate app with different icons and names!

## 🔍 Debugging Flavors

### Check Current Flavor
```dart
print('Current flavor: ${FlavorConfig.instance.flavor}');
print('App name: ${FlavorConfig.instance.appName}');
print('Primary color: ${FlavorConfig.instance.primaryColor}');
```

### Flavor-Specific Logging
```dart
if (FlavorConfig.isProduction()) {
  print('Running Pipze production build');
} else if (FlavorConfig.isDevelopment()) {
  print('Running Octa development build');
} else if (FlavorConfig.isStaging()) {
  print('Running Fleza staging build');
}
```

## 🎯 Benefits of This System

1. **Professional**: Industry-standard approach to app variants
2. **Scalable**: Easy to add more brands
3. **Maintainable**: Separate configurations for each brand
4. **Deployable**: Different package IDs for Play Store
5. **Testable**: Can test all brands simultaneously
6. **Customizable**: Different icons, names, colors, APIs

## 🚨 Important Notes

- **Always use `FlavorConfig.instance`** instead of hardcoded values
- **Test all flavors** before releasing
- **Keep assets organized** in flavor-specific folders
- **Update all mipmap resolutions** for each brand
- **Use different package IDs** if publishing to Play Store

## 🔄 Switching Between Flavors

To switch between flavors during development:

1. **Stop the current app**
2. **Run with new flavor**: `flutter run --flavor octa`
3. **Or build new flavor**: `flutter build apk --flavor fleza`

---

**That's it!** You now have a professional Flutter flavors system that allows you to build different branded versions of your app with different icons, names, and colors! 🎉✨
