#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
DEPLOY_LOG="$LOG_DIR/screens_prod_deploy_${TS}.log"
PROBE_LOG="$LOG_DIR/screens_prod_probe_${TS}.log"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need vercel || die "vercel CLI not found (npm i -g vercel)"

# 1) Make sure we’re linked to the right Vercel project (pull settings)
echo "Pulling Vercel prod settings…"
vercel pull --yes --environment=production >/dev/null 2>&1 || true

# 2) Sanity: check .vercel/project.json for rootDirectory: web
RD="$(node -e "try{const p=require('./.vercel/project.json');process.stdout.write(p?.settings?.rootDirectory||'')}catch{}")"
if [ "$RD" != "web" ]; then
  echo "WARN: .vercel/project.json missing or rootDirectory!='web'. Vercel will still try to deploy; if it fails, check project link." >&2
fi

# 3) Non-interactive production deploy (from repo root; project.json should point into web)
echo "Deploying to PROD… (log: $DEPLOY_LOG)"
if ! vercel deploy --prod --yes >"$DEPLOY_LOG" 2>&1; then
  echo "Deploy FAILED. See $DEPLOY_LOG"
  exit 2
fi

# 4) Locate manifest and preferred base path
MF=""
for p in "web/src/design/screens.manifest.ts" "web/design/screens.manifest.ts"; do
  [ -f "$p" ] && MF="$p" && break
done
if [ -z "$MF" ]; then
  echo "Manifest not found; looked for web/src/design/screens.manifest.ts and web/design/screens.manifest.ts" | tee -a "$PROBE_LOG"
  exit 2
fi

# extract slugs
SLUGS="$(node -e "const fs=require('fs');const s=fs.readFileSync('$MF','utf8');const a=s.indexOf('['),b=s.lastIndexOf(']');if(a<0||b<0)process.exit(2);const arr=JSON.parse(s.slice(a,b+1));console.log(arr.map(x=>x.slug).join('\n'))")"

probe_one () {
  local path="$1"
  local code
  code="$(curl -s -o /dev/null -w "%{http_code}" "${PROD_URL}${path}?nocache=$(date +%s)")"
  echo "  ${path} -> ${code}" | tee -a "$PROBE_LOG"
  [ "$code" = "200" ]
}

echo "Probing ${PROD_URL} … (log: $PROBE_LOG)"

# Try /screens first; fallback to /__screens
BASE="/screens"
if ! probe_one "$BASE"; then
  BASE="/__screens"
  probe_one "$BASE" >/dev/null || true
fi

# probe a few detail pages (bounded)
ok=0; fail=0
count=0
while IFS= read -r slug; do
  [ -z "$slug" ] && continue
  count=$((count+1))
  probe_one "${BASE}/${slug}" && ok=$((ok+1)) || fail=$((fail+1))
  [ $count -ge 10 ] && break   # cap to 10 pages for speed
done <<< "$SLUGS"

echo "=== CTO 19a2 PROD DEPLOY+PROBE SUMMARY START ==="
echo "Prod: $PROD_URL"
echo "Deploy log: $DEPLOY_LOG"
echo "Probe log:  $PROBE_LOG"
echo "Base path used: $BASE"
echo "Detail probes: PASS=$ok FAIL=$fail (capped to 10)"
echo "Tip: Set NEXT_PUBLIC_SHOW_SCREENS=1 in Vercel env if you want a nav link."
echo "=== CTO 19a2 PROD DEPLOY+PROBE SUMMARY END ==="
