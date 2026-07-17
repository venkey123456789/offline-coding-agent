@echo off
call "%~dp0env.cmd"
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGENT_HOME%\scripts\snapshot.ps1" %*
