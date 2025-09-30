#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

TEAM="${TEAM:-ai_tutor}"
PROJECT="${PROJECT:-tutor_web}"
APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"

# Change this if your prod domain differs:
URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }

need vercel || die "Vercel CLI not found (npm i -g vercel)."
need node   || die "Node not found."

# Confirm login
if ! vercel whoami >/dev/null 2>&1; then
  die "Not logged in in this shell. Run: vercel login"
fi

ROOT="$(pwd)"
mkdir -p "$ROOT/.cto_logs"
TS="$(date -u +%Y%m%d_%H%M%S)"
LINK_LOG="$ROOT/.cto_logs/vercel_link_${TS}.log"
DEPLOY_LOG="$ROOT/.cto_logs/vercel_remote_deploy_${TS}.log"
PROBE_LOG="$ROOT/.cto_logs/courses_prod_probe_${TS}.log"

echo "Switching scope to team: $TEAM"
vercel switch "$TEAM" >/dev/null

# Link inside web/ to the exact project
pushd "$APP_DIR" >/dev/null
echo "Linking to project: $PROJECT (team: $TEAM) …"
if ! vercel link --yes --scope "$TEAM" --project "$PROJECT" >"$LINK_LOG" 2>&1; then
  echo "Link failed. Log: $LINK_LOG"
  echo "If you have multiple teams or projects, run interactively: (cd $APP_DIR && vercel link)"
  exit 2
fi

# Sanity check: project.json exists and matches the project
if [ ! -f ".vercel/project.json" ]; then
  echo "Link did not produce .vercel/project.json — aborting."
  exit 2
fi
echo ".vercel/project.json:"
cat .vercel/project.json

# Best-effort: pull prod env (doesn't block)
vercel pull --yes --environment=production >/dev/null 2>&1 || true

# Remote build + deploy to PRODUCTION under the specified scope
echo "Deploying remotely to production… (log: $DEPLOY_LOG)"
if ! vercel deploy --prod --yes --scope "$TEAM" >"$DEPLOY_LOG" 2>&1; then
  echo "=== CTO VERCEL REMOTE DEPLOY SUMMARY START ==="
  echo "Result: FAIL"
  echo "Team: $TEAM"
  echo "Project: $PROJECT"
  echo "Deploy log: $DEPLOY_LOG"
  echo "Hint: If you see 'project not found' or 'forbidden', confirm you belong to the ai_tutor team and that project '$PROJECT' exists in that team."
  echo "=== CTO VERCEL REMOTE DEPLOY SUMMARY END ==="
  exit 2
fi
popd >/dev/null

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
  local limit="${PROBE_LIMIT:-40}"  # ~5 min at 8s intervals
  for i in $(seq 1 $limit); do
    if [ "$(probe_once "$path" "$needle")" = "yes" ]; then echo "$label: PASS"; return 0; fi
    sleep 8
  done
  echo "$label: FAIL (timeout)"; return 1
}

R1="$(wait_for "/courses" "Courses" "Prod /courses")" || true
R2="$(wait_for "/courses/getting-started" "Getting Started with the AI Tutor" "Prod /courses/getting-started")" || true

echo "=== CTO VERCEL REMOTE (SCOPED) SUMMARY START ==="
echo "Team: $TEAM"
echo "Project: $PROJECT"
[ -n "$DEPLOY_URL" ] && echo "Deployment URL: $DEPLOY_URL"
echo "Prod URL: $URL"
echo "Link log: $LINK_LOG"
echo "Deploy log: $DEPLOY_LOG"
echo "$R1"
echo "$R2"
echo "Probe log: $PROBE_LOG"
echo "=== CTO VERCEL REMOTE (SCOPED) SUMMARY END ==="
