#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

need vercel || die "Vercel CLI not found (npm i -g vercel)."
need node   || die "Node required."

# Logged in?
if ! vercel whoami >/dev/null 2>&1; then
  die "Not logged in in this shell. Run: vercel login"
fi

# Linked?
PJ="$APP_DIR/.vercel/project.json"
[ -f "$PJ" ] || die "Not linked in $APP_DIR. Run: (cd web && vercel link) and choose the existing project."

# Read orgId/projectId from project.json
ORG_ID="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$PJ','utf8')).orgId||'')" 2>/dev/null || true)"
PROJ_ID="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$PJ','utf8')).projectId||'')" 2>/dev/null || true)"
[ -n "$ORG_ID" ] || die "Could not read orgId from $PJ"
[ -n "$PROJ_ID" ] || die "Could not read projectId from $PJ"

# Find team slug that matches ORG_ID
TEAMS_JSON="$(vercel teams ls --json 2>/dev/null || true)"
TEAM_SLUG="$(node -e "
try{
  const t = JSON.parse(process.argv[1]);
  for (const team of t) {
    if (team.id === '$ORG_ID' || team.id === 'team_$ORG_ID') { console.log(team.slug); process.exit(0); }
  }
  // Also try matching last 6 chars (some CLIs show trimmed ids)
  for (const team of t) {
    if (team.id && '$ORG_ID'.endsWith(team.id.slice(-6))) { console.log(team.slug); process.exit(0); }
  }
  process.exit(1);
} catch(e){ process.exit(1); }
" "$TEAMS_JSON" 2>/dev/null || true)"

if [ -z "$TEAM_SLUG" ]; then
  echo "Could not auto‑map orgId to a team slug."
  echo "Run this and re‑run the script: vercel teams ls  (copy the correct team slug)"
  echo "Then re‑run with: TEAM=<your-team-slug> bash cto_step_17r_vercel_scope_switch_deploy_probe.sh"
  exit 2
fi

echo "Using team scope: $TEAM_SLUG"
# Switch current CLI scope
vercel switch "$TEAM_SLUG" >/dev/null

ROOT="$(pwd)"
mkdir -p "$ROOT/.cto_logs"
TS="$(date -u +%Y%m%d_%H%M%S)"
DEPLOY_LOG="$ROOT/.cto_logs/vercel_remote_deploy_scoped_${TS}.log"
PROBE_LOG="$ROOT/.cto_logs/courses_prod_probe_${TS}.log"

# Deploy remotely under forced IDs and team scope
echo "Deploying to production (team: $TEAM_SLUG)… (log: $DEPLOY_LOG)"
(
  cd "$APP_DIR"
  VERCEL_ORG_ID="$ORG_ID" VERCEL_PROJECT_ID="$PROJ_ID" vercel deploy --prod --yes --scope "$TEAM_SLUG"
) >"$DEPLOY_LOG" 2>&1 || {
  echo "=== CTO VERCEL REMOTE (SCOPED) SUMMARY START ==="
  echo "Result: FAIL"
  echo "Team: $TEAM_SLUG"
  echo "Org: $ORG_ID"
  echo "Project: $PROJ_ID"
  echo "Deploy log: $DEPLOY_LOG"
  echo "Hint: If this still says 'project not found' or 'forbidden', the linked project in web/.vercel is not the one serving prod."
  echo "=== CTO VERCEL REMOTE (SCOPED) SUMMARY END ==="
  exit 2
}

# Try to capture the deployment URL
DEPLOY_URL="$(grep -Eo 'https?://[^ ]+\.vercel\.app' "$DEPLOY_LOG" | tail -n1 || true)"

# Probe production with cache‑busting
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
  local limit="${PROBE_LIMIT:-40}"  # ~5 min
  for i in $(seq 1 $limit); do
    if [ "$(probe_once "$path" "$needle")" = "yes" ]; then echo "$label: PASS"; return 0; fi
    sleep 8
  done
  echo "$label: FAIL (timeout)"; return 1
}

R1="$(wait_for "/courses" "Courses" "Prod /courses")" || true
R2="$(wait_for "/courses/getting-started" "Getting Started with the AI Tutor" "Prod /courses/getting-started")" || true

echo "=== CTO VERCEL REMOTE (SCOPED) SUMMARY START ==="
echo "Team: $TEAM_SLUG"
echo "Org: $ORG_ID"
echo "Project: $PROJ_ID"
[ -n "$DEPLOY_URL" ] && echo "Deployment URL: $DEPLOY_URL"
echo "Prod URL: $URL"
echo "Deploy log: $DEPLOY_LOG"
echo "$R1"
echo "$R2"
echo "Probe log: $PROBE_LOG"
echo "=== CTO VERCEL REMOTE (SCOPED) SUMMARY END ==="
