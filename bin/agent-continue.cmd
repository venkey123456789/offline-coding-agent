@echo off
call "%~dp0env.cmd"
set "OPENCODE_CONFIG=%AGENT_HOME%\config\opencode.json"
"%AGENT_HOME%\tools\npm\node_modules\.bin\opencode.cmd" --continue %*
if errorlevel 1 pause
