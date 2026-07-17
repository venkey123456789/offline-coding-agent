@echo off
call "%~dp0env.cmd"
set "OPENCODE_CONFIG=%AGENT_HOME%\config\opencode.json"
node "%AGENT_HOME%\scripts\run-agent-profile.mjs" balanced
if errorlevel 1 pause
