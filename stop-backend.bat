@echo off
REM Stops the backend: closes its window and anything still listening on port 8080.
taskkill /FI "WINDOWTITLE eq AdultEdu Backend*" /T /F >nul 2>&1
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":8080 .*LISTENING"') do taskkill /PID %%p /T /F >nul 2>&1
echo Backend stopped.
