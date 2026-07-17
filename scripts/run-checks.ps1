param(
  [string]$ProjectPath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $root 'bin\env.ps1')

$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$failed = $false

function Run-Step([string]$Name, [scriptblock]$Step) {
  Write-Host "== $Name =="
  & $Step
  if ($LASTEXITCODE -ne 0) {
    $script:failed = $true
    Write-Host "FAILED: $Name"
  }
}

Push-Location $project
try {
  if (Test-Path 'package.json') {
    $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
    if ($pkg.scripts.lint) { Run-Step 'npm lint' { npm run lint } }
    if ($pkg.scripts.test) { Run-Step 'npm test' { npm test } }
    if ($pkg.scripts.build) { Run-Step 'npm build' { npm run build } }
  }

  if ((Test-Path 'pyproject.toml') -or (Test-Path 'pytest.ini') -or (Test-Path 'tests')) {
    Run-Step 'ruff check' { & (Join-Path $root 'tools\python\aider-venv\Scripts\ruff.exe') check . }
    Run-Step 'pytest' { & (Join-Path $root 'tools\python\aider-venv\Scripts\python.exe') -m pytest }
  }

  if (-not (Test-Path 'package.json') -and -not (Test-Path 'pyproject.toml') -and -not (Test-Path 'tests')) {
    Write-Host 'No standard check targets found.'
  }
} finally {
  Pop-Location
}

if ($failed) { exit 1 }
Write-Host 'CHECKS_DONE'
