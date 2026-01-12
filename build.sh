#!/bin/bash

# Build script for Flutter flavors with centralized asset management
# This script automatically:
#   1. Increments version code (for release builds) - allows users to update without uninstalling
#   2. Copies client assets from lib/clients/{flavor}/assets/
#   3. Generates native splash screens with client colors
#   4. Generates launcher icons from client assets
#   5. Builds the app using centralized main.dart with auto flavor detection
#   6. Builds for Android 13+ only (arm64-v8a architecture) for smaller APK size
#
# Usage: 
#   Single client: ./build.sh {flavor} {build_type} [mode]
#   All clients:   ./build.sh all {build_type} [mode]
# Example: 
#   ./build.sh afx apk release
#   ./build.sh all apk release

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to increment version code in pubspec.yaml
# Format: version: X.Y.Z+BUILD_NUMBER
increment_version_code() {
    local PUBSPEC_FILE="pubspec.yaml"
    
    if [ ! -f "$PUBSPEC_FILE" ]; then
        echo -e "${YELLOW}⚠️  Warning: pubspec.yaml not found, skipping version increment${NC}"
        return 0
    fi
    
    # Read current version
    local CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //' | tr -d ' ')
    
    if [ -z "$CURRENT_VERSION" ]; then
        echo -e "${YELLOW}⚠️  Warning: Could not find version in pubspec.yaml${NC}"
        return 0
    fi
    
    # Extract version name and build number
    local VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
    local BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)
    
    # If no build number exists, start at 1
    if [ -z "$BUILD_NUMBER" ] || [ "$BUILD_NUMBER" == "$CURRENT_VERSION" ]; then
        BUILD_NUMBER=1
    else
        # Increment build number
        BUILD_NUMBER=$((BUILD_NUMBER + 1))
    fi
    
    # Create new version string
    local NEW_VERSION="${VERSION_NAME}+${BUILD_NUMBER}"
    
    # Update pubspec.yaml
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^version:.*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
    else
        # Linux
        sed -i "s/^version:.*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
    fi
    
    echo -e "${GREEN}📈 Version updated: $CURRENT_VERSION → $NEW_VERSION${NC}"
    return 0
}

# Function to build a single flavor
build_flavor() {
    local FLAVOR=$1
    local BUILD_TYPE=$2
    local MODE=$3
    local SKIP_VERSION_INCREMENT=${4:-false}
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🚀 Building $FLAVOR flavor ($BUILD_TYPE, $MODE mode)${NC}"
    echo -e "${BLUE}📱 Target: Android 13+ (arm64-v8a only)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Step 0: Increment version code for release builds (so users can update without uninstalling)
    # Skip if building multiple clients (version already incremented)
    if [ "$MODE" == "release" ] && [ "$SKIP_VERSION_INCREMENT" != "true" ]; then
        echo -e "${YELLOW}📈 Step 0: Incrementing version code...${NC}"
        increment_version_code
        echo ""
    fi
    
    # Step 1: Prepare assets
    echo -e "${YELLOW}📦 Step 1: Preparing client assets for $FLAVOR...${NC}"
    if ! dart run scripts/prepare_flavor.dart $FLAVOR; then
        echo -e "${RED}❌ Failed to prepare assets for $FLAVOR${NC}"
        return 1
    fi
    
    # Step 2: Build
    echo -e "\n${YELLOW}🔨 Step 2: Building Flutter app for $FLAVOR (arm64-v8a only)...${NC}"
    local BUILD_CMD=""
    if [ "$MODE" == "release" ]; then
        BUILD_CMD="flutter build $BUILD_TYPE --flavor $FLAVOR --dart-define=FLAVOR=$FLAVOR --release --target-platform android-arm64"
    elif [ "$MODE" == "debug" ]; then
        BUILD_CMD="flutter build $BUILD_TYPE --flavor $FLAVOR --dart-define=FLAVOR=$FLAVOR --debug --target-platform android-arm64"
    elif [ "$MODE" == "profile" ]; then
        BUILD_CMD="flutter build $BUILD_TYPE --flavor $FLAVOR --dart-define=FLAVOR=$FLAVOR --profile --target-platform android-arm64"
    else
        echo -e "${RED}❌ Invalid mode: $MODE${NC}"
        return 1
    fi
    
    if ! $BUILD_CMD; then
        echo -e "${RED}❌ Build failed for $FLAVOR${NC}"
        return 1
    fi
    
    # Step 3: Show output location
    echo -e "\n${GREEN}✅ Build completed successfully for $FLAVOR!${NC}"
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
        AAB_PATH="build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"
        if [ -f "$AAB_PATH" ]; then
            AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
            echo -e "${GREEN}📦 AAB location: $AAB_PATH${NC}"
            echo -e "${GREEN}📦 AAB size: $AAB_SIZE${NC}"
        else
            echo -e "${GREEN}📦 AAB location: $AAB_PATH${NC}"
        fi
    fi
    echo -e "${BLUE}ℹ️  Built for Android 13+ (arm64-v8a architecture only)${NC}"
    
    return 0
}

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}❌ Error: Missing arguments${NC}"
    echo ""
    echo "Usage:"
    echo "  Single client: ./build.sh {flavor} {build_type} [mode]"
    echo "  All clients:   ./build.sh all {build_type} [mode]"
    echo ""
    echo "Arguments:"
    echo "  flavor: afx, pipze, onsa, tenax, profx, tradoxy, or 'all'"
    echo "  build_type: apk, appbundle"
    echo "  mode: release (default), debug, profile"
    echo ""
    echo "Examples:"
    echo "  ./build.sh afx apk release"
    echo "  ./build.sh all apk release"
    echo "  ./build.sh pipze appbundle release"
    echo ""
    echo -e "${BLUE}ℹ️  Note: Building for Android 13+ only (arm64-v8a) for optimal APK size${NC}"
    exit 1
