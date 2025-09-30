#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }

need vercel || die "Vercel CLI not found (npm i -g vercel)."

# Sanity: logged in + linked inside web/
if ! vercel whoami >/dev/null 2>&1; then
  die "Not logged in in this shell. Run: vercel login"
fi
[ -f "$APP_DIR/.vercel/project.json" ] || die "Not linked in $APP_DIR. Run: (cd web && vercel link) and select the existing prod project."

ROOT="$(pwd)"
mkdir -p "$ROOT/.cto_logs"
TS="$(date -u +%Y%m%d_%H%M%S)"
DEPLOY_LOG="$ROOT/.cto_logs/vercel_remote_deploy_${TS}.log"
PROBE_LOG="$ROOT/.cto_logs/courses_prod_probe_${TS}.log"

# Remote build+deploy to production
echo "Deploying remotely to production… (log: $DEPLOY_LOG)"
( cd "$APP_DIR" && vercel deploy --prod --yes ) >"$DEPLOY_LOG" 2>&1 || {
  echo "=== CTO VERCEL REMOTE DEPLOY SUMMARY START ==="
  echo "Result: FAIL (deploy command failed)"
  echo "Deploy log: $DEPLOY_LOG"
  echo "=== CTO VERCEL REMOTE DEPLOY SUMMARY END ==="
  exit 2
}

# Try to extract the production deployment URL from output (best effort)
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

echo "=== CTO VERCEL REMOTE DEPLOY SUMMARY START ==="
echo "Result: DONE (remote build+deploy issued)"
echo "Prod URL: $URL"
[ -n "$DEPLOY_URL" ] && echo "Deployment URL: $DEPLOY_URL"
echo "Deploy log: $DEPLOY_LOG"
echo "$R1"
echo "$R2"
echo "Probe log: $PROBE_LOG"
echo "=== CTO VERCEL REMOTE DEPLOY SUMMARY END ==="
