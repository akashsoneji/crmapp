# Splash Screen Background Color Fix

## Issue Fixed

### Problem
The splash screen background was always showing purple color regardless of which app flavor (Pipze, Octa, Fleza, or ONSA) was being used. The user expected the splash screen to display the correct brand color.

### Root Cause
The splash screen background was hardcoded to purple (`Color(0xFF692EAF)`) in the Flutter code:
- **Line 101** in `lib/screens/auth/splash/splash_screen.dart`: `color: const Color(0xFF692EAF)`
- Android native splash colors were not defined for each flavor

## Solution Implemented

### 1. Flutter Splash Screen (Dynamic)
Changed the hardcoded purple color to use the brand's primary color dynamically:

```dart
// Before:
color: const Color(0xFF692EAF),

// After:
color: FlavorConfig.instance.primaryColor,
```

Now the splash screen will use:
- **Pipze**: Purple `#5A2DD8`
- **Octa**: Orange `#FF6B35`
- **Fleza**: Green `#4CAF50`
- **ONSA**: Blue `#193FAD` (with gradient in Flutter layer)

### 2. Android Native Splash Screen
Added flavor-specific splash colors to each flavor's `colors.xml`:

#### `android/app/src/pipze/res/values/colors.xml`
```xml
<color name="my_splash_color">#5A2DD8</color> <!-- Pipze Purple -->
```

#### `android/app/src/octa/res/values/colors.xml`
```xml
<color name="my_splash_color">#FF6B35</color> <!-- Octa Orange -->
```

#### `android/app/src/fleza/res/values/colors.xml`
```xml
<color name="my_splash_color">#4CAF50</color> <!-- Fleza Green -->
```

#### `android/app/src/onsa/res/values/colors.xml`
```xml
<color name="my_splash_color">#193FAD</color> <!-- ONSA Blue -->
```

## How It Works

### Splash Screen Architecture
1. **Native Android Splash**: Shows immediately when app launches using `launch_background.xml` which references `@color/my_splash_color`
2. **Flutter Splash**: Takes over after native splash, shows custom logo and animations

### Color Progression
- **App Launch**: Native splash shows flavor-specific color (orange for Octa, green for Fleza, etc.)
- **Flutter Starts**: Splash screen widget displays with matching color
- **Content Load**: Transitions to authentication or main app screen

## Brand Colors

| Brand | Primary Color | Hex Code |
|-------|--------------|----------|
| **Pipze** | Purple | `#5A2DD8` |
| **Octa** | Orange | `#FF6B35` |
| **Fleza** | Green | `#4CAF50` |
| **ONSA** | Blue | `#193FAD` |

## Files Modified

1. `lib/screens/auth/splash/splash_screen.dart`
   - Line 101: Changed from hardcoded purple to `FlavorConfig.instance.primaryColor`

2. `android/app/src/pipze/res/values/colors.xml`
   - Added `my_splash_color` with Pipze purple

3. `android/app/src/octa/res/values/colors.xml`
   - Added `my_splash_color` with Octa orange

4. `android/app/src/fleza/res/values/colors.xml`
   - Added `my_splash_color` with Fleza green

5. `android/app/src/onsa/res/values/colors.xml`
   - Added `my_splash_color` with ONSA blue

## Testing

### Test Each Flavor
1. **Build with different flavor**: Use the flavor-specific build commands
2. **Check splash screen**: Verify color matches brand identity
3. **Verify transition**: Ensure smooth transition to login/main screen

### Expected Results
- ✅ Pipze: Purple splash screen
- ✅ Octa: Orange splash screen
- ✅ Fleza: Green splash screen
- ✅ ONSA: Blue gradient splash screen

## Benefits

1. **Brand Consistency**: Each flavor now shows its unique brand color
2. **Professional Appearance**: Splash screen matches app branding
3. **Dynamic Configuration**: Easy to add new flavors in the future
4. **Platform Integration**: Both native and Flutter layers use correct colors

## Notes

- ONSA has a special gradient implementation in the Flutter code layer
- The native splash color is the start color (blue) for ONSA
- All other flavors use solid colors matching their primary brand color

