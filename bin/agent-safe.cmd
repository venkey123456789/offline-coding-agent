@echo off
call "%~dp0env.cmd"
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGENT_HOME%\scripts\snapshot.ps1" -ProjectPath "%CD%" >nul
if "%~1"=="" (
  node "%AGENT_HOME%\scripts\run-agent-profile.mjs" balanced --continue
) else (
  node "%AGENT_HOME%\scripts\run-agent-profile.mjs" balanced %*
)
if errorlevel 1 (
  echo.
  echo Agent failed. Run this health check:
  echo "%AGENT_HOME%\bin\health.cmd"
  pause
)
