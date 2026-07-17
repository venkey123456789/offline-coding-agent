@echo off
call "%~dp0env.cmd"
node "%AGENT_HOME%\scripts\run-agent-profile.mjs" review %*
if errorlevel 1 (
  echo.
  echo Agent failed. Run this health check:
  echo "%AGENT_HOME%\bin\health.cmd"
  pause
)
