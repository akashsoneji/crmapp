@echo off
echo 🏗️ Flutter Flavor Builder
echo =======================

if "%1"=="" (
    echo Usage: build_flavor.bat [pipze^|octa^|fleza] [aab^|apk]
    echo.
    echo Examples:
    echo   build_flavor.bat pipze aab   - Build Pipze AAB
    echo   build_flavor.bat octa apk    - Build Octa APK
    echo   build_flavor.bat fleza aab   - Build Fleza AAB
    echo.
    echo Defaulting to Pipze AAB...
    flutter build appbundle --flavor pipze --release
    goto :end
)

if "%2"=="aab" (
    echo 🟣 Building %1 AAB (App Bundle)...
    flutter build appbundle --flavor %1 --release
) else if "%2"=="apk" (
    echo 🟣 Building %1 APK...
    flutter build apk --flavor %1 --release
) else (
    echo 🟣 Building %1 AAB (default)...
    flutter build appbundle --flavor %1 --release
)

:end
echo.
echo ✅ Build completed! Check build/app/outputs/ folder
pause
