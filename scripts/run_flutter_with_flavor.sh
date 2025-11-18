#!/bin/bash

# Wrapper script for VS Code launch configuration
# Reads flavor and device from files prepared by prepare-flutter-run task
# Then runs flutter with the correct arguments

FLAVOR_FILE="/tmp/vscode_flutter_flavor.txt"
DEVICE_FILE="/tmp/vscode_flutter_device.txt"
IS_IOS_FILE="/tmp/vscode_flutter_is_ios.txt"

# Read values from files (with defaults)
FLAVOR=$(cat "$FLAVOR_FILE" 2>/dev/null | tr -d '\n' || echo "tenax")
DEVICE=$(cat "$DEVICE_FILE" 2>/dev/null | tr -d '\n' || echo "emulator-5554")
IS_IOS=$(cat "$IS_IOS_FILE" 2>/dev/null | tr -d '\n' || echo "false")

echo "🎨 Using flavor: $FLAVOR"
echo "📱 Using device: $DEVICE"
echo ""

# Build flutter run command
if [ "$IS_IOS" = "true" ]; then
    # iOS doesn't need --flavor flag
    flutter run -d "$DEVICE"
else
    # Android needs --flavor flag
    flutter run --flavor "$FLAVOR" -d "$DEVICE"
fi

