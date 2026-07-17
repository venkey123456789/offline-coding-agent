@echo off
call "%~dp0env.cmd"
where ollama >nul 2>nul
if errorlevel 1 (
  echo Ollama is not installed or not on PATH.
  exit /b 1
)
if /I "%~1"=="serve" (
  ollama serve
  exit /b %ERRORLEVEL%
)
if /I "%~1"=="list" (
  ollama list
  exit /b %ERRORLEVEL%
)
if /I "%~1"=="pull" (
  shift
  ollama pull %*
  exit /b %ERRORLEVEL%
)
echo OLLAMA_MODELS=%OLLAMA_MODELS%
ollama --version
ollama list

