$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $root 'bin\env.ps1')

function Invoke-Smoke {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [string[]]$Arguments = @()
  )
  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Smoke command failed with exit code ${LASTEXITCODE}: $FilePath $($Arguments -join ' ')"
  }
}

Invoke-Smoke -FilePath (Join-Path $root 'tools\npm\node_modules\.bin\opencode.cmd') -Arguments @('--version')
Invoke-Smoke -FilePath (Join-Path $root 'tools\npm\node_modules\.bin\cn.cmd') -Arguments @('--version')
Invoke-Smoke -FilePath (Join-Path $root 'tools\python\aider-venv\Scripts\aider.exe') -Arguments @('--version')
Invoke-Smoke -FilePath (Join-Path $root 'tools\python\aider-venv\Scripts\mcp-server-git.exe') -Arguments @('--help')

try {
  Invoke-RestMethod 'http://127.0.0.1:11435/api/tags' -TimeoutSec 5 | Out-Null
  Write-Host 'OLLAMA_API_OK'
} catch {
  Write-Host 'OLLAMA_API_NOT_RUNNING'
}

Write-Host 'SMOKE_LOCAL_DONE'
