@echo off
REM Starts the backend, the web app in Chrome and, if a phone is plugged in
REM with USB debugging on, the app on the phone.
cd /d "%~dp0"
call start-backend.bat
call start-frontend.bat
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=adb"
"%ADB%" get-serialno >nul 2>&1 && call start-phone.bat || echo No phone connected - skipping the phone.
