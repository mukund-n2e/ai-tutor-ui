#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

TEAM="${TEAM:-ai_tutor}"           # expected team slug for prod project
PROJECT="${PROJECT:-tutor_web}"     # expected Vercel project name
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need vercel || die "vercel CLI not found (npm i -g vercel)"
need node   || die "node not found"
need curl   || die "curl not found"

LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
DEPLOY_LOG="$LOG_DIR/screens_prod_deploy_${TS}.log"
PROBE_LOG="$LOG_DIR/screens_prod_probe_${TS}.log"

echo "=== STEP: verify scope and link ==="
echo "vercel whoami: $(vercel whoami 2>/dev/null || echo '<unknown>')"
echo "Switching scope to team: $TEAM"
if ! vercel switch "$TEAM" >/dev/null 2>&1; then
  echo "ERROR: cannot switch to team '$TEAM'. Check your Vercel access to that team."
  exit 2
fi

# If project.json is missing or points to a different project/org, relink.
NEED_LINK="no"
if [ ! -f ".vercel/project.json" ]; then
  NEED_LINK="yes"
else
  # sanity read of project.json
  node -e "try{
    const p=require('./.vercel/project.json');
    if (!p.projectName || p.projectName!=='$PROJECT') process.exit(1);
  }catch{ process.exit(1) }" || NEED_LINK="yes"
fi

if [ "$NEED_LINK" = "yes" ]; then
  echo "Linking repo root to project: $PROJECT (team: $TEAM)…"
  # non-interactive first; if it fails, fallback to interactive
  vercel link --yes --scope "$TEAM" --project "$PROJECT" >/dev/null 2>&1 || vercel link
fi

# Make sure rootDirectory is 'web' (so deploy from repo root works)
echo "Ensuring .vercel/project.json has settings.rootDirectory = web"
node -e "try{
  const fs=require('fs');
  const p=JSON.parse(fs.readFileSync('.vercel/project.json','utf8'));
  p.settings = p.settings || {};
  if (p.settings.rootDirectory!=='web'){ p.settings.rootDirectory='web'; fs.writeFileSync('.vercel/project.json', JSON.stringify(p,null,2)); console.log('patched'); }
}catch(e){ console.error('WARN: unable to patch project.json'); }"

echo "Pulling PROD env/settings…"
vercel pull --yes --environment=production --scope "$TEAM" >/dev/null 2>&1 || true

echo "=== STEP: deploy to PROD ==="
if ! vercel deploy --prod --yes --scope "$TEAM" >"$DEPLOY_LOG" 2>&1; then
  echo "Deploy FAILED. Tail of log:"
  tail -n 120 "$DEPLOY_LOG" || true
  echo "Full log: $DEPLOY_LOG"
  exit 2
fi

echo "=== STEP: probe /screens (and fallback to /__screens) ==="
# Locate manifest to enumerate a few slugs
MF=""
for p in "web/src/design/screens.manifest.ts" "web/design/screens.manifest.ts"; do
  [ -f "$p" ] && MF="$p" && break
done
if [ -z "$MF" ]; then
  echo "WARN: Manifest not found; probing only the index route." | tee -a "$PROBE_LOG"
fi

probe() {
  local path="$1"
  local code
  code="$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL$path?nocache=$(date +%s)")"
  echo "  $path -> $code" | tee -a "$PROBE_LOG"
  [ "$code" = "200" ]
}

BASE="/screens"
if ! probe "$BASE"; then
  BASE="/__screens"
  probe "$BASE" >/dev/null || true
fi

ok=0; fail=0; count=0
if [ -n "$MF" ]; then
  SLUGS="$(node -e "const fs=require('fs');const s=fs.readFileSync('$MF','utf8');const a=s.indexOf('['),b=s.lastIndexOf(']');if(a<0||b<0)process.exit(0);const arr=JSON.parse(s.slice(a,b+1));console.log(arr.map(x=>x.slug).join('\n'))")"
  while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    count=$((count+1))
    probe "$BASE/$slug" && ok=$((ok+1)) || fail=$((fail+1))
    [ $count -ge 10 ] && break
  done <<< "$SLUGS"
fi

echo "=== CTO 19a2 FIX LINK+DEPLOY+PROBE SUMMARY START ==="
echo "Team: $TEAM"
echo "Project: $PROJECT"
echo "Prod: $PROD_URL"
echo "Deploy log: $DEPLOY_LOG"
echo "Probe log:  $PROBE_LOG"
echo "Used base:  $BASE"
echo "Detail probes: PASS=$ok FAIL=$fail (max 10)"
echo "=== CTO 19a2 FIX LINK+DEPLOY+PROBE SUMMARY END ==="
