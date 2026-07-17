@echo off
call "%~dp0env.cmd"
if errorlevel 1 exit /b 1
set "OPENCODE_CONFIG=%AGENT_HOME%\state\opencode-config\opencode.json"
"%AGENT_HOME%\tools\npm\node_modules\.bin\opencode.cmd" session list --format table %*
echo.
echo Resume a chat with: agent.cmd --session SESSION_ID
pause
