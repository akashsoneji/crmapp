@echo off
REM Generate Launcher Icons for Each Flavor
REM Make sure you have the logo files ready before running this

echo ================================================
echo Generating Launcher Icons for All Flavors
echo ================================================
echo.

echo.
echo NOTE: This script requires you to have already created
echo the logo image files in assets/image/ directory:
echo - onsadb_logo.png (for ONSA)
echo - octa_logo.png (for Octa)
echo - fleza_logo.png (for Fleza)
echo - splash_logo.png (for Pipze - already exists)
echo.

pause

echo.
echo Step 1: Generating icons for each flavor...
echo.

REM Generate icons using flutter_launcher_icons
echo Generating icons for ONSA...
flutter pub run flutter_launcher_icons -f flutter_launcher_icons_onsa.yaml

echo.
echo ================================================
echo IMPORTANT: You need to manually copy the generated icons
echo from android/app/src/main/res/mipmap-* to:
echo - android/app/src/onsa/res/mipmap-*/
echo - android/app/src/pipze/res/mipmap-*/
echo - android/app/src/octa/res/mipmap-*/
echo - android/app/src/fleza/res/mipmap-*/
echo ================================================
echo.

pause

echo.
echo Done! Now copy the icons to flavor-specific directories.
echo.

