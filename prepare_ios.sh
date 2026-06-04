#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Please specify a flavor name.${NC}"
    echo "Usage: ./prepare_ios.sh {flavor}"
    echo "Example: ./prepare_ios.sh tenax"
    exit 1
fi

FLAVOR=$1

echo -e "🚀 Preparing iOS environment for flavor: ${GREEN}${FLAVOR}${NC}..."

# Check if flavor config directory exists
if [ ! -d "lib/clients/${FLAVOR}" ]; then
    echo -e "${RED}❌ Error: Flavor '${FLAVOR}' does not exist under lib/clients/.${NC}"
    exit 1
fi

# Run the Dart flavor prep script (handles assets, icons, splash, and writes ios/Flutter/Flavor.xcconfig)
dart run scripts/prepare_flavor.dart "${FLAVOR}"

echo -e "\n${GREEN}✓ iOS environment successfully prepared for flavor: ${FLAVOR}!${NC}"
echo "You can now run or build the iOS application with:"
echo -e "  ${GREEN}flutter run --dart-define=FLAVOR=${FLAVOR}${NC}"
echo -e "  ${GREEN}flutter build ipa --dart-define=FLAVOR=${FLAVOR}${NC}"
