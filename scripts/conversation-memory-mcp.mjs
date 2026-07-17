#!/usr/bin/env node
import { DatabaseSync } from "node:sqlite";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = process.env.AGENT_HOME || path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const databasePath = path.join(root, "state", "opencode", "opencode", "opencode.db");
const sdkRoot = path.join(root, "tools", "npm", "node_modules", "@modelcontextprotocol", "sdk", "dist", "esm");
const { Server } = await import(pathToFileURL(path.join(sdkRoot, "server", "index.js")).href);
const { StdioServerTransport } = await import(pathToFileURL(path.join(sdkRoot, "server", "stdio.js")).href);
const { CallToolRequestSchema, ListToolsRequestSchema } = await import(pathToFileURL(path.join(sdkRoot, "types.js")).href);

function response(data) {
  return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
}

function openDatabase() {
  return new DatabaseSync(databasePath, { readOnly: true });
}

function parseJson(value) {
  try {
    return JSON.parse(value);
  } catch {
    return {};
  }
}

function clamp(value, fallback, maximum) {
  const number = Number(value);
  return Number.isFinite(number) ? Math.max(1, Math.min(Math.trunc(number), maximum)) : fallback;
}

function recentChats(limit, directory) {
  const db = openDatabase();
  try {
    const rows = directory
      ? db.prepare("SELECT id, title, directory, time_created, time_updated FROM session WHERE directory = ? AND time_archived IS NULL ORDER BY time_updated DESC LIMIT ?").all(directory, limit)
      : db.prepare("SELECT id, title, directory, time_created, time_updated FROM session WHERE time_archived IS NULL ORDER BY time_updated DESC LIMIT ?").all(limit);
    return rows.map((row) => ({ ...row, created: new Date(row.time_created).toISOString(), updated: new Date(row.time_updated).toISOString() }));
  } finally {
    db.close();
  }
}

function searchChats(query, limit) {
  const db = openDatabase();
  try {
    const pattern = `%${query.toLowerCase()}%`;
    const rows = db.prepare(`
      SELECT s.id session_id, s.title, s.directory, s.time_updated, m.data message_data, p.data part_data
      FROM part p
      JOIN message m ON m.id = p.message_id
      JOIN session s ON s.id = p.session_id
      WHERE lower(p.data) LIKE ?
      ORDER BY p.time_created DESC
      LIMIT ?
    `).all(pattern, limit * 4);
    const matches = [];
    for (const row of rows) {
      const part = parseJson(row.part_data);
      const message = parseJson(row.message_data);
      if (part.type !== "text" || typeof part.text !== "string") continue;
      matches.push({
        session_id: row.session_id,
        title: row.title,
        directory: row.directory,
        updated: new Date(row.time_updated).toISOString(),
        role: message.role || "unknown",
        text: part.text.slice(0, 1200)
      });
      if (matches.length >= limit) break;
    }
    return matches;
  } finally {
    db.close();
  }
}

function readChat(sessionId, maxMessages) {
  const db = openDatabase();
  try {
    const session = db.prepare("SELECT id, title, directory, time_created, time_updated FROM session WHERE id = ?").get(sessionId);
    if (!session) return null;
    const rows = db.prepare(`
      SELECT m.id, m.data message_data, m.time_created, p.data part_data
      FROM message m
      JOIN part p ON p.message_id = m.id
      WHERE m.session_id = ?
      ORDER BY m.time_created DESC, p.time_created DESC
      LIMIT ?
    `).all(sessionId, maxMessages * 8).reverse();
    const messages = [];
    for (const row of rows) {
      const part = parseJson(row.part_data);
      if (part.type !== "text" || typeof part.text !== "string") continue;
      const message = parseJson(row.message_data);
      messages.push({ role: message.role || "unknown", text: part.text, created: new Date(row.time_created).toISOString() });
    }
    return { ...session, messages: messages.slice(-maxMessages) };
  } finally {
    db.close();
  }
}

const server = new Server({ name: "offline-agent-chat-memory", version: "1.0.0" }, { capabilities: { tools: {} } });

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: [
  {
    name: "list_recent_chats",
    description: "List locally saved OpenCode conversations from previous sessions and restarts.",
    inputSchema: { type: "object", properties: { limit: { type: "integer", minimum: 1, maximum: 100 }, directory: { type: "string" } }, additionalProperties: false }
  },
  {
    name: "search_chat_history",
    description: "Search the full text of earlier local user and assistant conversations before claiming prior context is unavailable.",
    inputSchema: { type: "object", properties: { query: { type: "string", minLength: 1 }, limit: { type: "integer", minimum: 1, maximum: 50 } }, required: ["query"], additionalProperties: false }
  },
  {
    name: "read_chat",
    description: "Read user and assistant text from one saved conversation by session ID.",
    inputSchema: { type: "object", properties: { session_id: { type: "string", minLength: 1 }, max_messages: { type: "integer", minimum: 1, maximum: 200 } }, required: ["session_id"], additionalProperties: false }
  }
] }));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const args = request.params.arguments || {};
  try {
    if (request.params.name === "list_recent_chats") return response({ chats: recentChats(clamp(args.limit, 20, 100), args.directory) });
    if (request.params.name === "search_chat_history") return response({ matches: searchChats(String(args.query), clamp(args.limit, 10, 50)) });
    if (request.params.name === "read_chat") return response({ chat: readChat(String(args.session_id), clamp(args.max_messages, 50, 200)) });
    throw new Error(`Unknown tool: ${request.params.name}`);
  } catch (error) {
    return { isError: true, content: [{ type: "text", text: `Chat memory unavailable: ${error.message}` }] };
  }
});

if (process.argv.includes("--self-test")) {
  const chats = recentChats(5);
  console.log(JSON.stringify({ ok: true, databasePath, chats: chats.length }));
  process.exit(0);
}

await server.connect(new StdioServerTransport());
