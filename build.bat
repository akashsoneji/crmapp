@echo off
REM Build script for Flutter flavors with centralized asset management (Windows)
REM This script automatically:
REM   1. Copies client assets from lib/clients/{flavor}/assets/
REM   2. Generates native splash screens with client colors
REM   3. Generates launcher icons from client assets
REM   4. Builds the app using centralized main.dart with auto flavor detection
REM
REM Usage: build.bat {flavor} {build_type} {mode}
REM Example: build.bat afx apk release

setlocal enabledelayedexpansion

REM Check arguments
if "%~1"=="" (
    echo [91m❌ Error: Missing arguments[0m
    echo Usage: build.bat {flavor} {build_type} [mode]
    echo   flavor: afx, pipze, onsa, tenax, profx
    echo   build_type: apk, appbundle
    echo   mode: release (default), debug, profile
    echo.
    echo Examples:
    echo   build.bat afx apk release
    echo   build.bat pipze appbundle release
    exit /b 1
)

if "%~2"=="" (
    echo [91m❌ Error: Missing build_type argument[0m
    echo Usage: build.bat {flavor} {build_type} [mode]
    exit /b 1
)

set FLAVOR=%~1
set BUILD_TYPE=%~2
set MODE=%~3
if "%MODE%"=="" set MODE=release

echo [92m🚀 Building %FLAVOR% flavor (%BUILD_TYPE%, %MODE% mode)[0m
echo.

REM Step 1: Prepare assets
echo [93m📦 Step 1: Preparing client assets...[0m
dart run scripts/prepare_flavor.dart %FLAVOR%
if errorlevel 1 (
    echo [91m❌ Failed to prepare assets[0m
    exit /b 1
)

REM Step 2: Build
echo.
echo [93m🔨 Step 2: Building Flutter app...[0m
if "%MODE%"=="release" (
    flutter build %BUILD_TYPE% --flavor %FLAVOR% -t lib/main.dart --dart-define=FLAVOR=%FLAVOR% --release
) else if "%MODE%"=="debug" (
    flutter build %BUILD_TYPE% --flavor %FLAVOR% -t lib/main.dart --dart-define=FLAVOR=%FLAVOR% --debug
) else if "%MODE%"=="profile" (
    flutter build %BUILD_TYPE% --flavor %FLAVOR% -t lib/main.dart --dart-define=FLAVOR=%FLAVOR% --profile
) else (
    echo [91m❌ Invalid mode: %MODE%[0m
    exit /b 1
)

if errorlevel 1 (
    echo [91m❌ Build failed[0m
    exit /b 1
)

REM Step 3: Show output location
echo.
echo [92m✅ Build completed successfully![0m
if "%BUILD_TYPE%"=="apk" (
    echo [92m📱 APK location: build\app\outputs\flutter-apk\app-%FLAVOR%-%MODE%.apk[0m
) else if "%BUILD_TYPE%"=="appbundle" (
    echo [92m📦 AAB location: build\app\outputs\bundle\%FLAVOR%Release\app-%FLAVOR%-release.aab[0m
)

endlocal
