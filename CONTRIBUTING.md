# Contributing

Thank you for helping improve Offline Coding Agent.

## Before opening a change

- Keep the offline-first and free-to-use core intact.
- Do not add paid APIs, required cloud accounts, telemetry, or background uploads.
- Keep models, chat histories, credentials, caches, and generated state out of Git.
- Prefer small changes with a clear reason and a focused validation path.

## Development workflow

1. Fork the repository and create a descriptive branch.
2. Make the smallest complete change that solves the problem.
3. Run `scripts\validate-stack.ps1` and any tests related to your change.
4. Explain what changed, why it changed, and how you verified it in the pull request.

When changing launchers or configuration, test from a path containing spaces. When changing memory behavior, verify both a new conversation and a resumed conversation. Never use real credentials or private conversations as fixtures.

## Reporting bugs

Include the Windows version, Node.js version, Python version, Ollama version, launcher used, model name, and the smallest relevant error output. Remove usernames, tokens, project secrets, and private chat text before posting logs.
