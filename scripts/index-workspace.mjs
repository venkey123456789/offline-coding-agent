#!/usr/bin/env node
import { mkdir, readFile, readdir, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = process.env.AGENT_HOME || path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const mode = process.argv[2] || "index";
const target = path.resolve(mode === "index" ? (process.argv[3] || process.cwd()) : process.cwd());
const indexDir = path.join(root, "state", "index");
const indexFile = path.join(indexDir, `${target.replace(/[:\\/\s]+/g, "_")}.json`);
const excludes = new Set([".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build", ".next", "coverage", "models", "tools", "cache"]);
const textExts = new Set([".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".json", ".yaml", ".yml", ".md", ".txt", ".html", ".css", ".py", ".ps1", ".cmd", ".bat", ".toml", ".rs", ".go", ".cs", ".lua", ".rb", ".java", ".cpp", ".c", ".h"]);

async function walk(dir, files = []) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    if (excludes.has(entry.name)) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) await walk(full, files);
    else if (entry.isFile() && textExts.has(path.extname(entry.name).toLowerCase())) files.push(full);
  }
  return files;
}

function snippet(content, query) {
  const lower = content.toLowerCase();
  const at = lower.indexOf(query.toLowerCase());
  const start = Math.max(0, at - 160);
  return content.slice(start, Math.min(content.length, start + 420)).replace(/\s+/g, " ");
}

if (mode === "index") {
  await mkdir(indexDir, { recursive: true });
  const files = await walk(target);
  const records = [];
  for (const file of files) {
    const info = await stat(file);
    if (info.size > 1_000_000) continue;
    const content = await readFile(file, "utf8").catch(() => "");
    records.push({ path: file, rel: path.relative(target, file), size: info.size, mtimeMs: info.mtimeMs, content });
  }
  await writeFile(indexFile, JSON.stringify({ target, createdAt: new Date().toISOString(), records }, null, 2));
  console.log(`INDEXED ${records.length} files -> ${indexFile}`);
} else if (mode === "search") {
  const query = process.argv.slice(3).join(" ").trim();
  if (!query) throw new Error("Usage: search-project.cmd <query>");
  const indexes = [indexFile];
  const data = JSON.parse(await readFile(indexes[0], "utf8"));
  const hits = data.records
    .filter((record) => record.content.toLowerCase().includes(query.toLowerCase()))
    .slice(0, 20)
    .map((record) => ({ file: record.rel, snippet: snippet(record.content, query) }));
  console.log(JSON.stringify(hits, null, 2));
} else {
  throw new Error("Use mode: index or search");
}
