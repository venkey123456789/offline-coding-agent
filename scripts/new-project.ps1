param(
  [Parameter(Mandatory = $true)][string]$Template,
  [Parameter(Mandatory = $true)][string]$Name,
  [string]$DestinationRoot
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
  $DestinationRoot = Join-Path $root 'projects'
}
$templatePath = Join-Path $root "templates\$Template"
if (-not (Test-Path -LiteralPath $templatePath)) {
  throw "Unknown template '$Template'. Available: $((Get-ChildItem (Join-Path $root 'templates') -Directory | Select-Object -ExpandProperty Name) -join ', ')"
}

$dest = Join-Path $DestinationRoot $Name
if (Test-Path -LiteralPath $dest) { throw "Destination exists: $dest" }
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Path (Join-Path $templatePath '*') -Destination $dest -Recurse -Force
Write-Host $dest
