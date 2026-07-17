param(
  [string]$ProjectPath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $root 'bin\env.ps1')

$resolved = (Resolve-Path -LiteralPath $ProjectPath).Path
$name = Split-Path -Leaf $resolved
if ([string]::IsNullOrWhiteSpace($name)) { $name = 'project' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$snapshotRoot = Join-Path $root 'state\snapshots'
$stage = Join-Path $env:TEMP "offline-agent-snapshot-$stamp"
$zip = Join-Path $snapshotRoot "$stamp-$($name -replace '[^A-Za-z0-9_.-]', '_').zip"

$excludedDirs = @('.git', 'node_modules', '.venv', 'venv', '__pycache__', 'dist', 'build', '.next', 'coverage', 'cache', 'models', 'tools')
New-Item -ItemType Directory -Force -Path $snapshotRoot, $stage | Out-Null

try {
  Get-ChildItem -LiteralPath $resolved -Recurse -Force -File | Where-Object {
    $relative = $_.FullName.Substring($resolved.Length).TrimStart('\')
    $parts = $relative -split '\\'
    -not ($parts | Where-Object { $excludedDirs -contains $_ })
  } | ForEach-Object {
    $relative = $_.FullName.Substring($resolved.Length).TrimStart('\')
    $target = Join-Path $stage $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
  }

  Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
  Write-Host $zip
} finally {
  if (Test-Path -LiteralPath $stage) {
    Remove-Item -LiteralPath $stage -Recurse -Force
  }
}
