@echo off
call "%~dp0env.cmd"
if errorlevel 1 exit /b 1
set "OPENCODE_CONFIG=%AGENT_HOME%\state\opencode-config\opencode.json"
node "%AGENT_HOME%\scripts\run-agent-profile.mjs" balanced
if errorlevel 1 pause
