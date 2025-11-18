#!/bin/bash

# Wrapper script that reads prepared values and runs Flutter
# This is called by VS Code launch configuration after prepare-flutter-run task

FLAVOR_FILE="/tmp/vscode_flutter_flavor.txt"
DEVICE_FILE="/tmp/vscode_flutter_device.txt"
IS_IOS_FILE="/tmp/vscode_flutter_is_ios.txt"

# Read values from files
FLAVOR=$(cat "$FLAVOR_FILE" 2>/dev/null | tr -d '\n' || echo "tenax")
DEVICE=$(cat "$DEVICE_FILE" 2>/dev/null | tr -d '\n' || echo "emulator-5554")
IS_IOS=$(cat "$IS_IOS_FILE" 2>/dev/null | tr -d '\n' || echo "false")

echo "🎨 Using flavor: $FLAVOR"
echo "📱 Using device: $DEVICE"
echo "🍎 Is iOS: $IS_IOS"
echo ""

# Build and run flutter command
if [ "$IS_IOS" = "true" ]; then
    # iOS doesn't need --flavor flag
    echo "🚀 Running on iOS simulator..."
    flutter run -d "$DEVICE"
else
    # Android needs --flavor flag
    echo "🚀 Running on Android emulator with flavor: $FLAVOR..."
    flutter run --flavor "$FLAVOR" -d "$DEVICE"
fi

