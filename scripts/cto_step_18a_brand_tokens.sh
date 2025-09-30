#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
APP_APP_DIR="$APP_DIR/src/app"
STY_DIR="$APP_DIR/src/styles"
PUB_DIR="$APP_DIR/public/brand"
SCR_DIR="$APP_DIR/scripts"
BRAND_DIR="$APP_DIR/brand"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/brand_tokens_build_${TS}.log"
BR="wp010-brand-tokens-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"
need node || die "node not found"
need npm  || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"

mkdir -p "$STY_DIR" "$PUB_DIR" "$SCR_DIR" "$BRAND_DIR"

# 1) Brand config (edit later with real values from Figma)
CFG="$BRAND_DIR/brand.config.json"
if [ ! -f "$CFG" ]; then
cat > "$CFG" <<'JSON'
{
  "brandName": "Nudge2Edge",
  "typography": {
    "fontSans": "Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial"
  },
  "light": {
    "bg": "#ffffff",
    "fg": "#0f172a",
    "muted": "#475569",
    "border": "#e5e7eb",
    "card": "#ffffff",
    "accent": "#2563eb",
    "accentContrast": "#ffffff",
    "radius1": "6px",
    "radius2": "10px",
    "shadow1": "0 1px 2px rgba(0,0,0,0.06)"
  },
  "dark": {
    "bg": "#0b1220",
    "fg": "#e6edf3",
    "muted": "#9aa4b2",
    "border": "#1f2a3a",
    "card": "#0f172a",
    "accent": "#3b82f6",
    "accentContrast": "#0b1220",
    "radius1": "6px",
    "radius2": "10px",
    "shadow1": "0 1px 2px rgba(0,0,0,0.4)"
  },
  "icons": {
    "favicon": "/brand/favicon.svg",
    "apple": "/brand/apple-touch-icon.png"
  },
  "logo": { "path": "/brand/logo.svg", "alt": "Nudge2Edge", "height": 24 }
}
JSON
fi

# 2) Sync script → writes tokens.css + components.css, and ensures layout imports
SYNC="$SCR_DIR/brand_sync.mjs"
cat > "$SYNC" <<'JS'
import fs from 'fs'; import path from 'path';
const root = process.cwd();
const appDir = fs.existsSync(path.join(root,'web','package.json')) ? path.join(root,'web') : root;
const cfg = JSON.parse(fs.readFileSync(path.join(appDir,'brand','brand.config.json'),'utf8'));
const styDir = path.join(appDir,'src','styles'); fs.mkdirSync(styDir,{recursive:true});

const tokens = `:root{
  --bg:${cfg.light.bg};--fg:${cfg.light.fg};--muted:${cfg.light.muted};--border:${cfg.light.border};
  --card:${cfg.light.card};--accent:${cfg.light.accent};--accent-contrast:${cfg.light.accentContrast};
  --radius-1:${cfg.light.radius1};--radius-2:${cfg.light.radius2};--shadow-1:${cfg.light.shadow1};
  --font-sans:${cfg.typography.fontSans};
}
@media (prefers-color-scheme: dark){
  :root{
    --bg:${cfg.dark.bg};--fg:${cfg.dark.fg};--muted:${cfg.dark.muted};--border:${cfg.dark.border};
    --card:${cfg.dark.card};--accent:${cfg.dark.accent};--accent-contrast:${cfg.dark.accentContrast};
    --radius-1:${cfg.dark.radius1};--radius-2:${cfg.dark.radius2};--shadow-1:${cfg.dark.shadow1};
  }
}`;
fs.writeFileSync(path.join(styDir,'tokens.css'), tokens);

const comps = `:root{font-family:var(--font-sans);color:var(--fg);background:var(--bg);}
a{color:var(--accent);}
main.page{max-width:960px;margin:40px auto;padding:0 16px;}
.lead{color:var(--muted);margin:8px 0 16px;}
.grid-cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px;}
.card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius-2);padding:16px;box-shadow:var(--shadow-1);}
.card .meta{font-size:14px;color:var(--muted);margin-bottom:8px;}
.topnav{display:flex;align-items:center;gap:16px;padding:12px 16px;border-bottom:1px solid var(--border);}
.brand{display:flex;align-items:center;gap:10px;font-weight:600;}
.brand img{display:block;height:${cfg.logo?.height ?? 24}px;}
`;
fs.writeFileSync(path.join(styDir,'components.css'), comps);

