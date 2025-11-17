#!/bin/bash

# Script to update iOS app name and icon based on FlavorConfig in main.dart
# This allows iOS to work like Android - just change FlavorConfig in main.dart

MAIN_DART="lib/main.dart"
INFO_PLIST="ios/Runner/Info.plist"
PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"

# Extract flavor from main.dart (ignore commented lines)
FLAVOR=$(grep -E "^[[:space:]]*FlavorConfig\.(pipze|octa|fleza|tenax|onsa)" "$MAIN_DART" | grep -v "^[[:space:]]*//" | head -1 | sed -E 's/.*FlavorConfig\.([a-z]+).*/\1/')

if [ -z "$FLAVOR" ]; then
    echo "⚠️  Could not detect flavor from $MAIN_DART"
    echo "   Make sure FlavorConfig.{flavor} is set in main.dart"
    exit 1
fi

echo "📱 Detected flavor: $FLAVOR"

# Map flavor to app name and icon (from flavor_config.dart)
case "$FLAVOR" in
    pipze)
        APP_NAME="Pipze"
        APP_ICON="AppIcon"  # Using default icon for now
        ;;
    octa)
        APP_NAME="Octa"
        APP_ICON="AppIcon"  # Using default icon for now
        ;;
    fleza)
        APP_NAME="Fleza"
        APP_ICON="AppIcon"  # Using default icon for now
        ;;
    tenax)
        APP_NAME="Tenax"
        APP_ICON="tenax_app_icon"
        ;;
    onsa)
        APP_NAME="ONSA"
        APP_ICON="onsa_app_icon"
        ;;
    *)
        APP_NAME="Pipze"
        APP_ICON="AppIcon"
        ;;
esac

echo "📝 Updating app name to: $APP_NAME"
echo "🎨 Updating app icon to: $APP_ICON"

# Update Info.plist using PlistBuddy
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$INFO_PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $APP_NAME" "$INFO_PLIST"

/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$INFO_PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$INFO_PLIST"

# Update Xcode project file to change app icon
# This updates ASSETCATALOG_COMPILER_APPICON_NAME for Runner target (Debug, Release, Profile)
if [ -f "$PROJECT_FILE" ]; then
    # Check if icon set exists, if not use AppIcon as fallback
    ICON_SET_PATH="ios/Runner/Assets.xcassets/${APP_ICON}.appiconset"
    if [ ! -d "$ICON_SET_PATH" ]; then
        echo "⚠️  Icon set not found: $ICON_SET_PATH"
        echo "   Using default AppIcon. Please create $APP_ICON.appiconset in Assets.xcassets"
        echo "   Run: bash scripts/create_ios_icon_set.sh $FLAVOR <path_to_icon_image>"
        APP_ICON="AppIcon"
    fi
    
    # Create backup
    cp "$PROJECT_FILE" "${PROJECT_FILE}.bak"
    
    # Update ASSETCATALOG_COMPILER_APPICON_NAME for Runner target configurations only
    # We need to update lines that are in Runner target (97C147061CF9000F007C117D) sections
    # This includes Debug, Release configurations for Runner target
    
    # Use Python for more reliable string replacement
    python3 << EOF
import re

project_file = "$PROJECT_FILE"
new_icon = "$APP_ICON"

with open(project_file, 'r') as f:
    content = f.read()

# Pattern to match ASSETCATALOG_COMPILER_APPICON_NAME in Runner target sections
# Update all instances (will handle Debug, Release, Profile)
pattern = r'(ASSETCATALOG_COMPILER_APPICON_NAME = )([^;]+)(;)'
replacement = r'\1' + new_icon + r'\3'

# Replace all occurrences
content = re.sub(pattern, replacement, content)

with open(project_file, 'w') as f:
    f.write(content)

print(f"✅ Updated all icon settings to: {new_icon}")
EOF
    
    echo "✅ Updated Xcode project icon setting to: $APP_ICON"
else
    echo "⚠️  Project file not found: $PROJECT_FILE"
fi

echo "✅ iOS app name updated to: $APP_NAME"
echo "✅ iOS app icon updated to: $APP_ICON"

