#!/usr/bin/env node
const input = process.argv.slice(2).join(" ") || "local";
console.log(JSON.stringify({ ok: true, input }));
