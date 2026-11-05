@echo off
REM Stops the frontend: closes its window and anything still listening on port 5000.
taskkill /FI "WINDOWTITLE eq AdultEdu Frontend*" /T /F >nul 2>&1
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":5000 .*LISTENING"') do taskkill /PID %%p /T /F >nul 2>&1
echo Frontend stopped.