fi

FLAVOR=$1
BUILD_TYPE=$2
MODE=${3:-release}

# Validate build type
if [ "$BUILD_TYPE" != "apk" ] && [ "$BUILD_TYPE" != "appbundle" ]; then
    echo -e "${RED}❌ Invalid build_type: $BUILD_TYPE${NC}"
    echo "  build_type must be: apk or appbundle"
    exit 1
fi

# Validate mode
if [ "$MODE" != "release" ] && [ "$MODE" != "debug" ] && [ "$MODE" != "profile" ]; then
    echo -e "${RED}❌ Invalid mode: $MODE${NC}"
    echo "  mode must be: release, debug, or profile"
    exit 1
fi

# Build all clients if "all" is specified
if [ "$FLAVOR" == "all" ]; then
    # Define all clients to build
    CLIENTS=("tradoxy" "tenax" "afx" "onsa" "pipze")
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🚀 Building ALL clients: ${CLIENTS[*]}${NC}"
    echo -e "${BLUE}📱 Build type: $BUILD_TYPE | Mode: $MODE${NC}"
    echo -e "${BLUE}📱 Target: Android 13+ (arm64-v8a only)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Increment version code once for all builds (only for release mode)
    if [ "$MODE" == "release" ]; then
        echo -e "${YELLOW}📈 Incrementing version code for all builds...${NC}"
        increment_version_code
        echo ""
    fi
    
    # Track results
    SUCCESSFUL=()
    FAILED=()
    START_TIME=$(date +%s)
    
    # Build each client (skip version increment since we did it once above)
    for CLIENT in "${CLIENTS[@]}"; do
        CLIENT_START=$(date +%s)
        if build_flavor "$CLIENT" "$BUILD_TYPE" "$MODE" "true"; then
            SUCCESSFUL+=("$CLIENT")
            CLIENT_END=$(date +%s)
            CLIENT_DURATION=$((CLIENT_END - CLIENT_START))
            echo -e "${GREEN}✅ $CLIENT completed in ${CLIENT_DURATION}s${NC}"
        else
            FAILED+=("$CLIENT")
            CLIENT_END=$(date +%s)
            CLIENT_DURATION=$((CLIENT_END - CLIENT_START))
            echo -e "${RED}❌ $CLIENT failed after ${CLIENT_DURATION}s${NC}"
        fi
    done
    
    # Summary
    END_TIME=$(date +%s)
    TOTAL_DURATION=$((END_TIME - START_TIME))
    TOTAL_MINUTES=$((TOTAL_DURATION / 60))
    TOTAL_SECONDS=$((TOTAL_DURATION % 60))
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📊 BUILD SUMMARY${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Successful builds: ${#SUCCESSFUL[@]}/${#CLIENTS[@]}${NC}"
    if [ ${#SUCCESSFUL[@]} -gt 0 ]; then
        echo -e "${GREEN}   Clients: ${SUCCESSFUL[*]}${NC}"
    fi
    
    if [ ${#FAILED[@]} -gt 0 ]; then
        echo -e "${RED}❌ Failed builds: ${#FAILED[@]}/${#CLIENTS[@]}${NC}"
        echo -e "${RED}   Clients: ${FAILED[*]}${NC}"
    fi
    
    echo -e "${BLUE}⏱️  Total time: ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Show output locations
    if [ ${#SUCCESSFUL[@]} -gt 0 ]; then
        echo -e "${GREEN}📱 Output files:${NC}"
        for CLIENT in "${SUCCESSFUL[@]}"; do
            if [ "$BUILD_TYPE" == "apk" ]; then
                APK_PATH="build/app/outputs/flutter-apk/app-$CLIENT-$MODE.apk"
                if [ -f "$APK_PATH" ]; then
                    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
                    echo -e "  ${GREEN}✓${NC} $CLIENT: $APK_PATH ($APK_SIZE)"
                fi
            elif [ "$BUILD_TYPE" == "appbundle" ]; then
                AAB_PATH="build/app/outputs/bundle/${CLIENT}Release/app-$CLIENT-release.aab"
                if [ -f "$AAB_PATH" ]; then
                    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
                    echo -e "  ${GREEN}✓${NC} $CLIENT: $AAB_PATH ($AAB_SIZE)"
                fi
            fi
        done
        echo ""
    fi
    
    # Exit with error if any builds failed
    if [ ${#FAILED[@]} -gt 0 ]; then
        exit 1
    fi
else
    # Build single client
    if ! build_flavor "$FLAVOR" "$BUILD_TYPE" "$MODE"; then
        exit 1
    fi
fi