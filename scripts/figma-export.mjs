// scripts/figma-export.mjs
// Exports PNGs for the node IDs in design/frames.json via /images API

import fs from "node:fs/promises";

const TOKEN = process.env.FIGMA_TOKEN;
const FILE_KEY = process.env.FIGMA_FILE_KEY;
const BRANCH_ID = process.env.FIGMA_BRANCH_ID || null;

const api = async (path, params = {}) => {
  const url = new URL(`https://api.figma.com/v1/${path}`);
  if (BRANCH_ID) url.searchParams.set("branch_id", BRANCH_ID);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  const res = await fetch(url, { headers: { "X-Figma-Token": TOKEN } });
  if (!res.ok) throw new Error(`Figma API ${res.status}: ${await res.text()}`);
  return res.json();
};

const download = async (url, dest) => {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`Download ${r.status}`);
  const buf = Buffer.from(await r.arrayBuffer());
  await fs.writeFile(dest, buf);
};

const main = async () => {
  if (!TOKEN || !FILE_KEY) throw new Error("Missing FIGMA_TOKEN or FIGMA_FILE_KEY in env.");
  const frames = JSON.parse(await fs.readFile("design/frames.json", "utf8"));
  const ids = Object.values(frames.frames)
    .flatMap(({ desktop, mobile }) => [desktop, mobile])
    .filter(id => id && !id.startsWith("MISSING") && !id.startsWith("NOT_FOUND"));

  if (!ids.length) {
    console.log("No valid node IDs to export.");
    return;
  }

  const { images } = await api(`images/${FILE_KEY}`, { ids: ids.join(","), format: "png", scale: "2" });
  await fs.mkdir("design/exports", { recursive: true });

  for (const [id, url] of Object.entries(images)) {
    if (!url) continue;
    const safe = id.replace(/[:]/g, "_");
    await download(url, `design/exports/${safe}.png`);
    console.log(`Exported ${safe}.png`);
  }
};

main().catch(e => { console.error(e); process.exit(1); });


