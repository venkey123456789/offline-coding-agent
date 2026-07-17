$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $root 'bin\env.ps1')

Write-Host "ROOT=$root"
Write-Host "OLLAMA_HOST=$env:OLLAMA_HOST"
Write-Host "OLLAMA_MODELS=$env:OLLAMA_MODELS"

try {
  $models = Invoke-RestMethod "http://$env:OLLAMA_HOST/api/tags" -TimeoutSec 5
  Write-Host 'OLLAMA_API=OK'
  $models.models | Select-Object name,size | Format-Table -AutoSize
} catch {
  Write-Host "OLLAMA_API=FAIL $($_.Exception.Message)"
}

Write-Host 'TOOLS='
& (Join-Path $root 'tools\npm\node_modules\.bin\opencode.cmd') --version
& (Join-Path $root 'tools\npm\node_modules\.bin\cn.cmd') --version
& (Join-Path $root 'tools\python\aider-venv\Scripts\aider.exe') --version
& (Join-Path $root 'tools\python\aider-venv\Scripts\ruff.exe') --version
& (Join-Path $root 'tools\python\aider-venv\Scripts\python.exe') -m pytest --version

Write-Host 'MCP='
node (Join-Path $root 'scripts\check-mcp.mjs')

Write-Host 'AUDIT='
npm audit --prefix (Join-Path $root 'tools\npm') --omit=dev

$bad = Select-String -Path (Join-Path $root 'config\*.json'),(Join-Path $root 'config\*.yaml'),(Join-Path $root 'bin\*.cmd') -Pattern 'api.openai.com|githubcopilot|mcp.figma.com|mcp.canva.com|replit-mcp|NVIDIA_API_KEY|CODERABBIT|BRAVE_API_KEY' -ErrorAction SilentlyContinue
if ($bad) {
  Write-Host 'PAID_OR_ACCOUNT_ADAPTERS=FOUND'
  $bad | ForEach-Object { Write-Host "$($_.Path):$($_.LineNumber): $($_.Line)" }
  exit 1
}
Write-Host 'PAID_OR_ACCOUNT_ADAPTERS=NONE'
