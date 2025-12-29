# Fix for iOS Flavor Error

## Problem
When running `flutter run --flavor <flavor>` on iOS, you get:
```
Error: The Xcode project does not define custom schemes. You cannot use the --flavor option.
```

## Solution

Since we removed all custom Xcode schemes and only have the default Runner scheme, Flutter iOS doesn't support the `--flavor` flag. Instead, we use `--dart-define=FLAVOR=<flavor>`.

## Quick Fix Options

### Option 1: Use the Wrapper Script (Recommended)

Use one of these scripts that automatically handle the conversion:

```bash
# Direct script usage
bash scripts/run_ios_flavor.sh pipze

# Or use the universal wrapper (if aliased)
flutter run --flavor pipze  # (if flutter is aliased to flutter_wrapper.sh)
```

### Option 2: Use --dart-define Directly

Instead of:
```bash
flutter run --flavor pipze
```

Use:
```bash
# First update iOS config
bash scripts/update_ios_flavor.sh pipze

# Then run with --dart-define
flutter run --dart-define=FLAVOR=pipze -d <device>
```

### Option 3: Alias Flutter Command (Best for Daily Use)

Add this to your `~/.zshrc` or `~/.bashrc`:

```bash
# Auto-convert --flavor to --dart-define for iOS
alias flutter='bash /path/to/your/project/scripts/flutter_wrapper.sh'
```

Then you can use `flutter run --flavor pipze` normally, and it will automatically convert for iOS.

## How It Works

1. **For iOS**: 
   - Scripts call `update_ios_flavor.sh` to update app name/icon
   - Then use `--dart-define=FLAVOR=<flavor>` instead of `--flavor`
   - Your `main.dart` reads the flavor from the environment variable

2. **For Android**: 
   - Uses `--flavor` flag as normal (no changes needed)

## Available Scripts

- `scripts/run_ios_flavor.sh <flavor>` - Run on iOS with specific flavor
- `scripts/flutter_wrapper.sh` - Universal wrapper (can alias to 'flutter')
- `scripts/flutter_ios` - iOS-specific wrapper
- `scripts/update_ios_flavor.sh <flavor>` - Update iOS app name/icon only

## Testing

```bash
# Test iOS
bash scripts/run_ios_flavor.sh pipze

# Test Android (unchanged)
flutter run --flavor pipze -d <android-device>
```

