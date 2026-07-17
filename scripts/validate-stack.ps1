$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $root 'bin\env.ps1')

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [string[]]$Arguments = @()
  )
  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($Arguments -join ' ')"
  }
}

$required = @(
  'bin\agent.cmd',
  'bin\agent-router.cmd',
  'bin\agent-fast.cmd',
  'bin\agent-deep.cmd',
  'bin\agent-review.cmd',
  'bin\agent-safe.cmd',
  'bin\agent-new.cmd',
  'bin\agent-continue.cmd',
  'bin\agent-history.cmd',
  'bin\agent-web.cmd',
  'bin\vscode-agent.cmd',
  'bin\aider-local.cmd',
  'bin\ollama-local.cmd',
  'bin\health.cmd',
  'bin\snapshot.cmd',
  'bin\run-checks.cmd',
  'bin\index-project.cmd',
  'bin\search-project.cmd',
  'bin\new-project.cmd',
  'bin\eval-local.cmd',
  'bin\cache-free-deps.cmd',
  'bin\pull-models.cmd',
  'bin\pull-large-model.cmd',
  'bin\pull-gpt-oss.cmd',
  'bin\env.ps1',
  'config\opencode.json',
  'config\opencode-online.json',
  'config\mcp-local.json',
  'config\mcp-online.json',
  'config\continue-config.yaml',
  'config\model-routing.json',
  'config\free-modes.json',
  'config\agent-instructions.md',
  'scripts\conversation-memory-mcp.mjs',
  'scripts\sync-conversation-memory.mjs',
  'scripts\render-continue-config.ps1',
  'config\plugins\persistent-memory.js',
  'config\automatic-context.md',
  'runtime\npm\package.json',
  'runtime\npm\package-lock.json',
  'runtime\requirements.txt',
  'tools\npm\node_modules\.bin\opencode.cmd',
  'tools\npm\node_modules\.bin\cn.cmd',
  'tools\python\aider-venv\Scripts\aider.exe',
  'tools\python\aider-venv\Scripts\mcp-server-git.exe',
  'tools\python\aider-venv\Scripts\pytest.exe',
  'tools\python\aider-venv\Scripts\ruff.exe'
)

foreach ($relative in $required) {
  $path = Join-Path $root $relative
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing required path: $path"
  }
}

foreach ($jsonFile in @('opencode.json', 'opencode-online.json', 'mcp-local.json', 'mcp-online.json', 'model-routing.json', 'free-modes.json')) {
  Get-Content (Join-Path $root "config\$jsonFile") -Raw | ConvertFrom-Json | Out-Null
}

$continueConfig = Join-Path $root 'config\continue-config.yaml'
Invoke-Checked -FilePath 'node' -Arguments @('-e', "const fs=require('fs'); const YAML=require('yaml'); YAML.parse(fs.readFileSync(process.argv[1],'utf8'));", $continueConfig) | Out-Null
Invoke-Checked -FilePath 'node' -Arguments @('--check', (Join-Path $root 'scripts\project-tools-mcp.mjs')) | Out-Null
Invoke-Checked -FilePath 'node' -Arguments @('--check', (Join-Path $root 'scripts\conversation-memory-mcp.mjs')) | Out-Null
Invoke-Checked -FilePath 'node' -Arguments @('--check', (Join-Path $root 'scripts\sync-conversation-memory.mjs')) | Out-Null
Invoke-Checked -FilePath 'node' -Arguments @('--check', (Join-Path $root 'config\plugins\persistent-memory.js')) | Out-Null
Invoke-Checked -FilePath 'node' -Arguments @((Join-Path $root 'scripts\conversation-memory-mcp.mjs'), '--self-test') | Out-Null
Invoke-Checked -FilePath 'node' -Arguments @((Join-Path $root 'scripts\project-tools-mcp.mjs'), '--self-test') | Out-Null
Invoke-Checked -FilePath 'node' -Arguments @('--check', (Join-Path $root 'scripts\check-mcp.mjs')) | Out-Null
Invoke-Checked -FilePath 'node' -Arguments @('--check', (Join-Path $root 'scripts\run-agent-profile.mjs')) | Out-Null
Invoke-Checked -FilePath 'node' -Arguments @('--check', (Join-Path $root 'scripts\index-workspace.mjs')) | Out-Null

$bad = Select-String -Path (Join-Path $root 'config\*.json'),(Join-Path $root 'config\*.yaml'),(Join-Path $root 'bin\*.cmd') -Pattern 'C:\\Users\\venka|AppData\\Local|\\.ollama\\models' -SimpleMatch -ErrorAction SilentlyContinue
if ($bad) {
  $bad | ForEach-Object { Write-Error "$($_.Path):$($_.LineNumber): $($_.Line)" }
  throw 'Found forbidden user/C-drive storage paths in generated config.'
}

$paid = Select-String -Path (Join-Path $root 'config\*.json'),(Join-Path $root 'config\*.yaml'),(Join-Path $root 'bin\*.cmd') -Pattern 'api.openai.com|githubcopilot|mcp.figma.com|mcp.canva.com|replit-mcp|NVIDIA_API_KEY|CODERABBIT|BRAVE_API_KEY' -ErrorAction SilentlyContinue
if ($paid) {
  $paid | ForEach-Object { Write-Error "$($_.Path):$($_.LineNumber): $($_.Line)" }
  throw 'Found paid/account-backed adapter references in generated runtime config.'
}

Write-Host 'STATIC_VALIDATION_OK'
