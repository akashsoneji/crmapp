#!/bin/bash

# Build script for Flutter flavors with centralized asset management
# This script automatically:
#   1. Copies client assets from lib/clients/{flavor}/assets/
#   2. Generates native splash screens with client colors
#   3. Generates launcher icons from client assets
#   4. Builds the app using centralized main.dart with auto flavor detection
#   5. Builds for Android 13+ only (arm64-v8a architecture) for smaller APK size
#
# Usage: ./build.sh {flavor} {build_type} [mode]
# Example: ./build.sh afx apk release

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}❌ Error: Missing arguments${NC}"
    echo "Usage: ./build.sh {flavor} {build_type} [mode]"
    echo "  flavor: afx, pipze, onsa, tenax, profx, tradoxy"
    echo "  build_type: apk, appbundle"
    echo "  mode: release (default), debug, profile"
    echo ""
    echo "Examples:"
    echo "  ./build.sh afx apk release"
    echo "  ./build.sh pipze appbundle release"
    echo ""
    echo -e "${BLUE}ℹ️  Note: Building for Android 13+ only (arm64-v8a) for optimal APK size${NC}"
    exit 1
fi

FLAVOR=$1
BUILD_TYPE=$2
MODE=${3:-release}

echo -e "${GREEN}🚀 Building $FLAVOR flavor ($BUILD_TYPE, $MODE mode)${NC}"
echo -e "${BLUE}📱 Target: Android 13+ (arm64-v8a only)${NC}\n"

# Step 1: Prepare assets
echo -e "${YELLOW}📦 Step 1: Preparing client assets...${NC}"
dart run scripts/prepare_flavor.dart $FLAVOR
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to prepare assets${NC}"
    exit 1
fi

# Step 2: Build
echo -e "\n${YELLOW}🔨 Step 2: Building Flutter app (arm64-v8a only)...${NC}"
if [ "$MODE" == "release" ]; then
    flutter build $BUILD_TYPE --flavor $FLAVOR --dart-define=FLAVOR=$FLAVOR --release --target-platform android-arm64
elif [ "$MODE" == "debug" ]; then
    flutter build $BUILD_TYPE --flavor $FLAVOR --dart-define=FLAVOR=$FLAVOR --debug --target-platform android-arm64
elif [ "$MODE" == "profile" ]; then
    flutter build $BUILD_TYPE --flavor $FLAVOR --dart-define=FLAVOR=$FLAVOR --profile --target-platform android-arm64
else
    echo -e "${RED}❌ Invalid mode: $MODE${NC}"
    exit 1
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Step 3: Show output location
echo -e "\n${GREEN}✅ Build completed successfully!${NC}"
if [ "$BUILD_TYPE" == "apk" ]; then
    APK_PATH="build/app/outputs/flutter-apk/app-$FLAVOR-$MODE.apk"
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo -e "${GREEN}📱 APK location: $APK_PATH${NC}"
        echo -e "${GREEN}📦 APK size: $APK_SIZE${NC}"
    else
        echo -e "${GREEN}📱 APK location: $APK_PATH${NC}"
    fi
elif [ "$BUILD_TYPE" == "appbundle" ]; then
    echo -e "${GREEN}📦 AAB location: build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab${NC}"
fi
echo -e "${BLUE}ℹ️  Built for Android 13+ (arm64-v8a architecture only)${NC}"