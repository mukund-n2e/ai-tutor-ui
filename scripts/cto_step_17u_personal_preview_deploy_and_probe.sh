#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }

need vercel || die "Vercel CLI not found (npm i -g vercel)."
need node   || die "Node is required."

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"

# Use your personal scope
SELF="$(vercel whoami 2>/dev/null || true)"
[ -z "$SELF" ] && die "Not logged in in this shell. Run: vercel login"
# Try to switch; if it fails (older CLI), we continue — personal is often default.
vercel switch "$SELF" >/dev/null 2>&1 || true

ROOT="$(pwd)"
mkdir -p "$ROOT/.cto_logs"
TS="$(date -u +%Y%m%d_%H%M%S)"
DEPLOY_LOG="$ROOT/.cto_logs/vercel_preview_deploy_${TS}.log"
PROBE_LOG="$ROOT/.cto_logs/courses_preview_probe_${TS}.log"

pushd "$APP_DIR" >/dev/null

# Backup existing team link if present
mkdir -p .vercel
if [ -f ".vercel/project.json" ]; then
  cp -f ".vercel/project.json" ".vercel/project.team.bak"
  echo "Backed up team link to .vercel/project.team.bak"
fi

# Ensure .vercel is ignored by git (defensive)
if [ -f "../.gitignore" ] && ! grep -q "^\.vercel/" "../.gitignore"; then
  echo ".vercel/" >> ../.gitignore
fi

# Remote preview deploy (creates a personal project if needed)
echo "Deploying preview to personal scope… (log: $DEPLOY_LOG)"
if ! vercel deploy --yes >"$DEPLOY_LOG" 2>&1; then
  echo "=== CTO PERSONAL PREVIEW SUMMARY START ==="
  echo "Result: FAIL (preview deploy)"
  echo "Deploy log: $DEPLOY_LOG"
  echo "=== CTO PERSONAL PREVIEW SUMMARY END ==="
  # Restore team link if we had one
  if [ -f ".vercel/project.team.bak" ]; then cp -f ".vercel/project.team.bak" ".vercel/project.json"; fi
  popd >/dev/null
  exit 2
fi

# Extract the preview deployment URL
PREVIEW_URL="$(grep -Eo 'https?://[^ ]+\.vercel\.app' "$DEPLOY_LOG" | tail -n1 || true)"
[ -z "$PREVIEW_URL" ] && PREVIEW_URL="(not captured; open the deploy log)"

popd >/dev/null

# Probe preview with cache-busting
echo "Probing $PREVIEW_URL … (log: $PROBE_LOG)"
probe_once() {
  local base="$1"; local path="$2"; local needle="$3"; local t="$(date +%s)"
  [ -z "$base" ] && echo "no" && return 1
  local body code
  body="$(curl -fsSL "$base$path?nocache=$t" -H 'Cache-Control: no-cache' 2>>"$PROBE_LOG" || true)"
  code="$([ -n "$body" ] && echo 200 || curl -s -o /dev/null -w '%{http_code}' "$base$path?nocache=$t" 2>>"$PROBE_LOG")"
  if [ "$code" = "200" ] && echo "$body" | grep -qi "$needle"; then echo "yes"; else echo "no"; fi
}
wait_for() {
  local base="$1"; local path="$2"; local needle="$3"; local label="$4"
  local limit=40; local sleep_s=6
  for i in $(seq 1 $limit); do
    if [ "$(probe_once "$base" "$path" "$needle")" = "yes" ]; then echo "$label: PASS"; return 0; fi
    sleep $sleep_s
  done
  echo "$label: FAIL (timeout)"; return 1
}

R1="$(wait_for "$PREVIEW_URL" "/courses" "Courses" "Preview /courses")" || true
R2="$(wait_for "$PREVIEW_URL" "/courses/getting-started" "Getting Started with the AI Tutor" "Preview /courses/getting-started")" || true

# Restore the original team link file (so future team deploys keep working)
if [ -f "web/.vercel/project.team.bak" ]; then
  cp -f "web/.vercel/project.team.bak" "web/.vercel/project.json"
  echo "Restored team link from .vercel/project.team.bak"
fi

echo "=== CTO PERSONAL PREVIEW SUMMARY START ==="
echo "Result: DONE"
echo "Preview URL: $PREVIEW_URL"
echo "$R1"
echo "$R2"
echo "Deploy log: $DEPLOY_LOG"
echo "Probe log: $PROBE_LOG"
echo "Note: This is your PERSONAL preview (not team prod). SSE/chat may 500 without OPENAI_API_KEY, but Courses are static."
echo "=== CTO PERSONAL PREVIEW SUMMARY END ==="
