# Offline Coding Agent Workspace

This workspace is for the local/offline-first coding-agent stack. Treat the directory containing this file as the installation root.

## Defaults
- Keep models, caches, logs, and runtime state inside this workspace unless the user explicitly asks otherwise.
- Prefer local Ollama models for normal coding work.
- Treat online work as public-browser access only; no account-backed or paid MCP adapters.
- Do not assume Docker or cloud GPU tooling exists on this machine.
- Do not add paid APIs, subscription-backed MCP adapters, cloud GPU billing, or paid review/design/build services.
- Expand terse requests into concrete technical tasks before editing.
- Review generated code twice for syntax, structure, regressions, and robustness.
- Conserve output tokens and avoid redundant status chatter.
- Use web research only through opt-in online tools when the task needs current external information.

## Persistent Memory
- Chat sessions are stored locally under `state\opencode` and survive restarts.
- Before claiming that prior context is unavailable, use the `chat-memory` MCP tools to search earlier conversations.
- When the user refers to previous work without enough detail, search chat history first, then read the relevant chat.
- Use the `memory` MCP knowledge graph for durable user preferences, project decisions, names, and recurring facts. Search it at the start of related work and update it when stable information is explicitly established.
- Do not save passwords, tokens, API keys, private keys, or other secrets in long-term memory.

## Local Entry Points
- `bin\agent.cmd` starts OpenCode with local Ollama and offline MCP tools.
- `bin\agent-online.cmd` starts OpenCode with only no-cost public-browser web tools.
- `bin\agent-fast.cmd`, `bin\agent-deep.cmd`, and `bin\agent-review.cmd` use model routing profiles.
- `bin\agent-safe.cmd` snapshots the project before starting the agent.
- `bin\agent-web.cmd` starts the OpenCode web UI on localhost.
- `bin\vscode-agent.cmd` starts VS Code with local extension/profile storage.
- `bin\aider-local.cmd` starts Aider against local Ollama.
- `bin\ollama-local.cmd` starts or checks Ollama with H-local model storage.
