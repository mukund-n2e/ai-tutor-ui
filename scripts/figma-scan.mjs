// scripts/figma-scan.mjs
// Node 20+
// Discovers top-level frames per page, auto-picks "desktop" (~1440x900) and "mobile" (~390x844)
// and writes design/frames.json for: landing, role, readiness, proposal, session, validator, export

import fs from "node:fs/promises";

const TOKEN = process.env.FIGMA_TOKEN;
const FILE_KEY = process.env.FIGMA_FILE_KEY;
const BRANCH_ID = process.env.FIGMA_BRANCH_ID || null;

// Heuristics (tweak if your spec differs)
const TARGETS = {
  landing: "01_Landing",
  role: "02_Onboarding_Role",
  readiness: "03_Onboarding_Readiness",
  proposal: "04_QuickWin_Proposal",
  session: "05_Session",
  validator: "06_Validator",
  export: "Export"
};

// Desktop/mobile target sizes (w,h) with tolerance
const DESKTOP = { w: 1440, h: 900, tol: 40 };
const MOBILE  = { w: 390,  h: 844, tol: 20 };

// ---- helpers
const api = async (path) => {
  const url = new URL(`https://api.figma.com/v1/${path}`);
  if (BRANCH_ID) url.searchParams.set("branch_id", BRANCH_ID);
  const res = await fetch(url, { headers: { "X-Figma-Token": TOKEN } });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Figma API ${res.status}: ${text}`);
  }
  return res.json();
};

const almost = (a, b, tol) => Math.abs(a - b) <= tol;

// Recursively walk nodes and collect top-level frames under a page
const collectTopLevelFrames = (pageNode) => {
  const frames = [];
  for (const child of pageNode.children || []) {
    if (child.type === "FRAME") frames.push(child);
  }
  return frames;
};

const pickBySize = (frames, target) => {
  let best = frames.find(n => {
    const bb = n.absoluteBoundingBox;
    return bb && almost(bb.width, target.w, target.tol) && almost(bb.height, target.h, target.tol);
  });
  if (best) return best;
  const byName = frames.find(n => {
    const name = (n.name || "").toLowerCase();
    return name.includes(target === DESKTOP ? "desktop" : "mobile") || name.includes(String(target.w));
  });
  return byName || null;
};

const nodeIdOf = (node) => node?.id || null;

const main = async () => {
  if (!TOKEN || !FILE_KEY) throw new Error("Missing FIGMA_TOKEN or FIGMA_FILE_KEY in env.");

  const file = await api(`files/${FILE_KEY}`);
  const pages = (file.document?.children || []).reduce((acc, p) => { acc[p.name] = p; return acc; }, {});

  const out = {
    breakpoints: { desktop: [DESKTOP.w, DESKTOP.h], mobile: [MOBILE.w, MOBILE.h] },
    frames: {},
    tokensMode: "Light"
  };

  for (const [key, pageName] of Object.entries(TARGETS)) {
    const page = pages[pageName];
    if (!page) { out.frames[key] = { desktop: "MISSING_PAGE", mobile: "MISSING_PAGE" }; continue; }
    const frames = collectTopLevelFrames(page);
    const desktop = pickBySize(frames, DESKTOP) || frames[0] || null;
    const mobile  = pickBySize(frames, MOBILE)  || desktop;
    out.frames[key] = {
      desktop: nodeIdOf(desktop) || "NOT_FOUND",
      mobile:  nodeIdOf(mobile)  || "NOT_FOUND"
    };
  }

  await fs.mkdir("design", { recursive: true });
  await fs.writeFile("design/frames.json", JSON.stringify(out, null, 2), "utf8");
  console.log("Wrote design/frames.json");
};

main().catch(err => { console.error(err); process.exit(1); });


