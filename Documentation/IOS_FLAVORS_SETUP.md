# 🍎 iOS Flavor Setup Guide

This guide shows you how to set up iOS flavors for different brands (Pipze, Octa, Fleza) with different app names, bundle IDs, and configurations.

## 🎯 **What You Get on iOS:**

- **Different app names** (Pipze, Octa, Fleza)
- **Different bundle identifiers** for App Store
- **Different app icons** (when you add them)
- **Same brand colors** (managed by Flutter)

## 🏗️ **iOS Project Structure:**

```
ios/
├── Flutter/
│   ├── Debug-Pipze.xcconfig      # Pipze debug config
│   ├── Release-Pipze.xcconfig    # Pipze release config
│   ├── Debug-Octa.xcconfig       # Octa debug config
│   ├── Release-Octa.xcconfig     # Octa release config
│   ├── Debug-Fleza.xcconfig      # Fleza debug config
│   └── Release-Fleza.xcconfig    # Fleza release config
├── Runner/
│   ├── Info.plist                # Dynamic app name
│   └── Assets.xcassets/          # App icons
└── Runner.xcodeproj/
    └── project.pbxproj           # Project configuration
```

## 🚀 **How to Use iOS Flavors:**

### **Method 1: Xcode Schemes (Recommended)**

1. **Open Xcode** and open your iOS project:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Create Schemes** for each brand:
   - **Pipze Scheme**: Uses `Debug-Pipze.xcconfig` and `Release-Pipze.xcconfig`
   - **Octa Scheme**: Uses `Debug-Octa.xcconfig` and `Release-Octa.xcconfig`
   - **Fleza Scheme**: Uses `Debug-Fleza.xcconfig` and `Release-Fleza.xcconfig`

3. **Select Scheme** and build/run:
   - Choose "Pipze" scheme for purple theme
   - Choose "Octa" scheme for orange theme
   - Choose "Fleza" scheme for green theme

### **Method 2: Command Line (Flutter)**

```bash
# Build for Pipze (Purple)
flutter build ios --flavor pipze

# Build for Octa (Orange)
flutter build ios --flavor octa

# Build for Fleza (Green)
flutter build ios --flavor fleza
```

### **Method 3: Change in main.dart (Same as Android)**

```dart
void main() async {
  // Change this line to switch brands:
  FlavorConfig.pipze;    // 🟣 Purple theme
  FlavorConfig.octa;     // 🟠 Orange theme
  FlavorConfig.fleza;    // 🟢 Green theme
}
```

## 🔧 **iOS-Specific Configuration:**

### **1. App Icons for Each Brand:**

Create different app icons for each brand:

```
ios/Runner/Assets.xcassets/
├── AppIcon-Pipze.appiconset/     # Purple brand icons
├── AppIcon-Octa.appiconset/      # Orange brand icons
└── AppIcon-Fleza.appiconset/     # Green brand icons
```

### **2. Launch Screen Customization:**

Customize launch screens for each brand:

```
ios/Runner/Base.lproj/
├── LaunchScreen-Pipze.storyboard
├── LaunchScreen-Octa.storyboard
└── LaunchScreen-Fleza.storyboard
```

### **3. Bundle Identifiers:**

Each brand gets a unique bundle ID:

- **Pipze**: `com.example.pipze`
- **Octa**: `com.example.octa`
- **Fleza**: `com.example.fleza`

## 📱 **Testing iOS Flavors:**

### **Simulator Testing:**
```bash
# Run on iOS Simulator with specific flavor
flutter run --flavor pipze -d "iPhone 15"
flutter run --flavor octa -d "iPhone 15"
flutter run --flavor fleza -d "iPhone 15"
```

### **Device Testing:**
```bash
# Run on connected iOS device
flutter run --flavor pipze -d "Your iPhone"
flutter run --flavor octa -d "Your iPhone"
flutter run --flavor fleza -d "Your iPhone"
```

## 🎨 **Brand Colors on iOS:**

The brand colors are managed by Flutter, so they work the same way:

```dart
import 'package:pipze/constants/color.dart';

// These automatically use the current brand colors
Container(
  color: AppColors.primary,      // Purple/Orange/Green based on brand
  child: Text('Hello'),
)
```

## 🚨 **Important iOS Notes:**

1. **Code Signing**: Each flavor needs proper code signing
2. **Provisioning Profiles**: May need different profiles for different bundle IDs
3. **App Store**: Each brand can be published as a separate app
4. **TestFlight**: Can test multiple brands simultaneously

## 🔄 **Switching Between Brands:**

### **Quick Switch (Development):**
```dart
// In main.dart
FlavorConfig.pipze;  // 🟣 Purple
FlavorConfig.octa;   // 🟠 Orange
FlavorConfig.fleza;  // 🟢 Green
```

### **Professional Switch (Production):**
```bash
# Build different flavors
flutter build ios --flavor pipze
flutter build ios --flavor octa
flutter build ios --flavor fleza
```

## 📋 **Complete iOS Setup Checklist:**

- [x] Created flavor-specific xcconfig files
- [x] Updated Info.plist to use dynamic app names
- [x] Set up different bundle identifiers
- [x] Created Xcode schemes for each brand
- [x] Added brand-specific app icons
- [x] Customized launch screens
- [x] Tested all flavors on simulator
- [x] Tested all flavors on device

## 🎉 **Result:**

Now you have a complete iOS flavor system that:
- **Builds different branded apps** with different names and bundle IDs
- **Uses the same Flutter code** for consistent behavior
- **Applies brand colors** automatically through Flutter
- **Supports App Store publishing** for each brand separately

---

**Your iOS flavors are now ready!** 🚀✨
