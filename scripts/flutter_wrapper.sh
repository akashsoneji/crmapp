#!/bin/bash

# Lets one `flutter run --flavor <name>` command work on both Android and iOS.
#
# Android has Gradle product flavors, so the command is passed through as is.
# iOS only has the Runner scheme (no per-flavor schemes), so `flutter run
# --flavor` fails there. On an iOS device this script instead prepares the
# flavor (bundle id, name, icons, Flavor.xcconfig) with
# scripts/prepare_flavor.dart, drops --flavor, and keeps --dart-define=FLAVOR.
#
# Used as "customTool" by every config in .vscode/launch.json. It can also be
# aliased: alias flutter='bash /path/to/scripts/flutter_wrapper.sh'
#
# stdout is reserved for flutter itself (the IDE talks to `flutter run
# --machine` over it), so this script's own messages go to stderr.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

FLUTTER_BIN="flutter"
DART_BIN="dart"
if [ -n "$FLUTTER_ROOT" ] && [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
    FLUTTER_BIN="$FLUTTER_ROOT/bin/flutter"
    DART_BIN="$FLUTTER_ROOT/bin/dart"
fi

if [ "$1" != "run" ] || [[ "$*" != *"--flavor"* ]]; then
    exec "$FLUTTER_BIN" "$@"
fi

ARGS=("$@")
FLAVOR=""
DEVICE=""
for ((i = 0; i < ${#ARGS[@]}; i++)); do
    case "${ARGS[$i]}" in
        --flavor) FLAVOR="${ARGS[$((i + 1))]}" ;;
        --flavor=*) FLAVOR="${ARGS[$i]#--flavor=}" ;;
        -d | --device-id) DEVICE="${ARGS[$((i + 1))]}" ;;
        --device-id=*) DEVICE="${ARGS[$i]#--device-id=}" ;;
    esac
done

if [ -z "$FLAVOR" ]; then
    exec "$FLUTTER_BIN" "$@"
fi

# `flutter devices` lists iOS targets as "<name> • <id> • ios • <sdk>", with
# the columns padded by spaces.
IOS_COLUMN='•[[:space:]]+ios[[:space:]]+•'
DEVICES_OUTPUT=$("$FLUTTER_BIN" devices 2>/dev/null)
IS_IOS=false
AUTO_DEVICE=""
if [ -n "$DEVICE" ]; then
    if echo "$DEVICES_OUTPUT" | grep -F -- "$DEVICE" | grep -qE "$IOS_COLUMN"; then
        IS_IOS=true
    fi
elif echo "$DEVICES_OUTPUT" | grep -qE "$IOS_COLUMN"; then
    IS_IOS=true
    AUTO_DEVICE=$(echo "$DEVICES_OUTPUT" | grep -E "$IOS_COLUMN" | head -1 | awk -F'•' '{print $2}' | xargs)
fi

if [ "$IS_IOS" != true ]; then
    exec "$FLUTTER_BIN" "$@"
fi

echo "iOS device: preparing flavor '$FLAVOR' and running without --flavor..." >&2
if ! (cd "$PROJECT_DIR" && "$DART_BIN" run scripts/prepare_flavor.dart "$FLAVOR") >&2; then
    echo "scripts/prepare_flavor.dart failed for flavor '$FLAVOR'" >&2
    exit 1
fi

NEW_ARGS=()
HAS_FLAVOR_DEFINE=false
for ((i = 0; i < ${#ARGS[@]}; i++)); do
    case "${ARGS[$i]}" in
        --flavor) i=$((i + 1)) ;;
        --flavor=*) ;;
        --dart-define=FLAVOR=*)
            HAS_FLAVOR_DEFINE=true
            NEW_ARGS+=("${ARGS[$i]}")
            ;;
        *) NEW_ARGS+=("${ARGS[$i]}") ;;
    esac
done

if [ "$HAS_FLAVOR_DEFINE" != true ]; then
    NEW_ARGS+=("--dart-define=FLAVOR=$FLAVOR")
fi
if [ -n "$AUTO_DEVICE" ]; then
    NEW_ARGS+=("-d" "$AUTO_DEVICE")
fi

exec "$FLUTTER_BIN" "${NEW_ARGS[@]}"
