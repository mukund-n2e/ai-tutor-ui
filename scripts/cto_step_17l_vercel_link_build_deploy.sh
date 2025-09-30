#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }

need vercel || die "Vercel CLI not found. Install with: npm i -g vercel"

# Confirm login
if ! vercel whoami >/dev/null 2>&1; then
  echo "You need to login once: vercel login"
  exit 2
fi

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

ROOT="$(pwd)"
mkdir -p "$ROOT/.cto_logs"
TS="$(date -u +%Y%m%d_%H%M%S)"
PULL_LOG="$ROOT/.cto_logs/vercel_pull_${TS}.log"
BUILD_LOG="$ROOT/.cto_logs/vercel_build_${TS}.log"
DEPLOY_LOG="$ROOT/.cto_logs/vercel_deploy_${TS}.log"
PROBE_LOG="$ROOT/.cto_logs/courses_prod_probe_${TS}.log"

pushd "$APP_DIR" >/dev/null

# Link to the existing Vercel project if not already linked (.vercel/project.json)
if [ ! -f ".vercel/project.json" ]; then
  echo "Linking this directory to your Vercel project…"
  # This will prompt to pick the team and the correct project (choose the production project for tutorweb-cyan)
  vercel link || die "vercel link failed; please re-run and choose the existing project for this app."
fi

# Pull prod env (best-effort)
vercel pull --yes --environment=production >"$PULL_LOG" 2>&1 || true

# Build prebuilt output
echo "Building prebuilt output… (log: $BUILD_LOG)"
if ! vercel build --prod >"$BUILD_LOG" 2>&1; then
  echo "=== CTO VERCEL PREBUILT SUMMARY START ==="
  echo "Phase: build"
  echo "Result: FAIL"
  echo "Build log: $BUILD_LOG"
  echo "=== CTO VERCEL PREBUILT SUMMARY END ==="
  exit 2
fi

# Deploy prebuilt to prod
echo "Deploying prebuilt to production… (log: $DEPLOY_LOG)"
if ! vercel deploy --prebuilt --prod --yes >"$DEPLOY_LOG" 2>&1; then
  echo "=== CTO VERCEL PREBUILT SUMMARY START ==="
  echo "Phase: deploy"
  echo "Result: FAIL"
  echo "Deploy log: $DEPLOY_LOG"
  echo "=== CTO VERCEL PREBUILT SUMMARY END ==="
  exit 2
fi

popd >/dev/null

# Probe production with cache-busting until routes are live
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
  local limit=80; local sleep_s=8
  for i in $(seq 1 $limit); do
    if [ "$(probe_once "$path" "$needle")" = "yes" ]; then echo "$label: PASS"; return 0; fi
    sleep $sleep_s
  done
  echo "$label: FAIL (timeout)"; return 1
}

R1="$(wait_for "/courses" "Courses" "Prod /courses")" || true
R2="$(wait_for "/courses/getting-started" "Getting Started with the AI Tutor" "Prod /courses/getting-started")" || true

echo "=== CTO VERCEL PREBUILT SUMMARY START ==="
echo "Phase: full (link+build+deploy+probe)"
echo "Result: DONE"
echo "Prod URL: $URL"
echo "Pull log: $PULL_LOG"
echo "Build log: $BUILD_LOG"
echo "Deploy log: $DEPLOY_LOG"
echo "$R1"
echo "$R2"
echo "Probe log: $PROBE_LOG"
echo "=== CTO VERCEL PREBUILT SUMMARY END ==="
