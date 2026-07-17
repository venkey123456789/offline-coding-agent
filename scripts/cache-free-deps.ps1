$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $root 'bin\env.ps1')

npm cache verify
npm install --prefix (Join-Path $root 'tools\npm') --prefer-offline --no-audit typescript eslint prettier
& (Join-Path $root 'tools\python\aider-venv\Scripts\python.exe') -m pip download -d (Join-Path $root 'cache\pip\wheels') pytest ruff
Write-Host 'FREE_DEP_CACHE_DONE'
