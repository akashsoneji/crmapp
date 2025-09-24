@echo off
echo Setting up clean Android logging...
echo.

REM Clear existing logs
adb logcat -c

REM Set log level to reduce noise (only show ERROR and above)
adb logcat *:E

echo.
echo Log level set to ERROR only. Use Ctrl+C to stop.
echo For more verbose logging, use: adb logcat *:W
echo For debug level: adb logcat *:D
echo.
