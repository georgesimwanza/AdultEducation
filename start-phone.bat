@echo off
REM Runs the app on the Android phone connected by USB (USB debugging on).
REM adb reverse makes the phone's localhost:8080 reach the backend on this PC.
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=adb"
set "PHONE="
for /f "delims=" %%s in ('"%ADB%" get-serialno 2^>nul') do set "PHONE=%%s"
if "%PHONE%"=="" (echo Phone not found. Connect it and allow USB debugging. & exit /b 1)
"%ADB%" reverse tcp:8080 tcp:8080
cd /d "%~dp0adult"
REM Packages come from the local cache: the online pub step can hang on this network.
call flutter pub get --offline
start "AdultEdu Phone" cmd /k flutter run --no-pub -d %PHONE% --dart-define=BACKEND_HOST=http://localhost:8080
echo App starting on phone %PHONE% (see "AdultEdu Phone" window)
