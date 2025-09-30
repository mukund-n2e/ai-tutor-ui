#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }

need vercel || die "Vercel CLI not found (npm i -g vercel)."
need node   || die "Node is required."

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"

SELF="$(vercel whoami 2>/dev/null || true)"
[ -z "$SELF" ] && die "Not logged in in this shell. Run: vercel login"

ROOT="$(pwd)"
mkdir -p "$ROOT/.cto_logs"
TS="$(date -u +%Y%m%d_%H%M%S)"
LINK_LOG="$ROOT/.cto_logs/vercel_preview_link_${TS}.log"
DEPLOY_LOG="$ROOT/.cto_logs/vercel_preview_deploy_${TS}.log"
PROBE_LOG="$ROOT/.cto_logs/courses_preview_probe_${TS}.log"

PREVIEW_PROJECT="${PREVIEW_PROJECT:-tutor_web_preview_${TS}}"

pushd "$APP_DIR" >/dev/null

# 1) Backup & REMOVE team link so CLI won't try the team project
mkdir -p .vercel
if [ -f ".vercel/project.json" ]; then
  cp -f ".vercel/project.json" ".vercel/project.team.bak"
  rm -f ".vercel/project.json"
  echo "Backed up team link to .vercel/project.team.bak and removed project.json"
fi

# 2) Link to a PERSONAL project (non-interactive)
#    We pass --scope "$SELF" and --project "$PREVIEW_PROJECT" so it's created under your personal account.
echo "Linking personal project: $PREVIEW_PROJECT (scope: $SELF)…"
if ! vercel link --yes --scope "$SELF" --project "$PREVIEW_PROJECT" >"$LINK_LOG" 2>&1; then
  echo "Link failed. Log: $LINK_LOG"
  echo "Try interactive linking: (cd $APP_DIR && vercel link) and choose 'Create a new project' under your personal account."
  # Restore team link if we had one
  if [ -f ".vercel/project.team.bak" ]; then mv -f ".vercel/project.team.bak" ".vercel/project.json"; fi
  popd >/dev/null
  exit 2
fi

# 3) Preview deploy (NOT prod)
echo "Deploying PREVIEW under personal scope… (log: $DEPLOY_LOG)"
if ! vercel deploy --yes --scope "$SELF" >"$DEPLOY_LOG" 2>&1; then
  echo "=== CTO PERSONAL PREVIEW SUMMARY START ==="
  echo "Result: FAIL (preview deploy)"
  echo "Preview project: $PREVIEW_PROJECT"
  echo "Deploy log: $DEPLOY_LOG"
  echo "=== CTO PERSONAL PREVIEW SUMMARY END ==="
  # Restore team link
  if [ -f ".vercel/project.team.bak" ]; then mv -f ".vercel/project.team.bak" ".vercel/project.json"; fi
  popd >/dev/null
  exit 2
fi

# 4) Capture preview URL
PREVIEW_URL="$(grep -Eo 'https?://[^ ]+\.vercel\.app' "$DEPLOY_LOG" | tail -n1 || true)"
[ -z "$PREVIEW_URL" ] && PREVIEW_URL="(not captured; open the deploy log)"

popd >/dev/null

# 5) Probe preview with cache-busting
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

# 6) Restore team link (so prod deploys will target the team project once you’re added)
if [ -f "web/.vercel/project.team.bak" ]; then
  mv -f "web/.vercel/project.team.bak" "web/.vercel/project.json"
  echo "Restored team link from .vercel/project.team.bak"
fi

echo "=== CTO PERSONAL PREVIEW SUMMARY START ==="
echo "Result: DONE"
echo "Preview URL: $PREVIEW_URL"
echo "$R1"
echo "$R2"
echo "Preview project: $PREVIEW_PROJECT"
echo "Link log: $LINK_LOG"
echo "Deploy log: $DEPLOY_LOG"
echo "Probe log: $PROBE_LOG"
echo "Note: This is PERSONAL preview (not team prod)."
echo "=== CTO PERSONAL PREVIEW SUMMARY END ==="
