#!/usr/bin/env node
import { DatabaseSync } from "node:sqlite";
import { appendFile, mkdir, open, readFile, rename, unlink, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = process.env.AGENT_HOME || path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const memoryDir = path.join(root, "state", "memory");
const databasePath = path.join(root, "state", "opencode", "opencode", "opencode.db");
const transcriptPath = path.join(memoryDir, "all-conversations.jsonl");
const indexPath = path.join(memoryDir, "synced-parts.txt");
const lockPath = path.join(memoryDir, "conversation-sync.lock");

await mkdir(memoryDir, { recursive: true });

let lock;
try {
  lock = await open(lockPath, "wx");
} catch (error) {
  if (error.code === "EEXIST") process.exit(0);
  throw error;
}

try {
  let known = new Set();
  try {
    known = new Set((await readFile(indexPath, "utf8")).split(/\r?\n/).filter(Boolean));
  } catch {}

  const db = new DatabaseSync(databasePath, { readOnly: true });
  let rows;
  try {
    rows = db.prepare(`
      SELECT p.id part_id, p.time_created, p.data part_data, m.data message_data,
             s.id session_id, s.title, s.directory
      FROM part p
      JOIN message m ON m.id = p.message_id
      JOIN session s ON s.id = p.session_id
      ORDER BY p.time_created, p.id
    `).all();
  } finally {
    db.close();
  }

  const additions = [];
  for (const row of rows) {
    if (known.has(row.part_id)) continue;
    let part;
    let message;
    try {
      part = JSON.parse(row.part_data);
      message = JSON.parse(row.message_data);
    } catch {
      continue;
    }
    if (part.type !== "text" || typeof part.text !== "string") continue;
    additions.push(JSON.stringify({
      part_id: row.part_id,
      session_id: row.session_id,
      title: row.title,
      directory: row.directory,
      role: message.role || "unknown",
      time: new Date(row.time_created).toISOString(),
      text: part.text
    }));
    known.add(row.part_id);
  }

  if (additions.length) await appendFile(transcriptPath, `${additions.join("\n")}\n`, "utf8");
  const temporaryIndex = `${indexPath}.tmp`;
  await writeFile(temporaryIndex, `${[...known].sort().join("\n")}\n`, "utf8");
  await rename(temporaryIndex, indexPath);

  console.log(JSON.stringify({ ok: true, added: additions.length, total: known.size, transcriptPath }));
} finally {
  await lock.close();
  await unlink(lockPath).catch(() => {});
}
