@echo off
call "%~dp0env.cmd"
ollama pull qwen3:14b
ollama pull qwen2.5-coder:1.5b
ollama pull nomic-embed-text

