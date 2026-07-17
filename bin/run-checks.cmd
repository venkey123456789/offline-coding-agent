@echo off
call "%~dp0env.cmd"
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGENT_HOME%\scripts\run-checks.ps1" %*
