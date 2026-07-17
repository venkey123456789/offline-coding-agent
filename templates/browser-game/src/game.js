const canvas = document.querySelector("#game");
const ctx = canvas.getContext("2d");
const player = { x: 120, y: 120, vx: 0, vy: 0, size: 28 };
const keys = new Set();

addEventListener("keydown", (event) => keys.add(event.key.toLowerCase()));
addEventListener("keyup", (event) => keys.delete(event.key.toLowerCase()));

function step() {
  player.vx = (keys.has("d") || keys.has("arrowright") ? 1 : 0) - (keys.has("a") || keys.has("arrowleft") ? 1 : 0);
  player.vy = (keys.has("s") || keys.has("arrowdown") ? 1 : 0) - (keys.has("w") || keys.has("arrowup") ? 1 : 0);
  player.x = Math.max(0, Math.min(canvas.width - player.size, player.x + player.vx * 4));
  player.y = Math.max(0, Math.min(canvas.height - player.size, player.y + player.vy * 4));
  draw();
  requestAnimationFrame(step);
}

function draw() {
  ctx.fillStyle = "#0d1117";
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = "#58a6ff";
  ctx.fillRect(player.x, player.y, player.size, player.size);
  ctx.fillStyle = "#c9d1d9";
  ctx.font = "16px Arial";
  ctx.fillText("WASD / arrows", 24, 32);
}

step();
