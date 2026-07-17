# Offline Coding Agent

A free, open-source, offline-first AI coding workspace for Windows. It combines local Ollama models with OpenCode, persistent conversation memory, MCP tools, VS Code integration, and Aider without requiring a paid AI API.

The goal is simple: install it once, keep your code and conversations on your own drive, and use one dependable launcher for everyday development.

## What it can do

- Build, edit, debug, test, and review software projects.
- Work with websites, desktop apps, command-line tools, games, scripts, and existing repositories.
- Use local filesystem, Git, memory, sequential-thinking, and project-management MCP tools.
- Preserve complete OpenCode chat sessions across restarts.
- Automatically recall the current task, durable preferences, and relevant excerpts from older conversations.
- Run through a terminal, a local browser interface, VS Code, or Aider.
- Use optional browser automation for public web research without adding a paid search API.

## Privacy model

Your models, chats, memories, projects, caches, editor profile, and logs stay inside the installation folder. They are deliberately excluded from Git and are never part of the public repository.

The first installation and model downloads require internet access. Normal coding and conversation work can run offline afterward.

## Requirements

- Windows 10 or Windows 11
- [Ollama](https://ollama.com/download/windows)
- Node.js 22.5 or newer
- Python 3.11 or newer
- Git
- VS Code is optional
- A GPU is recommended, but Ollama can fall back to CPU execution

## Install

Open PowerShell in the folder where you want the project, then run:

```powershell
git clone https://github.com/venkey123456789/offline-coding-agent.git
cd offline-coding-agent
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

The installer creates all runtime folders inside the repository, installs the free local tools, starts the workspace-specific Ollama service, downloads the balanced model set, and validates the installation.

To install the tools without downloading models yet:

```powershell
.\install.ps1 -SkipModels
```

## Start

For normal use, launch:

```cmd
bin\agent-safe.cmd
```

This creates a local project snapshot and resumes the latest conversation. The other useful launchers are:

| Launcher | Purpose |
| --- | --- |
| `bin\agent.cmd` | Main offline OpenCode agent |
| `bin\agent-new.cmd` | Start a clean conversation |
| `bin\agent-history.cmd` | List saved conversations |
| `bin\agent-fast.cmd` | Faster, smaller local model profile |
| `bin\agent-deep.cmd` | Strongest installed local model profile |
| `bin\agent-review.cmd` | Review-oriented model profile |
| `bin\agent-web.cmd` | Local browser interface on port 4096 |
| `bin\agent-online.cmd` | Public-browser automation, enabled explicitly |
| `bin\vscode-agent.cmd` | Portable VS Code profile and extensions |
| `bin\aider-local.cmd` | Aider connected to local Ollama |
| `bin\health.cmd` | Installation and runtime diagnostics |

## Persistent memory

Memory is not dependent on the model remembering to call a tool. A local OpenCode plugin injects useful memory before every response.

The system keeps three complementary forms of memory:

1. OpenCode stores complete sessions and messages in its local database.
2. `state\memory\all-conversations.jsonl` keeps an append-only text mirror of user and assistant messages.
3. `state\memory\memory.jsonl` stores durable facts such as preferences and project decisions.

The memory plugin retrieves relevant older excerpts, identifies the latest unfinished request, and preserves important context during conversation compaction. Secrets should never be intentionally placed in durable memory.

## Local models

The default installation uses:

- `qwen3:14b` for balanced coding and reasoning.
- `qwen2.5-coder:1.5b` for fast coding and autocomplete.
- `nomic-embed-text` for local embeddings.

Optional launchers can pull `qwen3-coder:latest` or `gpt-oss:20b` when the machine has enough memory. Model availability and hardware requirements can change, so check Ollama before downloading a larger model.

## Architecture

```text
launchers -> OpenCode -> Ollama local model
                     -> offline MCP servers
                     -> persistent-memory plugin
                     -> local session database

VS Code -> Continue -> Ollama and local MCP servers
Aider -------------> Ollama
```

Everything generated at runtime remains under `models`, `cache`, `state`, `logs`, `tools`, or `projects`. Those directories are ignored by Git.

## Safety

- File edits and shell commands require approval by default.
- `agent-safe.cmd` creates a recoverable snapshot before work begins.
- Paid APIs and account-backed cloud adapters are not included.
- Online browser automation is separate from the offline launcher.
- The repository contains source and configuration only, never local chat history or downloaded models.

## Validate

```powershell
.\bin\health.cmd
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-stack.ps1
node .\scripts\check-mcp.mjs
```

## Scope

This is a practical local coding environment, not a promise that one model can perfectly complete every possible task. Results depend on the selected model, available hardware, project quality, and the instructions provided. The stack is designed to be inspectable, extensible, and fully usable without paid inference services.

## Contributing

Bug reports, documentation improvements, new local integrations, and focused pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes.

## License

Released under the [MIT License](LICENSE).
