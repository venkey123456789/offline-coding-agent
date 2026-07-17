@echo off
set "AGENT_HOME=%~dp0.."
for %%I in ("%AGENT_HOME%") do set "AGENT_HOME=%%~fI"

set "OLLAMA_MODELS=%AGENT_HOME%\models\ollama"
set "HF_HOME=%AGENT_HOME%\cache\huggingface"
set "HF_HUB_CACHE=%HF_HOME%\hub"
set "TRANSFORMERS_CACHE=%HF_HOME%\transformers"
set "XDG_CACHE_HOME=%AGENT_HOME%\cache"
set "XDG_DATA_HOME=%AGENT_HOME%\state\opencode"
set "XDG_STATE_HOME=%AGENT_HOME%\state"
set "PIP_CACHE_DIR=%AGENT_HOME%\cache\pip"
set "NPM_CONFIG_CACHE=%AGENT_HOME%\cache\npm"
set "UV_CACHE_DIR=%AGENT_HOME%\cache\uv"
set "PLAYWRIGHT_BROWSERS_PATH=%AGENT_HOME%\cache\ms-playwright"
set "CONTINUE_GLOBAL_DIR=%AGENT_HOME%\state\continue"

set "OPENCODE_CONFIG=%AGENT_HOME%\config\opencode.json"
set "OPENCODE_CONFIG_DIR=%AGENT_HOME%\config"
set "OPENCODE_DISABLE_AUTOUPDATE=true"
set "OPENCODE_DISABLE_PRUNE=true"

set "OLLAMA_HOST=127.0.0.1:11435"
set "OLLAMA_API_BASE=http://127.0.0.1:11435"
set "OLLAMA_CONTEXT_LENGTH=32768"

set "AGENT_PLUGIN_URL=file:///%AGENT_HOME:\=/%/config/plugins/persistent-memory.js"
set "AGENT_MEMORY_CONTEXT=%AGENT_HOME%\config\automatic-context.md"
set "PATH=%AGENT_HOME%\bin;%AGENT_HOME%\tools\npm\node_modules\.bin;%AGENT_HOME%\tools\python\aider-venv\Scripts;%PATH%"

if not exist "%OLLAMA_MODELS%" mkdir "%OLLAMA_MODELS%" >nul 2>nul
if not exist "%HF_HOME%" mkdir "%HF_HOME%" >nul 2>nul
if not exist "%CONTINUE_GLOBAL_DIR%" mkdir "%CONTINUE_GLOBAL_DIR%" >nul 2>nul
if not exist "%XDG_DATA_HOME%" mkdir "%XDG_DATA_HOME%" >nul 2>nul
