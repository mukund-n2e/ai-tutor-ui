#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT="$(pwd)"
APP_DIR="."
[[ -d "web" ]] && [[ -f "web/package.json" ]] && APP_DIR="web"

LOG_DIR="$ROOT/.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BR="wp013-handover-pack-${TS}"
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

need(){ command -v "$1" >/dev/null 2>&1; }
git_url(){ git remote get-url origin 2>/dev/null || echo ""; }

# --- 1) Handover.md skeleton ---
cat > Handover.md <<'MD'
# n2e AI Tutor — CTO Handover (v1, 2025‑09‑17)

## Snapshot
- **Repo**: `mukund-n2e/ai-tutor-web`  
- **App dir**: `web/` (app root: `web/src/app`)  
- **Framework**: Next.js 15.5.2 • Node 20.x  
- **Prod**: https://tutorweb-cyan.vercel.app  
- **Public Beta target**: **22 Sep 2025**  
- **Budget caps**: LLM **$50/mo**, Cloud **$100/mo**

## What’s live
- **Tutor (SSE)**: `/tutor` renders server page; client shell streams via `/api/tutor/stream`.  
  - Health routes: `/api/health` → 200 • `/smoke` → 200
- **Courses**: `/courses`, `/courses/getting-started` (SSG, zero LLM use).
- **Brand**: `web/brand/brand.config.json` + `/public/brand/*` wired; tokens synced.
- **Docs**: `README.md`, `docs/STATUS.md`, `docs/DEPLOY.md`, `docs/BRAND.md` reflect current prod.
- **Site hygiene**: `robots.txt`, `sitemap.xml`, `not-found.tsx`, `error.tsx`.
- **Edge middleware**: fixed cookie casing + Web Crypto usage (WP003a).

**In flight / just shipped**
- **Screens harness**: `web/src/design/screens.manifest.ts` + pages under `/screens` (+ alias `/__screens`).
- **Local Sessions**: Save on Tutor → list/export/delete under `/sessions`.  
  (Persists in `localStorage`; no backend writes — safe for budget.)

## Deploy runbook (Git‑based)
> We avoid fragile CLI scopes; Git pushes trigger Vercel.

1) Small change under `web/` → open PR → **Squash & Merge** (author = your GH user).  
2) Vercel picks up `main` (Root Directory=`web`, Production Branch=`main`).  
3) Probe prod endpoints:
MD

# --- 2) Probes ---
SMOKE_LOG="$LOG_DIR/smoke_${TS}.log"
SSE_LOG="$LOG_DIR/sse_${TS}.log"

SMOKE_URL="$PROD_URL"
SSE_URL="$PROD_URL/api/tutor/stream?courseTitle=probe&scope=probe&message=hello"

echo "Running smoke against $SMOKE_URL" | tee -a "$SMOKE_LOG"
if need node; then
  (cd "$APP_DIR" && SMOKE_URL="$SMOKE_URL" node ./scripts/smoke.mjs) 2>&1 | tee -a "$SMOKE_LOG" || true
else
  echo "node not available, skipping smoke" | tee -a "$SMOKE_LOG"
fi

echo "Running SSE probe $SSE_URL" | tee -a "$SSE_LOG"
if need node; then
  node ./docs/sse-probe.mjs "$SSE_URL" 2>&1 | tee -a "$SSE_LOG" || true
else
  if need curl; then
    bash ./docs/sse-probe.sh "$SSE_URL" 2>&1 | tee -a "$SSE_LOG" || true
  else
    echo "Neither node nor curl available; skipping SSE probe" | tee -a "$SSE_LOG"
  fi
fi

# --- 3) Append probe summary to Handover.md ---
{
  echo
  echo "## Probe results ($TS UTC)"
  echo
  echo "### Smoke"
  echo '```text'
  tail -n 80 "$SMOKE_LOG" 2>/dev/null || true
  echo '```'
  echo
  echo "### SSE"
  echo '```text'
  tail -n 80 "$SSE_LOG" 2>/dev/null || true
  echo '```'
} >> Handover.md

# --- 4) Optional: Scope Finder (grep key surfaces) ---
SCOPE_LOG="$LOG_DIR/scope_${TS}.log"
{
  echo "# Scope Finder (key surfaces)"
  echo
  echo "## API routes"
  find "$APP_DIR/src/app/api" -type f \( -name 'route.ts' -o -name 'route.tsx' -o -name 'route.js' \) 2>/dev/null | sed "s#^#$ROOT/#" || true
  echo
  echo "## Tutor transport and validators"
  find "$APP_DIR/src/lib" -type f \( -name 'tutorTransport.ts' -o -name 'validators.ts' -o -name 'renderMarkdown.ts' -o -name 'types.ts' \) 2>/dev/null | sed "s#^#$ROOT/#" || true
  echo
  echo "## Components"
  find "$APP_DIR/src/components" -type f -name '*.tsx' 2>/dev/null | sed "s#^#$ROOT/#" | head -n 40 || true
} | tee "$SCOPE_LOG" >/dev/null

{
  echo
  echo "## Scope Finder"
  echo '```text'
  tail -n 200 "$SCOPE_LOG" 2>/dev/null || true
  echo '```'
} >> Handover.md

# --- 5) Git branch + PR ---
if [[ -n "$(git status --porcelain || true)" ]]; then
  echo "Repository has uncommitted changes; proceeding will commit Handover and logs." >&2
fi

git add Handover.md "$LOG_DIR" || true
git commit -m "docs(handover): CTO Handover v1 with probes (${TS})" || true
git checkout -b "$BR" || git checkout "$BR"
git push -u origin "$BR" || true

if need gh; then
  gh pr create -B main -H "$BR" --title "CTO Handover Pack v1 (${TS})" --body "Automated handover doc with smoke+SSE probe logs and scope finder." || true
else
  echo "Install GitHub CLI (gh) to auto-open PR, or open PR for branch: $BR" >&2
fi

echo
echo "Handover.md created and probes logged under $LOG_DIR"
echo "Branch: $BR"


