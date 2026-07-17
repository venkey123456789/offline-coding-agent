$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$configDir = Join-Path $root 'config'
$runtimeConfigDir = Join-Path $root 'state\opencode-config'
New-Item -ItemType Directory -Force -Path $runtimeConfigDir | Out-Null

function ConvertTo-JsonStringContent([string]$Value) {
  return $Value.Replace('\', '\\').Replace('"', '\"')
}

$replacements = @{
  '{env:AGENT_HOME}' = ConvertTo-JsonStringContent $root
  '{env:AGENT_PLUGIN_URL}' = ([System.Uri](Join-Path $root 'config\plugins\persistent-memory.js')).AbsoluteUri
  '{env:AGENT_MEMORY_CONTEXT}' = ConvertTo-JsonStringContent (Join-Path $root 'config\automatic-context.md')
}

foreach ($name in @('opencode', 'opencode-online')) {
  $source = Join-Path $configDir "$name.json"
  $destinationName = if ($name -eq 'opencode') { 'opencode.json' } else { 'opencode-online.json' }
  $destination = Join-Path $runtimeConfigDir $destinationName
  $content = Get-Content -LiteralPath $source -Raw
  foreach ($entry in $replacements.GetEnumerator()) {
    $content = $content.Replace($entry.Key, $entry.Value)
  }
  $content | ConvertFrom-Json | Out-Null
  [System.IO.File]::WriteAllText($destination, $content, [System.Text.UTF8Encoding]::new($false))
}
