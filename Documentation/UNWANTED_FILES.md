# Unwanted Files in Flutter Project

This document lists files that can be safely deleted from the project as they are:
- Obsolete (replaced by new centralized system)
- Platform-specific scripts for Windows (not needed on Mac)
- Duplicate/backup files
- Unnecessary configuration files

---

## 🗑️ Files to Delete

### 1. Obsolete Build Scripts (Replaced by `build.sh`)

These Windows batch/PowerShell scripts are replaced by the new `build.sh`:

```
❌ build_flavor.bat          # Old Windows build script
❌ build_flavor.ps1          # Old PowerShell build script
❌ run_flavor.bat            # Old Windows run script
❌ run_flavor.ps1            # Old PowerShell run script
```

**Reason**: We now use `./build.sh {flavor} apk release` which is cross-platform and more powerful.

---

### 2. Obsolete Icon Generation Scripts

These are replaced by automated icon generation in `scripts/prepare_flavor.dart`:

```
❌ generate_icons.bat        # Old Windows icon generation
❌ setup_launcher_icons.ps1  # Old PowerShell icon setup
```

**Reason**: Icons are now generated automatically during build with `./build.sh`.

---

### 3. Obsolete Log Filtering Scripts

```
❌ filter_logs.bat           # Windows log filter
❌ filter_logs.ps1           # PowerShell log filter
❌ setup_clean_logs.bat      # Windows log setup
```

**Reason**: These are Windows-specific and not used in the current workflow.

---

### 4. Obsolete Brand Switching Script

```
❌ switch_brand.py           # Old Python brand switcher
```

**Reason**: Replaced by centralized config system. Flavors are now selected via build command.

---

### 5. Obsolete Launcher Icons Config

```
❌ flutter_launcher_icons.yaml        # Generic config (not flavor-specific)
❌ flutter_launcher_icons_fleza.yaml  # Fleza flavor (if not used)
```

**Reason**: Launcher icon configs are now in `lib/clients/{flavor}/launcher_icons.yaml`.

---

### 6. Backup/Archive Files

```
❌ lib_11_11.zip             # Old code backup (478 KB)
❌ .vscode.zip               # VSCode settings backup
```

**Reason**: These are backups. Use git history instead.

---

### 7. Unnecessary Config Files

```
❌ android_studio_logcat_filters.xml  # Android Studio specific
❌ Podfile                            # iOS dependency (if not using CocoaPods)
```

**Reason**: 
- `android_studio_logcat_filters.xml` - IDE-specific, not needed in repo
- `Podfile` - Only needed if using CocoaPods for iOS

---

### 8. System Files

```
❌ .DS_Store                 # macOS system file
```

**Reason**: Should be in `.gitignore`, not tracked in git.

---

### 9. Postman Collection (Optional)

```
⚠️  FXClient360 API Collection.postman_collection.json
```

**Reason**: Move to `Documentation/` or delete if not actively used.

---

## 📊 Summary

### Total Files to Delete: 17 files

**Categories:**
- Windows scripts: 8 files (.bat, .ps1)
- Obsolete configs: 3 files
- Backup files: 2 files (.zip)
- Python script: 1 file
- System files: 1 file (.DS_Store)
- Optional: 2 files (Postman, Podfile)

**Space saved**: ~480 KB (mostly from lib_11_11.zip)

---

## 🚀 Recommended Deletion Command

```bash
# Delete obsolete Windows scripts
rm build_flavor.bat build_flavor.ps1 run_flavor.bat run_flavor.ps1
rm generate_icons.bat setup_launcher_icons.ps1
rm filter_logs.bat filter_logs.ps1 setup_clean_logs.bat

# Delete obsolete Python script
rm switch_brand.py

# Delete obsolete launcher icon configs
rm flutter_launcher_icons.yaml flutter_launcher_icons_fleza.yaml

# Delete backup files
rm lib_11_11.zip .vscode.zip

# Delete system files
rm .DS_Store

# Delete unnecessary config
rm android_studio_logcat_filters.xml

# Optional: Move Postman collection to Documentation
mv "FXClient360 API Collection.postman_collection.json" Documentation/
```

---

## ✅ What to Keep

**Keep these files:**
- `build.sh` - New centralized build script
- `scripts/prepare_flavor.dart` - Asset preparation
- `lib/clients/{flavor}/launcher_icons.yaml` - Per-flavor icon configs
- `pubspec.yaml` - Flutter dependencies
- `analysis_options.yaml` - Dart linting rules
- `.gitignore` - Git ignore rules
- `.metadata` - Flutter metadata
- `devtools_options.yaml` - DevTools config

---

## 📝 After Deletion

After deleting these files:

1. **Test build**: `./build.sh afx apk release`
2. **Verify**: Ensure everything still works
3. **Commit**: 
   ```bash
   git add -A
   git commit -m "chore: Remove obsolete scripts and backup files"
   git push origin afx_k3
   ```

---

## ⚠️ Notes

- **Podfile**: Only delete if you're not using CocoaPods for iOS dependencies
- **Postman Collection**: Move to Documentation/ instead of deleting if still useful
- **gradlew.bat**: Keep this! It's needed for Android builds on Windows CI/CD
