[CmdletBinding()]
param(
  [switch]$SkipModels,
  [switch]$SkipVSCode
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

function Require-Command([string]$Name, [string]$InstallHint) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name is required. $InstallHint"
  }
}

Require-Command 'node' 'Install Node.js 22.5 or newer from https://nodejs.org/.'
Require-Command 'npm' 'Install Node.js 22.5 or newer from https://nodejs.org/.'
Require-Command 'python' 'Install Python 3.11 or newer from https://python.org/.'
Require-Command 'ollama' 'Install Ollama for Windows from https://ollama.com/download/windows.'

$nodeVersion = [version]((node --version).TrimStart('v'))
if ($nodeVersion -lt [version]'22.5.0') { throw "Node.js 22.5 or newer is required. Found $nodeVersion." }
$pythonVersion = [version]((python -c 'import platform; print(platform.python_version())').Trim())
if ($pythonVersion -lt [version]'3.11.0') { throw "Python 3.11 or newer is required. Found $pythonVersion." }

$directories = @(
  'cache\huggingface', 'cache\npm', 'cache\pip', 'cache\uv',
  'logs', 'models\ollama', 'projects', 'state\continue', 'state\memory',
  'state\opencode', 'state\playwright', 'state\snapshots', 'state\vscode-user',
  'tools\npm', 'tools\python', 'tools\vscode-extensions'
)
foreach ($relative in $directories) {
  New-Item -ItemType Directory -Force -Path (Join-Path $root $relative) | Out-Null
}

Copy-Item (Join-Path $root 'runtime\npm\package.json') (Join-Path $root 'tools\npm\package.json') -Force
Copy-Item (Join-Path $root 'runtime\npm\package-lock.json') (Join-Path $root 'tools\npm\package-lock.json') -Force
npm ci --prefix (Join-Path $root 'tools\npm') --no-audit --no-fund

$venv = Join-Path $root 'tools\python\aider-venv'
if (-not (Test-Path (Join-Path $venv 'Scripts\python.exe'))) {
  python -m venv $venv
}
& (Join-Path $venv 'Scripts\python.exe') -m pip install --upgrade pip
& (Join-Path $venv 'Scripts\python.exe') -m pip install -r (Join-Path $root 'runtime\requirements.txt')

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\render-continue-config.ps1') | Out-Null

if (-not $SkipVSCode -and (Get-Command 'code' -ErrorAction SilentlyContinue)) {
  $extensions = Join-Path $root 'tools\vscode-extensions'
  code --extensions-dir $extensions --install-extension continue.continue --force | Out-Null
  code --extensions-dir $extensions --install-extension sst-dev.opencode --force | Out-Null
}

if (-not $SkipModels) {
  . (Join-Path $root 'bin\env.ps1')
  $ready = $false
  try {
    Invoke-RestMethod "http://$env:OLLAMA_HOST/api/tags" -TimeoutSec 2 | Out-Null
    $ready = $true
  } catch {}
  if (-not $ready) {
    Start-Process -FilePath 'ollama' -ArgumentList 'serve' -WorkingDirectory $root -WindowStyle Hidden
    $deadline = (Get-Date).AddSeconds(30)
    do {
      Start-Sleep -Milliseconds 500
      try {
        Invoke-RestMethod "http://$env:OLLAMA_HOST/api/tags" -TimeoutSec 2 | Out-Null
        $ready = $true
      } catch {}
    } until ($ready -or (Get-Date) -gt $deadline)
    if (-not $ready) { throw "Ollama did not start at $env:OLLAMA_HOST." }
  }
  & (Join-Path $root 'bin\pull-models.cmd')
  if ($LASTEXITCODE -ne 0) { throw 'One or more default models failed to download.' }
}

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\validate-stack.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Static validation failed.' }

Write-Host ''
Write-Host 'Installation complete.' -ForegroundColor Green
Write-Host "Start the agent with: $root\bin\agent-safe.cmd"
