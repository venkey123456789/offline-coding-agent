@echo off
call "%~dp0env.cmd"
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGENT_HOME%\scripts\render-continue-config.ps1" >nul
"%AGENT_HOME%\tools\npm\node_modules\.bin\cn.cmd" %*