// Ensure layout.tsx exists and imports css (don't rewrite metadata)
const appAppDir = path.join(appDir,'src','app');
fs.mkdirSync(appAppDir, {recursive:true});
const layout = path.join(appAppDir,'layout.tsx');
if(!fs.existsSync(layout)){
  fs.writeFileSync(layout, `import '../styles/tokens.css';\nimport '../styles/components.css';\nexport default function RootLayout({children}:{children:React.ReactNode}){return <html><body>{children}</body></html>}`);
}else{
  let src = fs.readFileSync(layout,'utf8');
  if(!src.includes("src/styles/tokens.css")) src = `import '../styles/tokens.css';\n` + src;
  if(!src.includes("src/styles/components.css")) src = `import '../styles/components.css';\n` + src;
  fs.writeFileSync(layout, src);
}
console.log('brand_sync: wrote tokens.css/components.css and ensured layout imports.');
JS

# 3) Placeholder brand assets
[ -f "$PUB_DIR/logo.svg" ] || cat > "$PUB_DIR/logo.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="120" height="24" viewBox="0 0 120 24" fill="none">
  <rect width="24" height="24" rx="6" fill="#2563eb"/>
  <circle cx="12" cy="12" r="6" fill="#fff"/>
  <text x="32" y="17" font-family="Inter, Arial" font-size="14" fill="currentColor">N2E</text>
</svg>
SVG
[ -f "$PUB_DIR/favicon.svg" ] || cat > "$PUB_DIR/favicon.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><rect width="64" height="64" rx="12" fill="#2563eb"/><circle cx="32" cy="32" r="14" fill="#fff"/></svg>
SVG
if [ ! -f "$PUB_DIR/apple-touch-icon.png" ]; then
  printf '\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000@\000\000\000@\b\006\000\000\000szz\364\000\000\000\006bKGD\000\000\000\000\000\000\371C\257\277\000\000\000\ttIME\007\351\t\020\013!+\353\323\310\000\000\000\021tEXtSoftware\000placeholder\236\336\357\372\000\000\000IIDAT8\213c\370\377\377?\003\025\000\001\016\000\001\365\276\037\036\000\000\000\000IEND\256B`\202' | base64 --decode > "$PUB_DIR/apple-touch-icon.png" 2>/dev/null || true
fi

# 4) Generate tokens/styles
node "$SYNC"

# 5) Build, commit, push PR
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; exit 2; }

git config user.name "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null

git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$CFG" "$SYNC" "$STY_DIR/tokens.css" "$STY_DIR/components.css" "$APP_APP_DIR/layout.tsx" "$PUB_DIR" 2>/dev/null || true
git commit -m "feat(brand): add config-driven tokens + global styles (Step 18a)" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";; https://github.com/*) GH_URL="$REMOTE";; *) GH_URL="";; esac
PR_URL=""
if command -v gh >/dev/null 2>&1; then
  set +e
  PR_URL="$(gh pr list --head "$BR" --json url -q .[0].url 2>/dev/null || true)"
  [ -z "$PR_URL" ] && PR_URL="$(gh pr create --head "$BR" --title "feat(brand): config-driven tokens + global styles" --body "Adds brand.config.json and brand_sync.mjs → tokens.css/components.css. Imports in layout.tsx. Swap logo + set exact brand values, then \`node web/scripts/brand_sync.mjs\`.")"
  set -e
fi

echo "=== CTO STEP 18a SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "Brand config: $CFG"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "Next:"
echo "  1) Merge this PR (squash)."
echo "  2) Replace /public/brand/logo.svg & favicon with your real assets."
echo "  3) Paste exact colors/fonts/radii from Figma into $CFG."
echo "  4) Re-run: node $SCR_DIR/brand_sync.mjs && (cd $APP_DIR && npm run build) → open a small PR."
echo "=== CTO STEP 18a SUMMARY END ==="
