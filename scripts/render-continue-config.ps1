$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$source = Join-Path $root 'config\continue-config.yaml'
$destination = Join-Path $root 'state\continue\config.yaml'
$content = (Get-Content -LiteralPath $source -Raw).Replace('${{ secrets.AGENT_HOME }}', $root)
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
Set-Content -LiteralPath $destination -Value $content -NoNewline -Encoding utf8
Write-Host $destination
