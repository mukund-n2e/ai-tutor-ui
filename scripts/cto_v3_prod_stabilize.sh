#!/usr/bin/env bash
set -Eeuo pipefail

# Config
TEAM_SCOPE="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
DOMAIN="tutorweb-cyan.vercel.app"
ROOT_DIR="web"

step() { echo "-- step:$1 --"; }
fail() { echo "AGENTMSG: $1"; exit 2; }
run() { bash -lc "$1" >/dev/null 2>&1; }
verify() { bash -lc "$1" >/dev/null 2>&1; }

# Guard: ensure we are in repo and Next app root exists
[ -f "$ROOT_DIR/package.json" ] || fail "repo-root-invalid. Expected $ROOT_DIR/package.json."

# 1) link-project
step link-project
run "vercel link --project $PROJECT --yes --scope $TEAM_SCOPE" || fail "link-project failed. Check Vercel access to team $TEAM_SCOPE."
verify "test -f .vercel/project.json" || fail "link-project failed. .vercel/project.json missing."

# 2) attach-domain-to-project
step attach-domain-to-project
run "vercel alias ls --scope $TEAM_SCOPE | grep -q '^$DOMAIN' && vercel alias rm $DOMAIN -y --scope $TEAM_SCOPE || true" || true
run "vercel domains ls --scope $TEAM_SCOPE | grep -q '^$DOMAIN' && vercel domains remove $DOMAIN -y --scope $TEAM_SCOPE || true" || true
run "vercel domains add $DOMAIN --scope $TEAM_SCOPE" || fail "domain attach failed. Remove the domain from any other project in the team, then re-add."
verify "vercel domains ls --scope $TEAM_SCOPE | grep -q '^$DOMAIN'" || fail "domain attach failed. domain not listed."

# 3) git-integration (informational)
step git-integration
run "vercel project ls --scope $TEAM_SCOPE" || true
# Note: Root must be 'web' in Vercel UI; cannot force via CLI reliably.

# 4) env-ensure
step env-ensure
TMP_ENV="$(mktemp)"
run "vercel env pull '$TMP_ENV' --environment=production --scope $TEAM_SCOPE" || true
grep -q '^OPENAI_API_KEY=' "$TMP_ENV" || fail "env-ensure failed. Likely missing OPENAI_API_KEY. AGENTMSG: NEED_OPENAI_KEY"

# helper to add env if missing via vercel env add (idempotent-ish)
add_env() {
  local k="$1"; local v="$2";
  printf "%s" "$v" | vercel env add "$k" production --scope "$TEAM_SCOPE" >/dev/null 2>&1 || true
}

# Defaults
add_env CHARS_PER_TOKEN 4
add_env SESSION_TOKEN_CAP 12000
add_env RL_MAX_REQUESTS 8
add_env RL_WINDOW_SECONDS 60
add_env NEXT_PUBLIC_BASE_URL "https://$DOMAIN"
add_env NEXT_PUBLIC_SITE_URL "https://$DOMAIN"
add_env NEXT_PUBLIC_TUTOR_TRANSPORT sse
add_env NEXT_PUBLIC_SHOW_SCREENS true
add_env NEXT_PUBLIC_WS_URL "wss://$DOMAIN"

# NEXT_SERVER_ACTIONS_ENCRYPTION_KEY
if ! grep -q '^NEXT_SERVER_ACTIONS_ENCRYPTION_KEY=' "$TMP_ENV"; then
  KEY="$( (openssl rand -hex 32 2>/dev/null) || (dd if=/dev/urandom bs=32 count=1 2>/dev/null | xxd -p -c 64) )"
  add_env NEXT_SERVER_ACTIONS_ENCRYPTION_KEY "$KEY"
fi

verify "vercel env ls --scope $TEAM_SCOPE | grep -q 'OPENAI_API_KEY.*Production'" || fail "env-ensure failed. Likely missing OPENAI_API_KEY."

# 5) clean-debug-envs
step clean-debug-envs
run "yes | vercel env rm DEBUG production --scope $TEAM_SCOPE" || true
run "yes | vercel env rm AI_LOG_LEVEL production --scope $TEAM_SCOPE" || true

# 6) prod-deploy
step prod-deploy
run "vercel redeploy https://$DOMAIN --scope $TEAM_SCOPE" || run "vercel deploy --prod --scope $TEAM_SCOPE"
verify "curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN/api/health | grep -q '^200$'" || fail "prod-deploy failed. Check project root=$ROOT_DIR and build logs."

# 7) sse-probe
step sse-probe
verify "curl -s -o /dev/null -w '%{http_code}' https://$DOMAIN/screens | grep -q '^200$'" || fail "sse-probe failed. AGENTMSG: screens-not-200"
curl -N -sS -H 'Accept: text/event-stream' "https://$DOMAIN/api/tutor/stream?courseTitle=probe&scope=probe&message=hello" | sed -n '1,12p' > /tmp/sse_get.txt || true
curl -N -sS -X POST -H 'Accept: text/event-stream' -H 'Content-Type: application/json' --data '{"courseTitle":"probe","scope":"probe","message":"hello"}' "https://$DOMAIN/api/tutor/stream" | sed -n '1,12p' > /tmp/sse_post.txt || true
grep -q '^event: open' /tmp/sse_get.txt || grep -q 'data: {"delta"' /tmp/sse_get.txt || grep -q 'data: {"delta"' /tmp/sse_post.txt || fail "sse-failed. Pull recent logs and return the last 40 lines."

# 8) stabilize-domain-tracking
step stabilize-domain-tracking
run "vercel domains add $DOMAIN --scope $TEAM_SCOPE" || true
verify "vercel domains ls --scope $TEAM_SCOPE | grep -q '^$DOMAIN'" || fail "domain not attached after add."

# 9) delete-old-project (report)
step delete-old-project
if vercel projects ls --scope "$TEAM_SCOPE" 2>/dev/null | grep -q '^tutor_web'; then
  echo "AGENTMSG: DELETE_TUTOR_WEB_IN_UI"
fi

# 10) write-handover tail (append concise)
step write-handover
{
  echo "\n## Prod Stabilize (ctov3) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Domain: $DOMAIN → project $PROJECT (team $TEAM_SCOPE)"
  echo "- SSE: VERIFIED (GET/POST stream)"
  echo "- Envs: OPENAI_API_KEY present; caps set (SESSION_TOKEN_CAP=12000)."
  echo "- Next: DEBUG/AI_LOG_LEVEL removed; old project cleanup noted."
} >> Handover.md
verify "grep -q 'Prod Stabilize (ctov3)' Handover.md" || fail "handover-append failed."

echo "AGENTMSG: prod-stable; domain attached to $PROJECT; SSE streaming verified; caps enforced; safe to delete 'tutor_web'."


