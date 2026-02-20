#!/bin/bash
# Build crmapp with AFX flavor.
# Usage:
#   ./build-afx.sh                  → afx apk release (split per ABI)
#   ./build-afx.sh universal        → afx apk release universal (single APK)
#   ./build-afx.sh appbundle        → afx appbundle release
#   ./build-afx.sh apk debug        → afx apk debug

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

FLAVOR="afx"
BUILD_TYPE="apk"
MODE="release"
EXTRA=""

case "${1:-}" in
  universal)
    BUILD_TYPE="apk"
    MODE="release"
    EXTRA="universal"
    ;;
  appbundle)
    BUILD_TYPE="appbundle"
    MODE="${2:-release}"
    ;;
  apk)
    BUILD_TYPE="apk"
    MODE="${2:-release}"
    ;;
  "")
    BUILD_TYPE="apk"
    MODE="release"
    ;;
  *)
    echo "Usage: ./build-afx.sh [universal|appbundle|apk] [release|debug|profile]"
    exit 1
    ;;
esac

if [ "$EXTRA" == "universal" ]; then
  exec ./build.sh "$FLAVOR" "$BUILD_TYPE" "$MODE" universal
else
  exec ./build.sh "$FLAVOR" "$BUILD_TYPE" "$MODE"
fi
