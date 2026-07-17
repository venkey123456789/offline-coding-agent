@echo off
call "%~dp0env.cmd"
if errorlevel 1 exit /b 1
set "OPENCODE_CONFIG=%AGENT_HOME%\state\opencode-config\opencode-online.json"
if not exist "%AGENT_HOME%\tools\npm\node_modules\.bin\opencode.cmd" (
  echo OpenCode is not installed. Run: npm install --prefix "%AGENT_HOME%\tools\npm" opencode-ai
  exit /b 1
)
node "%AGENT_HOME%\scripts\sync-conversation-memory.mjs" >nul 2>nul
"%AGENT_HOME%\tools\npm\node_modules\.bin\opencode.cmd" %*
node "%AGENT_HOME%\scripts\sync-conversation-memory.mjs" >nul 2>nul
