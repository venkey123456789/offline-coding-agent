@echo off
call "%~dp0env.cmd"
if errorlevel 1 exit /b 1
set "OPENCODE_CONFIG=%AGENT_HOME%\state\opencode-config\opencode.json"
powershell -NoProfile -Command "try { $health = Invoke-RestMethod -Uri 'http://127.0.0.1:4096/global/health' -TimeoutSec 2; if ($health.healthy) { exit 0 } } catch {}; exit 1" >nul 2>nul
if not errorlevel 1 (
  start "" "http://127.0.0.1:4096"
  exit /b 0
)
"%AGENT_HOME%\tools\npm\node_modules\.bin\opencode.cmd" web --hostname 127.0.0.1 --port 4096 %*
