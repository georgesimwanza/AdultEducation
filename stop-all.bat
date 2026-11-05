@echo off
REM Stops the phone session, the web app and the backend.
cd /d "%~dp0"
call stop-phone.bat
call stop-frontend.bat
call stop-backend.bat
