#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# --- Inputs ---
PACK="${PACK:-/Users/mt/n2e-AI-tutor/ai-tutor-design-pack-v5}"  # override if needed
APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
APP_APP_DIR="$APP_DIR/src/app"
PUB_DIR="$APP_DIR/public/design/screens"
DESIGN_DIR="$APP_DIR/design"
MANIFEST_TS="$DESIGN_DIR/screens.manifest.ts"
SCREENS_DIR="$APP_APP_DIR/__screens"
COMP_DIR="$APP_DIR/src/components"
TOPNAV="$COMP_DIR/TopNav.tsx"

LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/screens_harness_build_${TS}.log"
BR="wp019a-screens-harness-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }

need git || die "git not found"
need node || die "node not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"
[ -d "$PACK" ] || die "Design pack not found at: $PACK"

mkdir -p "$PUB_DIR" "$DESIGN_DIR" "$SCREENS_DIR" "$SCREENS_DIR/[slug]"

# --- Node ingestor: scans PACK, copies images → /public/design/screens, writes manifest.ts ---
mkdir -p scripts
cat > scripts/screens_ingest.mjs <<'JS'
import fs from 'fs';
import path from 'path';

const root = process.cwd();
const appDir = fs.existsSync(path.join(root,'web','package.json')) ? path.join(root,'web') : root;
const pack = process.env.PACK || '/Users/mt/n2e-AI-tutor/ai-tutor-design-pack-v5';
const outPublic = path.join(appDir, 'public', 'design', 'screens');
const outDesign = path.join(appDir, 'design');
const manifestPath = path.join(outDesign, 'screens.manifest.ts');

fs.mkdirSync(outPublic, { recursive: true });
fs.mkdirSync(outDesign, { recursive: true });

const exts = new Set(['.png','.jpg','.jpeg','.svg','.webp']);
function slugify(name) {
  return name
    .toLowerCase()
    .replace(/\.[^.]+$/, '')
    .replace(/[_\s]+/g,'-')
    .replace(/[^a-z0-9-]/g,'')
    .replace(/-+/g,'-')
    .replace(/^-|-$/g,'');
}
function titleFrom(name) {
  const base = name.replace(/\.[^.]+$/, '').replace(/[-_]+/g,' ').trim();
  return base.charAt(0).toUpperCase() + base.slice(1);
}

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(p);
    else {
      const ext = path.extname(entry.name).toLowerCase();
      if (exts.has(ext)) files.push(p);
    }
  }
}
const files = [];
walk(pack);

const seen = new Map();
const records = [];
for (const abs of files) {
  const base = path.basename(abs);
  let slug = slugify(base);
  if (!slug) continue;
  // dedupe slugs
  let s = slug, i = 2;
  while (seen.has(s)) { s = `${slug}-${i++}`; }
  seen.set(s, true);

  // route suggestion
  const map = {
    'home': '/',
    'landing': '/',
    'tutor':'/tutor',
    'chat':'/tutor',
    'courses':'/courses',
    'course-wall':'/courses',
    'getting-started':'/courses/getting-started',
    'sessions':'/sessions',
    'settings':'/settings',
    'ship':'/ship',
    'onboarding':'/onboarding'
  };
  let route = map[s] || map[slug] || `/wip/${s}`;

  // copy asset into public
  const dest = path.join(outPublic, base);
  fs.copyFileSync(abs, dest);

  records.push({
    slug: s,
    title: titleFrom(base),
    file: base,
    route
  });
}

// mark existence of app routes
function pageExists(route) {
  if (route === '/') return true;
  const rel = route.replace(/^\/+/,''); // remove leading slash
  const routeDir = path.join(appDir, 'src', 'app', rel);
  return fs.existsSync(path.join(routeDir, 'page.tsx'));
}
for (const r of records) r.exists = pageExists(r.route);

// write TS manifest
const ts = `export type Screen = { slug: string; title: string; file: string; route: string; exists: boolean };
export const screens: Screen[] = ${JSON.stringify(records, null, 2)};`;
fs.writeFileSync(manifestPath, ts, 'utf8');

console.log(JSON.stringify({ copied: records.length, manifest: path.relative(root, manifestPath) }));
JS

# Run the ingestor
OUT_JSON="$(PACK="$PACK" node scripts/screens_ingest.mjs)"
COPIED="$(echo "$OUT_JSON" | node -e "process.stdin.once('data',d=>{try{const j=JSON.parse(d);console.log(j.copied||0);}catch{console.log(0)}})")"

# --- Pages: /__screens (index + detail) ---
cat > "$SCREENS_DIR/page.tsx" <<'TSX'
import Link from 'next/link';
import { screens } from '../../design/screens.manifest';

export const metadata = { title: 'Screens' };

