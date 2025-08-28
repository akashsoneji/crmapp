@echo off
echo 🎨 Flutter Flavor Runner
echo ======================

if "%1"=="pipze" (
    echo 🟣 Running Pipze (Purple Theme)...
    flutter run -t lib/main_pipze.dart
) else if "%1"=="octa" (
    echo 🟠 Running Octa (Orange Theme)...
    flutter run -t lib/main_octa.dart
) else if "%1"=="fleza" (
    echo 🟢 Running Fleza (Green Theme)...
    flutter run -t lib/main_fleza.dart
) else (
    echo Usage: run_flavor.bat [pipze^|octa^|fleza]
    echo.
    echo Examples:
    echo   run_flavor.bat pipze  - Run Pipze (Purple)
    echo   run_flavor.bat octa   - Run Octa (Orange)
    echo   run_flavor.bat fleza  - Run Fleza (Green)
    echo.
    echo Defaulting to Pipze...
    flutter run -t lib/main_pipze.dart
)
