@echo off
call "%~dp0env.cmd"
node "%AGENT_HOME%\scripts\index-workspace.mjs" search %*
