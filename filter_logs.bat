@echo off
echo Filtering Android logs to hide WebView and GPU noise...
echo.

REM Filter out WebView frame rate logs and GPU logs
adb logcat | findstr /V /C:"setRequestedFrameRate" /C:"GPUAUX" /C:"GuiExtAuxCheckAuxPath" /C:"WebViewChromium" /C:"WebViewProxyApi"

REM Alternative: Use grep if available
REM adb logcat | grep -v "setRequestedFrameRate\|GPUAUX\|GuiExtAuxCheckAuxPath\|WebViewChromium\|WebViewProxyApi"