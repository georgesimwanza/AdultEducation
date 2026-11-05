@echo off
REM Stops the flutter run session for the phone (the app stays installed).
taskkill /FI "WINDOWTITLE eq AdultEdu Phone*" /T /F >nul 2>&1
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=adb"
"%ADB%" reverse --remove tcp:8080 >nul 2>&1
echo Phone session stopped.
