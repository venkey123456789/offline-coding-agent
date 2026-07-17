#!/usr/bin/env node
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = process.env.AGENT_HOME || path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const sdkRoot = path.join(root, "tools", "npm", "node_modules", "@modelcontextprotocol", "sdk", "dist", "esm");
const { Client } = await import(pathToFileURL(path.join(sdkRoot, "client", "index.js")).href);
const { StdioClientTransport } = await import(pathToFileURL(path.join(sdkRoot, "client", "stdio.js")).href);

const commonEnv = {
  ...process.env,
  AGENT_HOME: root,
  MEMORY_FILE_PATH: path.join(root, "state", "memory", "memory.jsonl")
};

const servers = [
  {
    name: "filesystem",
    command: "node",
    args: [path.join(root, "tools", "npm", "node_modules", "@modelcontextprotocol", "server-filesystem", "dist", "index.js"), root]
  },
  {
    name: "git",
    command: path.join(root, "tools", "python", "aider-venv", "Scripts", "mcp-server-git.exe"),
    args: ["--repository", path.join(root, "state", "mcp-git-smoke")]
  },
  {
    name: "memory",
    command: "node",
    args: [path.join(root, "tools", "npm", "node_modules", "@modelcontextprotocol", "server-memory", "dist", "index.js")]
  },
  {
    name: "chat-memory",
    command: "node",
    args: [path.join(root, "scripts", "conversation-memory-mcp.mjs")]
  },
  {
    name: "sequential-thinking",
    command: "node",
    args: [path.join(root, "tools", "npm", "node_modules", "@modelcontextprotocol", "server-sequential-thinking", "dist", "index.js")]
  },
  {
    name: "project-tools",
    command: "node",
    args: [path.join(root, "scripts", "project-tools-mcp.mjs")]
  }
];

for (const server of servers) {
  const client = new Client({ name: `check-${server.name}`, version: "1.0.0" });
  const transport = new StdioClientTransport({ command: server.command, args: server.args, env: commonEnv });
  await client.connect(transport);
  const result = await client.listTools();
  await client.close();
  const tools = result.tools.map((tool) => tool.name).sort();
  if (tools.length === 0) {
    throw new Error(`${server.name} returned no tools`);
  }
  console.log(`${server.name}: ${tools.join(", ")}`);
}
