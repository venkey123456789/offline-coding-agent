$script:AgentHome = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

$env:AGENT_HOME = $script:AgentHome
$env:OLLAMA_MODELS = Join-Path $script:AgentHome 'models\ollama'
$env:HF_HOME = Join-Path $script:AgentHome 'cache\huggingface'
$env:HF_HUB_CACHE = Join-Path $env:HF_HOME 'hub'
$env:TRANSFORMERS_CACHE = Join-Path $env:HF_HOME 'transformers'
$env:XDG_CACHE_HOME = Join-Path $script:AgentHome 'cache'
$env:XDG_DATA_HOME = Join-Path $script:AgentHome 'state\opencode'
$env:XDG_STATE_HOME = Join-Path $script:AgentHome 'state'
$env:PIP_CACHE_DIR = Join-Path $script:AgentHome 'cache\pip'
$env:NPM_CONFIG_CACHE = Join-Path $script:AgentHome 'cache\npm'
$env:UV_CACHE_DIR = Join-Path $script:AgentHome 'cache\uv'
$env:PLAYWRIGHT_BROWSERS_PATH = Join-Path $script:AgentHome 'cache\ms-playwright'
$env:CONTINUE_GLOBAL_DIR = Join-Path $script:AgentHome 'state\continue'
$env:OPENCODE_CONFIG = Join-Path $script:AgentHome 'config\opencode.json'
$env:OPENCODE_CONFIG_DIR = Join-Path $script:AgentHome 'config'
$env:OPENCODE_DISABLE_AUTOUPDATE = 'true'
$env:OPENCODE_DISABLE_PRUNE = 'true'
$env:AGENT_PLUGIN_URL = ([System.Uri](Join-Path $script:AgentHome 'config\plugins\persistent-memory.js')).AbsoluteUri
$env:AGENT_MEMORY_CONTEXT = Join-Path $script:AgentHome 'config\automatic-context.md'
$env:OLLAMA_HOST = '127.0.0.1:11435'
$env:OLLAMA_API_BASE = 'http://127.0.0.1:11435'
$env:OLLAMA_CONTEXT_LENGTH = '32768'
$env:NODE_PATH = Join-Path $script:AgentHome 'tools\npm\node_modules'

$binPaths = @(
  (Join-Path $script:AgentHome 'bin'),
  (Join-Path $script:AgentHome 'tools\npm\node_modules\.bin'),
  (Join-Path $script:AgentHome 'tools\python\aider-venv\Scripts')
)
$env:PATH = ($binPaths + $env:PATH.Split(';') | Where-Object { $_ } | Select-Object -Unique) -join ';'

foreach ($path in @($env:OLLAMA_MODELS, $env:HF_HOME, $env:CONTINUE_GLOBAL_DIR, $env:XDG_DATA_HOME, $env:NPM_CONFIG_CACHE, $env:PIP_CACHE_DIR, $env:UV_CACHE_DIR)) {
  New-Item -ItemType Directory -Force -Path $path | Out-Null
}
