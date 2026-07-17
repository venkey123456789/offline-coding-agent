# Security Policy

## Supported version

Security fixes are applied to the latest version on the default branch.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting feature instead of opening a public issue. Include reproduction steps, affected files, impact, and any suggested mitigation.

Do not include API keys, access tokens, private source code, personal chat history, or other secrets in a report. If a secret was exposed, revoke it before doing anything else.

## Local data

This project stores conversations, memories, models, caches, logs, and editor state locally. Those runtime directories are excluded by `.gitignore`, but contributors are still responsible for reviewing staged files before every commit.
