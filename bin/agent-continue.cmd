@echo off
call "%~dp0env.cmd"
if errorlevel 1 exit /b 1
set "OPENCODE_CONFIG=%AGENT_HOME%\state\opencode-config\opencode.json"
"%AGENT_HOME%\tools\npm\node_modules\.bin\opencode.cmd" --continue %*
if errorlevel 1 pause
