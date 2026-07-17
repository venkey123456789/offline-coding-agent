@echo off
call "%~dp0env.cmd"
set "OPENCODE_CONFIG=%AGENT_HOME%\config\opencode.json"
"%AGENT_HOME%\tools\npm\node_modules\.bin\opencode.cmd" session list --format table %*
echo.
echo Resume a chat with: agent.cmd --session SESSION_ID
pause
