@echo off
REM Runs the app on the phone over Wi-Fi (phone and PC on the same network).
REM The phone must already be paired with: adb pair / adb connect (Wireless debugging).
REM The app reaches the backend on this PC's Wi-Fi address instead of over USB.
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=adb"
set "PHONE="
for /f "delims=" %%s in ('"%ADB%" get-serialno 2^>nul') do set "PHONE=%%s"
if "%PHONE%"=="" (echo Phone not found. Turn on Wireless debugging and run adb connect. & exit /b 1)
set "PCIP="
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1).IPv4Address.IPAddress"') do set "PCIP=%%i"
if "%PCIP%"=="" (echo Could not find this PC's network address. & exit /b 1)
cd /d "%~dp0adult"
REM Packages come from the local cache, so this also works without internet.
call flutter pub get --offline
start "AdultEdu Phone" cmd /k flutter run --no-pub -d %PHONE% --dart-define=BACKEND_HOST=http://%PCIP%:8080
echo App starting on phone %PHONE%, backend at http://%PCIP%:8080 (see "AdultEdu Phone" window)
