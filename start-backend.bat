@echo off
REM Starts the Spring Boot backend on http://localhost:8080 in its own window.
REM Uses the Maven already downloaded by the wrapper (mvnw.cmd fails on this machine);
REM falls back to mvnw.cmd if no cached Maven is found.
cd /d "%~dp0backend\adult"
set "MVN=mvnw.cmd"
for /d %%d in ("%USERPROFILE%\.m2\wrapper\dists\apache-maven-*") do (
  for /d %%h in ("%%d\*") do if exist "%%h\bin\mvn.cmd" set "MVN=%%h\bin\mvn.cmd"
)
REM clean: VS Code's Java extension also writes to target and can leave it broken.
start "AdultEdu Backend" cmd /k call "%MVN%" clean spring-boot:run
echo Backend starting on http://localhost:8080 (see "AdultEdu Backend" window)
