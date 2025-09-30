#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# -------- Settings we know --------
BETA_DATE="${BETA_DATE:-22 Sep 2025}"
LLM_BUDGET="${LLM_BUDGET:-\$50/mo}"
CLOUD_BUDGET="${CLOUD_BUDGET:-\$100/mo}"

TEAM="${TEAM:-ai_tutor}"
PROJECT="${PROJECT:-tutor_web}"
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

# -------- Repo layout --------
ROOT="$(pwd)"
APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
APP_APP_DIR="$APP_DIR/src/app"
DOCS_DIR="$ROOT/docs"; mkdir -p "$DOCS_DIR"
LOG_DIR="$ROOT/.cto_logs"; mkdir -p "$LOG_DIR"

TS_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo 'NA')"
BR="wp011-docs-sync-$(date -u +%Y%m%d_%H%M%S)"

# -------- Live probes (bounded; no hanging) --------
http_code() { curl -sS -o /dev/null -w "%{http_code}" "$1" -H 'Cache-Control: no-cache' || printf '000'; }
HEALTH_CODE="$(http_code "$PROD_URL/api/health")"
SMOKE_CODE="$(http_code "$PROD_URL/smoke?nocache=$(date +%s)")"
COURSES_CODE="$(http_code "$PROD_URL/courses?nocache=$(date +%s)")"
TUTOR_CODE="$(http_code "$PROD_URL/tutor?nocache=$(date +%s)")"
SSE_CODE="$(curl -sSI -o /dev/null -w "%{http_code}" "$PROD_URL/api/tutor/stream" || printf '000')"

# -------- README snapshot (marked block) --------
README="$ROOT/README.md"
SNAP_START="<!-- AUTODOC: SNAPSHOT START -->"
SNAP_END="<!-- AUTODOC: SNAPSHOT END -->"
SNAP_CONTENT="$(cat <<SNAP
$SNAP_START
### Project Snapshot (auto-updated)

