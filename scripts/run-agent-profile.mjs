#!/usr/bin/env node
import { spawn } from "node:child_process";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = process.env.AGENT_HOME || path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const configPath = path.join(root, "config", "model-routing.json");
const requested = process.argv[2] && !process.argv[2].startsWith("-") ? process.argv[2] : "balanced";
const passthrough = requested === process.argv[2] ? process.argv.slice(3) : process.argv.slice(2);
const ollamaHost = process.env.OLLAMA_HOST || "127.0.0.1:11435";
const ollamaUrl = `http://${ollamaHost}/api/tags`;

async function ollamaModels() {
  const response = await fetch(ollamaUrl);
  if (!response.ok) throw new Error(`Ollama API returned ${response.status}`);
  const data = await response.json();
  return new Set((data.models || []).map((model) => model.name));
}

async function sleep(ms) {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitForOllama(timeoutMs = 20000) {
  const deadline = Date.now() + timeoutMs;
  let lastError;
  while (Date.now() < deadline) {
    try {
      return await ollamaModels();
    } catch (error) {
      lastError = error;
      await sleep(1000);
    }
  }
  throw lastError || new Error("Ollama did not become ready");
}

async function startOllama() {
  const child = spawn("ollama", ["serve"], {
    cwd: root,
    detached: true,
    env: process.env,
    stdio: "ignore",
    windowsHide: true
  });
  child.unref();
}

const routing = JSON.parse(await readFile(configPath, "utf8"));
const profile = routing.profiles[requested] || routing.profiles[routing.defaultProfile];
if (!profile) throw new Error(`No model profile found for ${requested}`);

let installed;
try {
  installed = await ollamaModels();
} catch {
  console.error(`Ollama is not running on ${ollamaHost}. Starting it now...`);
  try {
    await startOllama();
    installed = await waitForOllama();
  } catch (error) {
    console.error(`Ollama could not start or respond at ${ollamaHost}.`);
    console.error(`Start it manually with: "${path.join(root, "bin", "ollama-local.cmd")}" serve`);
    console.error(`Then run this agent again.`);
    if (process.env.AGENT_DEBUG) console.error(error);
    process.exit(1);
  }
}
const selected = profile.models.find((model) => installed.has(model));
if (!selected) {
  console.error(`No model installed for profile "${requested}".`);
  console.error(`Install the local models with: "${path.join(root, "bin", "pull-models.cmd")}"`);
  console.error(`Expected one of: ${profile.models.join(", ")}`);
  process.exit(2);
}

console.error(`profile=${requested} model=${selected}`);
const opencode = path.join(root, "tools", "npm", "node_modules", ".bin", "opencode.cmd");
const args = [opencode, "-m", `ollama/${selected}`, ...passthrough];
const quote = (arg) => `"${String(arg).replace(/"/g, '""')}"`;
const commandLine = `call ${args.map(quote).join(" ")}`;
const syncScript = path.join(root, "scripts", "sync-conversation-memory.mjs");
await new Promise((resolve) => {
  const sync = spawn(process.execPath, [syncScript], { cwd: root, env: process.env, stdio: "ignore" });
  sync.on("exit", resolve);
  sync.on("error", resolve);
});

const child = spawn("cmd.exe", ["/d", "/c", commandLine], {
  cwd: process.cwd(),
  env: process.env,
  windowsVerbatimArguments: true,
  stdio: "inherit"
});
child.on("exit", (code) => {
  const sync = spawn(process.execPath, [syncScript], { cwd: root, env: process.env, stdio: "ignore" });
  sync.on("exit", () => process.exit(code ?? 0));
  sync.on("error", () => process.exit(code ?? 0));
});
