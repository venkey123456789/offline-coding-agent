import { Database } from "bun:sqlite";
import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = process.env.AGENT_HOME || path.dirname(path.dirname(path.dirname(fileURLToPath(import.meta.url))));
const databasePath = `${root}\\state\\opencode\\opencode\\opencode.db`;
const durablePath = `${root}\\state\\memory\\memory.jsonl`;
const marker = "<PERSISTENT_LOCAL_MEMORY>";
const stopWords = new Set(["about", "again", "also", "anything", "continue", "could", "everything", "from", "have", "just", "like", "more", "please", "should", "that", "their", "there", "these", "they", "this", "what", "when", "where", "which", "with", "working", "would", "your"]);

function textParts(message) {
  return Array.isArray(message?.parts) ? message.parts.filter((part) => part?.type === "text" && typeof part.text === "string") : [];
}

function words(text) {
  return [...new Set(String(text).toLowerCase().match(/[a-z0-9_:-]{3,}/g) || [])]
    .filter((word) => !stopWords.has(word))
    .slice(0, 20);
}

function durableFacts() {
  if (!existsSync(durablePath)) return [];
  const facts = [];
  for (const line of readFileSync(durablePath, "utf8").split(/\r?\n/)) {
    if (!line.trim()) continue;
    try {
      const item = JSON.parse(line);
      for (const observation of item.observations || []) facts.push(`${item.name}: ${observation}`);
    } catch {}
  }
  return facts.slice(-40);
}

function relevantHistory(query) {
  if (!existsSync(databasePath)) return [];
  const terms = words(query);
  const db = new Database(databasePath, { readonly: true });
  try {
    const rows = db.query(`
      SELECT s.id session_id, s.title, s.directory, p.time_created, p.data part_data, m.data message_data
      FROM part p
      JOIN message m ON m.id = p.message_id
      JOIN session s ON s.id = p.session_id
      ORDER BY p.time_created DESC
      LIMIT 800
    `).all();
    const scored = [];
    for (const row of rows) {
      let part;
      let message;
      try {
        part = JSON.parse(row.part_data);
        message = JSON.parse(row.message_data);
      } catch {
        continue;
      }
      if (part.type !== "text" || typeof part.text !== "string" || part.text.includes(marker)) continue;
      const lower = part.text.toLowerCase();
      if (lower.trim() === String(query).trim().toLowerCase()) continue;
      const score = terms.length === 0 ? 1 : terms.reduce((total, term) => total + (lower.includes(term) ? 3 : 0), 0);
      if (score > 0) scored.push({ score, time: row.time_created, role: message.role || "unknown", title: row.title, text: part.text });
    }
    return scored.sort((a, b) => b.score - a.score || b.time - a.time).slice(0, 8);
  } finally {
    db.close();
  }
}

function buildMemory(messages, currentText) {
  const earlier = [];
  for (const message of messages) {
    const role = message?.info?.role || message?.role || "unknown";
    for (const part of textParts(message)) {
      if (part.text === currentText || part.text.includes(marker)) continue;
      earlier.push({ role, text: part.text });
    }
  }
  const earlierUsers = earlier.filter((item) => item.role === "user");
  const latestTask = earlierUsers.at(-1)?.text || "No earlier request exists in this session.";
  const recent = earlier.slice(-10);
  const relevant = relevantHistory(currentText);
  const sections = [
    marker,
    "This is trusted local conversation memory supplied automatically. Use it as context; do not say memory is unavailable.",
    "LATEST UNFINISHED USER REQUEST:",
    latestTask,
    "DURABLE FACTS:",
    ...durableFacts().map((fact) => `- ${fact}`),
    "RECENT CURRENT-SESSION CONVERSATION:",
    ...recent.map((item) => `${item.role.toUpperCase()}: ${item.text.slice(0, 900)}`),
    "RELEVANT OLDER CHAT EXCERPTS:",
    ...relevant.map((item) => `[${item.title}] ${item.role.toUpperCase()}: ${item.text.slice(0, 900)}`),
    "INSTRUCTION: If the current request says continue, immediately execute the latest unfinished request above. Do not ask which task."
  ];
  return `${sections.join("\n").slice(0, 10000)}\n</PERSISTENT_LOCAL_MEMORY>`;
}

export const PersistentMemoryPlugin = async () => ({
  "experimental.chat.messages.transform": async (_input, output) => {
    if (!Array.isArray(output?.messages)) return;
    let target;
    for (let index = output.messages.length - 1; index >= 0 && !target; index--) {
      const message = output.messages[index];
      const role = message?.info?.role || message?.role;
      if (role === "user") target = textParts(message).at(-1);
    }
    if (!target || target.text.includes(marker)) return;
    const original = target.text;
    target.text = `${buildMemory(output.messages, original)}\n\n<CURRENT_USER_REQUEST>\n${original}\n</CURRENT_USER_REQUEST>`;
  },
  "experimental.session.compacting": async (_input, output) => {
    output.context.push("Preserve the exact latest unfinished user request, current task status, durable user facts, decisions, edited files, errors, and next actions. Never discard persistent-memory context.");
  },
  event: async ({ event }) => {
    if (event?.type !== "session.idle") return;
    const child = Bun.spawn(["node", `${root}\\scripts\\sync-conversation-memory.mjs`], {
      cwd: root,
      env: process.env,
      stdout: "ignore",
      stderr: "ignore"
    });
    child.unref();
  }
});

export default PersistentMemoryPlugin;
