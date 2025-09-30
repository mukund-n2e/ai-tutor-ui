#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

need vercel || die "Vercel CLI not found (npm i -g vercel)."
if ! vercel whoami >/dev/null 2>&1; then die "Not logged in in this shell. Run: vercel login"; fi
[ -f "$APP_DIR/.vercel/project.json" ] || die "Not linked in $APP_DIR. Run: (cd web && vercel link) first."

ROOT="$(pwd)"
mkdir -p "$ROOT/.cto_logs"
TS="$(date -u +%Y%m%d_%H%M%S)"
DEPLOY_LOG="$ROOT/.cto_logs/vercel_remote_deploy_forced_${TS}.log"
PROBE_LOG="$ROOT/.cto_logs/courses_prod_probe_${TS}.log"

# Extract org/project IDs from project.json via Node (no jq dependency)
ORG_ID="$(node -e "try{console.log(require('./$APP_DIR/.vercel/project.json').orgId||'')}catch(e){process.exit(1)}" 2>/dev/null || true)"
PROJ_ID="$(node -e "try{console.log(require('./$APP_DIR/.vercel/project.json').projectId||'')}catch(e){process.exit(1)}" 2>/dev/null || true)"
if [ -z "$ORG_ID" ] || [ -z "$PROJ_ID" ]; then
  die "Could not read orgId/projectId from $APP_DIR/.vercel/project.json"
fi
echo "Using orgId=$ORG_ID projectId=$PROJ_ID"

# Remote build+deploy to PRODUCTION under the forced scope/project
( cd "$APP_DIR" && VERCEL_ORG_ID="$ORG_ID" VERCEL_PROJECT_ID="$PROJ_ID" vercel deploy --prod --yes ) >"$DEPLOY_LOG" 2>&1 || {
  echo "=== CTO VERCEL REMOTE (FORCED) SUMMARY START ==="
  echo "Result: FAIL"
  echo "Org: $ORG_ID"
  echo "Project: $PROJ_ID"
  echo "Deploy log: $DEPLOY_LOG"
  echo "Hint: If this says 'not authorized' or 'project not found', run: vercel switch <team-slug>  (likely ai_tutor or ai-tutor) and retry."
  echo "=== CTO VERCEL REMOTE (FORCED) SUMMARY END ==="
  exit 2
}

# Try to capture the deployment URL (best effort)
DEPLOY_URL="$(grep -Eo 'https?://[^ ]+\.vercel\.app' "$DEPLOY_LOG" | tail -n1 || true)"

# Probe production with cache-busting
echo "Probing $URL … (log: $PROBE_LOG)"
probe_once() {
  local path="$1"; local needle="$2"; local t="$(date +%s)"
  local body code
  body="$(curl -fsSL "$URL$path?nocache=$t" -H 'Cache-Control: no-cache' 2>>"$PROBE_LOG" || true)"
  code="$([ -n "$body" ] && echo 200 || curl -s -o /dev/null -w '%{http_code}' "$URL$path?nocache=$t" 2>>"$PROBE_LOG")"
  if [ "$code" = "200" ] && echo "$body" | grep -qi "$needle"; then echo "yes"; else echo "no"; fi
}
wait_for() {
  local path="$1"; local needle="$2"; local label="$3"
  local limit="${PROBE_LIMIT:-40}"  # ~5 minutes at 8s intervals
  for i in $(seq 1 $limit); do
    if [ "$(probe_once "$path" "$needle")" = "yes" ]; then echo "$label: PASS"; return 0; fi
    sleep 8
  done
  echo "$label: FAIL (timeout)"; return 1
}

R1="$(wait_for "/courses" "Courses" "Prod /courses")" || true
R2="$(wait_for "/courses/getting-started" "Getting Started with the AI Tutor" "Prod /courses/getting-started")" || true

echo "=== CTO VERCEL REMOTE (FORCED) SUMMARY START ==="
echo "Result: DONE (remote build+deploy issued with forced scope)"
echo "Prod URL: $URL"
[ -n "$DEPLOY_URL" ] && echo "Deployment URL: $DEPLOY_URL"
echo "Deploy log: $DEPLOY_LOG"
echo "$R1"
echo "$R2"
echo "Probe log: $PROBE_LOG"
echo "=== CTO VERCEL REMOTE (FORCED) SUMMARY END ==="
