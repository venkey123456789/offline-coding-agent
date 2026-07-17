@echo off
call "%~dp0env.cmd"
powershell -NoProfile -ExecutionPolicy Bypass -File "%AGENT_HOME%\scripts\render-continue-config.ps1" >nul
if "%~1"=="" (
  code --user-data-dir "%AGENT_HOME%\state\vscode-user" --extensions-dir "%AGENT_HOME%\tools\vscode-extensions" "%CD%"
) else (
  code --user-data-dir "%AGENT_HOME%\state\vscode-user" --extensions-dir "%AGENT_HOME%\tools\vscode-extensions" %*
)