export default function ScreensIndex() {
  return (
    <main style={{maxWidth: 1100, margin: '40px auto', padding: '0 16px'}}>
      <h1 style={{marginBottom: 8}}>Design Screens</h1>
      <p style={{opacity: 0.8, marginBottom: 20}}>Static previews imported from the design pack. Use this to verify visual parity.</p>
      <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 16}}>
        {screens.map(s => (
          <article key={s.slug} style={{border: '1px solid #e5e7eb', borderRadius: 8, padding: 12}}>
            <div style={{height: 160, display:'flex', alignItems:'center', justifyContent:'center', overflow:'hidden', background:'#fafafa', border:'1px solid #eee', borderRadius:6}}>
              <img src={`/design/screens/${s.file}`} alt={s.title} style={{maxWidth:'100%', maxHeight:'100%', objectFit:'contain'}} />
            </div>
            <h3 style={{margin: '12px 0 6px'}}>{s.title}</h3>
            <div style={{fontSize: 12, opacity: 0.85, marginBottom: 10}}>Slug: <code>{s.slug}</code></div>
            <div style={{display:'flex', gap:12, fontSize:14}}>
              <Link href={`/__screens/${s.slug}`}>Open →</Link>
              <span style={{opacity:0.7}}>|</span>
              <Link href={s.route}>{s.exists ? 'Go to page' : 'Suggested route'} →</Link>
            </div>
            {!s.exists && <div style={{fontSize:12, color:'#b45309', marginTop:8}}>Route not implemented yet</div>}
          </article>
        ))}
      </div>
    </main>
  );
}
TSX

mkdir -p "$SCREENS_DIR/[slug]"
cat > "$SCREENS_DIR/[slug]/page.tsx" <<'TSX'
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { screens } from '../../../design/screens.manifest';

export async function generateStaticParams() {
  return screens.map(s => ({ slug: s.slug }));
}

export function generateMetadata({ params }: { params: { slug: string }}) {
  const s = screens.find(x => x.slug === params.slug);
  return { title: s ? `Screen • ${s.title}` : 'Screen' };
}

export default function ScreenPage({ params }: { params: { slug: string }}) {
  const s = screens.find(x => x.slug === params.slug);
  if (!s) return notFound();
  return (
    <main style={{maxWidth: 1100, margin: '40px auto', padding: '0 16px'}}>
      <p style={{marginBottom: 10}}><Link href="/__screens">← All screens</Link></p>
      <h1 style={{margin: '0 0 12px'}}>{s.title}</h1>
      <div style={{fontSize: 14, opacity: 0.8, marginBottom: 12}}>
        slug: <code>{s.slug}</code> • {s.exists ? 'Implemented route' : 'Suggested'}: <Link href={s.route}>{s.route}</Link>
      </div>
      <div style={{border:'1px solid #e5e7eb', borderRadius: 8, overflow:'hidden', background:'#fafafa'}}>
        <img src={`/design/screens/${s.file}`} alt={s.title} style={{display:'block', width:'100%', height:'auto'}} />
      </div>
    </main>
  );
}
TSX

# --- Dev-only TopNav link (guarded by NEXT_PUBLIC_SHOW_SCREENS=1) ---
if [ -f "$TOPNAV" ]; then
  # Ensure Link import
  if ! grep -q "from 'next/link'" "$TOPNAV"; then
    sed -i.bak "1s|^|import Link from 'next/link';\n|" "$TOPNAV" && rm -f "$TOPNAV.bak"
  fi
  # Insert conditional link before </nav> if not present
  if ! grep -q "/__screens" "$TOPNAV"; then
    awk '1; /<\/nav>/{print "      {process.env.NEXT_PUBLIC_SHOW_SCREENS === '\''1'\'' && <Link href=\"/__screens\">Screens</Link>}"}' "$TOPNAV" > "$TOPNAV.tmp" && mv "$TOPNAV.tmp" "$TOPNAV"
  fi
fi

# --- Build check ---
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 160 "$BUILD_LOG" || true; exit 2; }

# --- Commit & PR ---
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$PUB_DIR" "$DESIGN_DIR" "$SCREENS_DIR" "$TOPNAV" 2>/dev/null || true
git commit -m "feat(screens): ingest design pack → /__screens harness + manifest (Step 19a)" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac

PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr list --head "$BR" --json url -q .[0].url 2>/dev/null || true)"
  [ -z "$PR_URL" ] && PR_URL="$(gh pr create --head "$BR" --title "feat(screens): design pack harness /__screens" --body "Imports ${COPIED} screen assets; adds manifest + index/detail pages; optional TopNav link via NEXT_PUBLIC_SHOW_SCREENS=1.")"
fi

echo "=== CTO 19a SCREENS HARNESS SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "Design pack: $PACK"
echo "Assets copied: ${COPIED:-0}"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "Routes: /__screens , /__screens/[slug]"
echo "Dev link: set NEXT_PUBLIC_SHOW_SCREENS=1 to show TopNav link"
echo "=== CTO 19a SCREENS HARNESS SUMMARY END ==="
