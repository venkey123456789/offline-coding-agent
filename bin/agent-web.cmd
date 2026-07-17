@echo off
call "%~dp0env.cmd"
set "OPENCODE_CONFIG=%AGENT_HOME%\config\opencode.json"
"%AGENT_HOME%\tools\npm\node_modules\.bin\opencode.cmd" web --hostname 127.0.0.1 --port 4096 %*

