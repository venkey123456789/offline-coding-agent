@echo off
call "%~dp0env.cmd"
if not exist "%AGENT_HOME%\tools\python\aider-venv\Scripts\aider.exe" (
  echo Aider is not installed in "%AGENT_HOME%\tools\python\aider-venv".
  exit /b 1
)
"%AGENT_HOME%\tools\python\aider-venv\Scripts\aider.exe" --model ollama_chat/qwen3:14b %*

