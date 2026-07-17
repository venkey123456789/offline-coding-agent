param(
  [string]$Model = 'qwen3:14b'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. (Join-Path $root 'bin\env.ps1')
$out = Join-Path $root "state\evals\$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($Model -replace '[:\\/]', '_').txt"

$prompts = @(
  'Return only VALID_JSON_OK as a JSON string.',
  'Write a JavaScript function add(a,b) returning a+b. No explanation.',
  'Name one risk when editing a codebase without tests. One sentence.'
)

foreach ($prompt in $prompts) {
  "PROMPT: $prompt" | Add-Content -LiteralPath $out
  ollama run $Model $prompt | Add-Content -LiteralPath $out
  "" | Add-Content -LiteralPath $out
}
Write-Host $out
