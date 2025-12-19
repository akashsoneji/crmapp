# 🏗️ Flutter Flavor Build Guide

This guide shows you how to build different flavors (Pipze, Octa, Fleza) for both AAB (Android App Bundle) and APK formats.

## 🎯 **What You Can Build:**

- **AAB (Android App Bundle)**: For Google Play Store publishing
- **APK**: For direct installation and testing
- **3 Different Brands**: Pipze (Purple), Octa (Orange), Fleza (Green)

## 🚀 **Build Commands:**

### **1. Build AAB (App Bundle) - For Play Store:**

```bash
# Build AAB for each flavor
flutter build appbundle --flavor pipze --release
flutter build appbundle --flavor octa --release
flutter build appbundle --flavor fleza --release
```

### **2. Build APK - For Testing:**

```bash
# Build APK for each flavor
flutter build apk --flavor pipze --release
flutter build apk --flavor octa --release
flutter build apk --flavor fleza --release
```

### **3. Build Debug APK - For Development:**

```bash
# Build debug APK for each flavor
flutter build apk --flavor pipze
flutter build apk --flavor octa
flutter build apk --flavor fleza
```

## 🛠️ **Easy Build Scripts:**

### **Windows Batch Script:**
```bash
# Build AAB
build_flavor.bat pipze aab    # Build Pipze AAB
build_flavor.bat octa aab     # Build Octa AAB
build_flavor.bat fleza aab    # Build Fleza AAB

# Build APK
build_flavor.bat pipze apk    # Build Pipze APK
build_flavor.bat octa apk     # Build Octa APK
build_flavor.bat fleza apk    # Build Fleza APK
```

### **PowerShell Script:**
```bash
# Build AAB
.\build_flavor.ps1 pipze aab    # Build Pipze AAB
.\build_flavor.ps1 octa aab     # Build Octa AAB
.\build_flavor.ps1 fleza aab    # Build Fleza AAB

# Build APK
.\build_flavor.ps1 pipze apk    # Build Pipze APK
.\build_flavor.ps1 octa apk     # Build Octa APK
.\build_flavor.ps1 fleza apk    # Build Fleza APK
```

## 📁 **Output Locations:**

### **AAB Files:**
```
build/app/outputs/bundle/pipzeRelease/
├── app-pipze-release.aab

build/app/outputs/bundle/octaRelease/
├── app-octa-release.aab

build/app/outputs/bundle/flezaRelease/
├── app-fleza-release.aab
```

### **APK Files:**
```
build/app/outputs/flutter-apk/
├── app-pipze-release.apk
├── app-octa-release.apk
└── app-fleza-release.apk
```

## 🔧 **Build Options:**

### **Release Build (Production):**
```bash
flutter build appbundle --flavor pipze --release
flutter build apk --flavor pipze --release
```

### **Debug Build (Development):**
```bash
flutter build apk --flavor pipze
flutter build apk --flavor octa
flutter build apk --flavor fleza
```

### **Profile Build (Performance Testing):**
```bash
flutter build apk --flavor pipze --profile
flutter build apk --flavor octa --profile
flutter build apk --flavor fleza --profile
```

## 📱 **What Each Build Contains:**

### **Pipze Build:**
- 🟣 Purple theme colors
- App name: "Pipze"
- Bundle ID: `com.example.pipze`
- Brand-specific resources

### **Octa Build:**
- 🟠 Orange theme colors
- App name: "Octa"
- Bundle ID: `com.example.octa`
- Brand-specific resources

### **Fleza Build:**
- 🟢 Green theme colors
- App name: "Fleza"
- Bundle ID: `com.example.fleza`
- Brand-specific resources

## 🚨 **Important Notes:**

1. **AAB is for Play Store**: Use `flutter build appbundle` for publishing
2. **APK is for testing**: Use `flutter build apk` for direct installation
3. **Always use --release**: For production builds
4. **Check outputs folder**: Files are in `build/app/outputs/`
5. **Different bundle IDs**: Each flavor has unique bundle identifier

## 🎉 **Quick Build Examples:**

```bash
# Build all flavors for Play Store
flutter build appbundle --flavor pipze --release
flutter build appbundle --flavor octa --release
flutter build appbundle --flavor fleza --release

# Build all flavors for testing
flutter build apk --flavor pipze --release
flutter build apk --flavor octa --release
flutter build apk --flavor fleza --release
```

## 📋 **Build Checklist:**

- [ ] Select target flavor (pipze/octa/fleza)
- [ ] Choose build type (aab/apk)
- [ ] Use --release flag for production
- [ ] Check build/app/outputs/ folder
- [ ] Verify brand colors and app names
- [ ] Test installation on device

---

**Your flavor builds are ready!** 🚀✨
