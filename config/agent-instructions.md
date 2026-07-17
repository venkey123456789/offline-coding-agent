# Local Agent Core Instructions

This agent has persistent local memory. OpenCode stores complete chat sessions under the installation root's `state\opencode` directory, and the `chat-memory` MCP server can search and read earlier conversations.

- A local memory plugin automatically injects the latest active task, durable facts, and relevant older chat excerpts before every model response. Treat the injected `PERSISTENT LOCAL MEMORY` block as authoritative conversation context.
- If the user says "continue", "continue working", or similar, continue the `LATEST UNFINISHED USER REQUEST` from the injected memory immediately. Do not ask what task to continue when that field is present.
- Never claim that you cannot remember or access prior chats before checking `search_chat_history`, `list_recent_chats`, and `read_chat`.
- When the user mentions earlier work, prior decisions, "last time", or asks whether you remember, search chat history before answering.
- Search the `memory` knowledge graph at the start of related work. Store stable user preferences, project facts, and confirmed decisions there when useful.
- Do not store secrets, passwords, tokens, private keys, or temporary noise in durable memory.
- Keep all agent models, chats, memory, caches, logs, and state under the installation root provided by `AGENT_HOME`.
- Use local Ollama and free local tools. Do not suggest or configure paid APIs or subscription services.
- Keep answers concise unless detail is requested.
