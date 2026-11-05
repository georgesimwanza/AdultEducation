@echo off
REM Starts the Flutter web frontend in Chrome on http://localhost:5000 in its own window.
cd /d "%~dp0adult"
REM Packages come from the local cache, so this also works without internet.
call flutter pub get --offline
start "AdultEdu Frontend" cmd /k flutter run --no-pub -d chrome --web-port 5000
echo Frontend starting on http://localhost:5000 (see "AdultEdu Frontend" window)
