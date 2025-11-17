#!/bin/bash

# Pre-build script for Flutter iOS
# Updates iOS app name and icon based on FlavorConfig in main.dart
# This script runs automatically before Flutter builds iOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Run the flavor update script
bash "$SCRIPT_DIR/update_ios_flavor.sh"

