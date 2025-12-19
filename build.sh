#!/bin/bash

# Build script for Flutter flavors with centralized asset management
# This script automatically:
#   1. Copies client assets from lib/clients/{flavor}/assets/
#   2. Generates native splash screens with client colors
#   3. Generates launcher icons from client assets
#   4. Builds the app using centralized main.dart with auto flavor detection
#
# Usage: ./build.sh {flavor} {build_type} {mode}
# Example: ./build.sh afx apk release

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}❌ Error: Missing arguments${NC}"
    echo "Usage: ./build.sh {flavor} {build_type} [mode]"
    echo "  flavor: afx, pipze, onsa, tenax, profx"
    echo "  build_type: apk, appbundle"
    echo "  mode: release (default), debug, profile"
    echo ""
    echo "Examples:"
    echo "  ./build.sh afx apk release"
    echo "  ./build.sh pipze appbundle release"
    exit 1
fi

FLAVOR=$1
BUILD_TYPE=$2
MODE=${3:-release}

echo -e "${GREEN}🚀 Building $FLAVOR flavor ($BUILD_TYPE, $MODE mode)${NC}\n"

# Step 1: Prepare assets
echo -e "${YELLOW}📦 Step 1: Preparing client assets...${NC}"
dart run scripts/prepare_flavor.dart $FLAVOR
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to prepare assets${NC}"
    exit 1
fi

# Step 2: Build
echo -e "\n${YELLOW}🔨 Step 2: Building Flutter app...${NC}"
if [ "$MODE" == "release" ]; then
    flutter build $BUILD_TYPE --flavor $FLAVOR -t lib/main.dart --dart-define=FLAVOR=$FLAVOR --release
elif [ "$MODE" == "debug" ]; then
    flutter build $BUILD_TYPE --flavor $FLAVOR -t lib/main.dart --dart-define=FLAVOR=$FLAVOR --debug
elif [ "$MODE" == "profile" ]; then
    flutter build $BUILD_TYPE --flavor $FLAVOR -t lib/main.dart --dart-define=FLAVOR=$FLAVOR --profile
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
    echo -e "${GREEN}📱 APK location: build/app/outputs/flutter-apk/app-$FLAVOR-$MODE.apk${NC}"
elif [ "$BUILD_TYPE" == "appbundle" ]; then
    echo -e "${GREEN}📦 AAB location: build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab${NC}"
fi
