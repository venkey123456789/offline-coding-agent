#!/usr/bin/env node
import { readFile, readdir, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = process.env.AGENT_HOME || path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const sdkRoot = path.join(root, "tools", "npm", "node_modules", "@modelcontextprotocol", "sdk", "dist", "esm");
const { Server } = await import(pathToFileURL(path.join(sdkRoot, "server", "index.js")).href);
const { StdioServerTransport } = await import(pathToFileURL(path.join(sdkRoot, "server", "stdio.js")).href);
const { CallToolRequestSchema, ListToolsRequestSchema } = await import(pathToFileURL(path.join(sdkRoot, "types.js")).href);

function text(data) {
  return { content: [{ type: "text", text: typeof data === "string" ? data : JSON.stringify(data, null, 2) }] };
}

async function listProjects() {
  const projectsDir = path.join(root, "projects");
  try {
    const entries = await readdir(projectsDir, { withFileTypes: true });
    return entries.filter((entry) => entry.isDirectory()).map((entry) => entry.name).sort();
  } catch {
    return [];
  }
}

async function dirExists(relativePath) {
  try {
    return (await stat(path.join(root, relativePath))).isDirectory();
  } catch {
    return false;
  }
}

async function modelNames() {
  try {
    const response = await fetch(`http://${process.env.OLLAMA_HOST || "127.0.0.1:11435"}/api/tags`);
    const data = await response.json();
    return (data.models || []).map((model) => model.name).sort();
  } catch {
    return [];
  }
}

async function searchWorkspace(query) {
  const indexRoot = path.join(root, "state", "index");
  const hits = [];
  try {
    const files = await readdir(indexRoot);
    for (const file of files.filter((name) => name.endsWith(".json"))) {
      const data = JSON.parse(await readFile(path.join(indexRoot, file), "utf8"));
      for (const record of data.records || []) {
        const content = String(record.content || "");
        const at = content.toLowerCase().indexOf(query.toLowerCase());
        if (at >= 0) {
          hits.push({
            file: record.path,
            snippet: content.slice(Math.max(0, at - 120), at + 280).replace(/\s+/g, " ")
          });
        }
        if (hits.length >= 20) return hits;
      }
    }
  } catch {
    return [];
  }
  return hits;
}

const server = new Server(
  { name: "offline-agent-project-tools", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "workspace_info",
      description: "Return the local offline-agent workspace layout and key runtime paths.",
      inputSchema: { type: "object", properties: {}, additionalProperties: false }
    },
    {
      name: "list_projects",
      description: "List project folders under the offline-agent projects directory.",
      inputSchema: { type: "object", properties: {}, additionalProperties: false }
    },
    {
      name: "tool_policy",
      description: "Describe offline versus online tool boundaries for this workspace.",
      inputSchema: { type: "object", properties: {}, additionalProperties: false }
    },
    {
      name: "free_stack_status",
      description: "Return installed local model names and core workspace status.",
      inputSchema: { type: "object", properties: {}, additionalProperties: false }
    },
    {
      name: "search_workspace_index",
      description: "Search the local workspace index created by index-project.cmd.",
      inputSchema: {
        type: "object",
        properties: { query: { type: "string" } },
        required: ["query"],
        additionalProperties: false
      }
    }
  ]
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const name = request.params.name;
  if (name === "workspace_info") {
    return text({
      root,
      node: process.version,
      paths: {
        ollamaModels: process.env.OLLAMA_MODELS,
        hfHome: process.env.HF_HOME,
        continueGlobalDir: process.env.CONTINUE_GLOBAL_DIR,
        opencodeConfig: process.env.OPENCODE_CONFIG
      },
      directories: {
        bin: await dirExists("bin"),
        config: await dirExists("config"),
        models: await dirExists("models"),
        cache: await dirExists("cache"),
        state: await dirExists("state"),
        tools: await dirExists("tools"),
        projects: await dirExists("projects")
      }
    });
  }
  if (name === "list_projects") {
    return text({ projects: await listProjects() });
  }
  if (name === "tool_policy") {
    return text({
      offline: ["filesystem", "git", "memory", "sequential-thinking", "project-tools", "local Ollama"],
      online: ["public web pages through local browser automation"],
      blocked: ["paid APIs", "paid SaaS adapters", "cloud GPU billing", "subscription coding/review tools"],
      rule: "No paid API or subscription-backed adapter is included in this workspace."
    });
  }
  if (name === "free_stack_status") {
    return text({ root, models: await modelNames(), projects: await listProjects() });
  }
  if (name === "search_workspace_index") {
    return text({ hits: await searchWorkspace(String(request.params.arguments?.query || "")) });
  }
  throw new Error(`Unknown tool: ${name}`);
});

if (process.argv.includes("--self-test")) {
  console.log(JSON.stringify({ ok: true, root, projects: await listProjects() }));
  process.exit(0);
}

await server.connect(new StdioServerTransport());
