# Technical Reference

## Runtime layout

- `bin`: user-facing launchers and environment isolation.
- `config`: OpenCode, Continue, model-routing, policy, and plugin configuration.
- `scripts`: validation, memory, project, snapshot, and MCP utilities.
- `runtime`: reproducible npm and Python dependency manifests.
- `templates`: small offline project starters.
- `models`, `cache`, `state`, `logs`, `tools`, and `projects`: generated local data excluded from Git.

## Runtime isolation

`bin\env.cmd` and `bin\env.ps1` derive `AGENT_HOME` from their own location. They redirect Ollama models, Hugging Face data, npm and Python caches, OpenCode sessions, Continue state, Playwright data, and VS Code profiles into the installation root.

OpenCode configuration uses `{env:AGENT_HOME}` substitution, so the repository can be installed on any writable Windows drive or path, including paths containing spaces.

## Memory flow

OpenCode writes complete messages to its local SQLite database. `scripts\sync-conversation-memory.mjs` mirrors text parts into append-only JSONL. The local persistent-memory plugin injects durable facts, recent context, and query-relevant older excerpts into every model request. The chat-memory MCP server also provides explicit search and retrieval tools.

## Validation

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-stack.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-local.ps1
node .\scripts\check-mcp.mjs
```
