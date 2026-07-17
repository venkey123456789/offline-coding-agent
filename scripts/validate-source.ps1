$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

$required = @(
  '.gitignore', 'LICENSE', 'README.md', 'CONTRIBUTING.md', 'SECURITY.md',
  'install.ps1', 'bin\agent.cmd', 'bin\agent-safe.cmd',
  'config\opencode.json', 'config\opencode-online.json',
  'config\plugins\persistent-memory.js',
  'scripts\conversation-memory-mcp.mjs', 'scripts\sync-conversation-memory.mjs',
  'runtime\npm\package.json', 'runtime\npm\package-lock.json', 'runtime\requirements.txt'
)
foreach ($relative in $required) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) {
    throw "Missing source file: $relative"
  }
}

foreach ($file in Get-ChildItem (Join-Path $root 'config') -Filter '*.json' -File | Where-Object { $_.Name -ne 'package-lock.json' }) {
  Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json | Out-Null
}

$nodeFiles = Get-ChildItem (Join-Path $root 'scripts'),(Join-Path $root 'config\plugins') -Include '*.js','*.mjs' -File -Recurse
foreach ($file in $nodeFiles) {
  & node --check $file.FullName
  if ($LASTEXITCODE -ne 0) { throw "JavaScript syntax validation failed: $($file.FullName)" }
}

$publicAreas = @('bin', 'config', 'docs', 'runtime', 'scripts', 'templates') | ForEach-Object { Join-Path $root $_ }
$validatorPath = Join-Path $root 'scripts\validate-source.ps1'
$stackValidatorPath = Join-Path $root 'scripts\validate-stack.ps1'
$excludedValidationFiles = @($validatorPath, $stackValidatorPath)
$publicFiles = $publicAreas | ForEach-Object { Get-ChildItem -LiteralPath $_ -File -Recurse } | Where-Object { $_.FullName -notin $excludedValidationFiles }
$drivePathPattern = '[A-Z]:' + '\\coding offline ai agent'
$userPathPattern = 'C:' + '\\Users\\'
$hardcoded = $publicFiles | Select-String -Pattern ($drivePathPattern + '|' + $userPathPattern) -ErrorAction SilentlyContinue
if ($hardcoded) { throw 'Public source contains a hardcoded personal installation path.' }

$forbiddenRoots = @('models/', 'cache/', 'state/', 'logs/', 'tools/', 'projects/', 'chat histories/')
if (Test-Path (Join-Path $root '.git\HEAD')) {
  $tracked = git -C $root ls-files
  foreach ($entry in $tracked) {
    $normalized = $entry.Replace('\', '/')
    if ($forbiddenRoots | Where-Object { $normalized.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }) {
      throw "Private runtime data is tracked: $entry"
    }
  }
}

$secretPattern = '(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)'
$secretHits = Get-ChildItem $root -File -Recurse | Where-Object {
  $_.FullName -notmatch '\\(models|cache|state|logs|tools|projects|chat histories|\.git)\\'
} | Select-String -Pattern $secretPattern -ErrorAction SilentlyContinue
if ($secretHits) { throw 'A possible credential or private key was found in public source.' }

Write-Host 'SOURCE_VALIDATION_OK'