- **Repo:** \`$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo .)")\`   
- **App root:** \`$APP_APP_DIR\`  
- **Stack:** Next.js 15 • Node $(node -v 2>/dev/null || echo '>=20') • TypeScript  
- **Team / Project (Vercel):** \`$TEAM\` / \`$PROJECT\`  
- **Production:** [$PROD_URL]($PROD_URL)

**Routes (live check @ $TS_UTC, $SHORT_SHA):**
```
GET /api/health           -> $HEALTH_CODE
GET /smoke                -> $SMOKE_CODE
GET /courses              -> $COURSES_CODE
GET /tutor                -> $TUTOR_CODE
GET /api/tutor/stream     -> $SSE_CODE  (SSE endpoint)
```

**Key Dates / Caps**
- **Public Beta:** $BETA_DATE  
- **Budget caps:** LLM $LLM_BUDGET • Cloud $CLOUD_BUDGET

**Brand pipeline**
- Config: \`$APP_DIR/brand/brand.config.json\`  
- Sync: \`node $APP_DIR/scripts/brand_sync.mjs\` → writes \`$APP_DIR/src/styles/tokens.css\` + \`components.css\`  
- Assets: \`$APP_DIR/public/brand/\` (logo, favicon, apple‑touch icon)

$SNAP_END
SNAP
)"

if [ -f "$README" ]; then
  if grep -q "$SNAP_START" "$README"; then
    awk -v start="$SNAP_START" -v end="$SNAP_END" -v repl="$SNAP_CONTENT" '
      $0 ~ start {print repl; skip=1; next}
      $0 ~ end && skip==1 {skip=0; next}
      skip!=1 {print}
    ' "$README" > "$README.tmp" && mv "$README.tmp" "$README"
  else
    printf "\n%s\n" "$SNAP_CONTENT" >> "$README"
  fi
else
  cat > "$README" <<EOF
# Nudge2Edge — AI Tutor (Web)

Minimal AI Tutor web app (Next.js 15) with SSE chat and static course pages.

$SNAP_CONTENT

## Local Dev
```bash
cd $APP_DIR
npm i
npm run dev
```

## Deploy
- Auto-deploys on merge to \`main\` (Vercel project: \`$TEAM/$PROJECT\`)
- Root Directory: \`web\` • Framework: Next.js • Node: 20/22

## Brand
Edit \`$APP_DIR/brand/brand.config.json\` and run:
```bash
node $APP_DIR/scripts/brand_sync.mjs
```
EOF
fi

# -------- docs/STATUS.md --------
cat > "$DOCS_DIR/STATUS.md" <<EOF
# Project Status — $TS_UTC

**Production:** [$PROD_URL]($PROD_URL)  \\
**Commit:** \`$SHORT_SHA\`  \\
**Team/Project:** \`$TEAM/$PROJECT\`

## Live Checks
```
GET /api/health       -> $HEALTH_CODE
GET /smoke            -> $SMOKE_CODE
GET /courses          -> $COURSES_CODE
GET /tutor            -> $TUTOR_CODE
SSE /api/tutor/stream -> $SSE_CODE
```

## Milestones
- ✅ Step 16 — Courses scaffold (/courses, /courses/getting-started)
- ✅ Step 17 — Merge/probe; Next 15 fixes (PageProps, Tutor metadata)
- ✅ Step 18a — Brand pipeline (config → tokens.css)
- ⏳ Step 18b — Apply design pack values & assets
- 🔜 WP‑003 — Budget hardening (transport + caps)

## Caps
- LLM: $LLM_BUDGET
- Cloud: $CLOUD_BUDGET
EOF

# -------- docs/DEPLOY.md --------
cat > "$DOCS_DIR/DEPLOY.md" <<'EOF'
# Deploy Runbook

**Source of truth:** Git → Vercel (Production tracks `main`).

## Vercel Project
- Team / Project: `ai_tutor / tutor_web`
- Root Directory: `web`
- Framework: Next.js
- Node: 20.x or 22.x
- Domains: `tutorweb-cyan.vercel.app` (Production)

## Deploying
- Merge to `main` → Production deploy automatically.
- If needed, use a Deploy Hook (Settings → Git → Deploy Hooks) and POST to trigger.

## Troubleshooting
- 404 after merge → confirm Root Directory = `web` and Production Branch = `main`.
- Build fails on Next 15 types → ensure `/courses/[slug]` uses Promise-based params and tutor page metadata is on a Server Component.
- Vercel author check → squash commits with your GitHub user (avoid `cursor@local`).
EOF

# -------- docs/BRAND.md --------
cat > "$DOCS_DIR/BRAND.md" <<EOF
# Brand & Tokens

## Files
- Config: \`$APP_DIR/brand/brand.config.json\`
- Sync script: \`$APP_DIR/scripts/brand_sync.mjs\`
- Output CSS: \`$APP_DIR/src/styles/tokens.css\`, \`components.css\`
- Public assets: \`$APP_DIR/public/brand/\` (logo.svg, favicon.svg, apple-touch-icon.png)

## Apply changes
1. Update colors/fonts/radii/logo paths in \`brand.config.json\`.
2. Run:
   ```bash
   node $APP_DIR/scripts/brand_sync.mjs
   (cd $APP_DIR && npm run build)
   ```
3. Open a small PR with the CSS diffs.

## From your design pack
If you placed assets/configs under \`~/n2e-AI-tutor/ai-tutor-design-pack-v5\`, run:
```bash
bash cto_step_18b_ingest_design_pack.sh           # analyze → writes brand.auto.json + summary
APPLY=1 bash cto_step_18b_ingest_design_pack.sh   # apply → regenerates CSS + opens PR
```
EOF

# -------- Commit & PR --------
 git config user.name  "mukund-n2e" >/dev/null
 git config user.email "mukund-6019@users.noreply.github.com" >/dev/null

 git fetch -q origin || true
 git checkout -q main || true
 git pull --ff-only -q origin main || true
 git switch -c "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
 git add "$README" "$DOCS_DIR/STATUS.md" "$DOCS_DIR/DEPLOY.md" "$DOCS_DIR/BRAND.md"
 git commit -m "docs: sync README snapshot + STATUS/DEPLOY/BRAND (Step 18c)" >/dev/null 2>&1 || true
 git push -u origin "$BR" >/dev/null 2>&1 || true

 REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
 case "$REMOTE" in
   git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
   https://github.com/*) GH_URL="$REMOTE";;
   *) GH_URL="";;
 esac

 PR_URL=""
 if command -v gh >/dev/null 2>&1; then
   set +e
   PR_URL="$(gh pr list --head "$BR" --json url -q '.[0].url' 2>/dev/null || true)"
   if [ -z "$PR_URL" ]; then
     PR_URL="$(gh pr create --head "$BR" --title "docs: sync project docs (snapshot + status + runbooks)" --body "Auto-updated README snapshot, STATUS, DEPLOY, BRAND. Snapshot has live probe results. Safe to squash." 2>/dev/null || true)"
   fi
   set -e
 fi

 echo "=== CTO DOCS SYNC SUMMARY START ==="
 echo "README: $README"
 echo "STATUS: $DOCS_DIR/STATUS.md"
 echo "DEPLOY: $DOCS_DIR/DEPLOY.md"
 echo "BRAND:  $DOCS_DIR/BRAND.md"
 echo "Prod checks: health=$HEALTH_CODE smoke=$SMOKE_CODE courses=$COURSES_CODE tutor=$TUTOR_CODE sse=$SSE_CODE"
 if [ -n "$PR_URL" ]; then echo "PR: $PR_URL"; elif [ -n "$GH_URL" ]; then echo "Compare: $GH_URL/compare/$BR?expand=1"; fi
 echo "=== CTO DOCS SYNC SUMMARY END ==="
