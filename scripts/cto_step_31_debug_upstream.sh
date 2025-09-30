#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
ALIAS="https://tutorweb-cyan.vercel.app"

# 1) Turn on debug logging for the Vercel AI SDK (and friends)
vercel link --project ai-tutor-web --yes --scope "$TEAM" >/dev/null
yes | vercel env rm DEBUG production --scope "$TEAM" >/dev/null 2>&1 || true
printf "%s" "ai:*" | vercel env add DEBUG production --scope "$TEAM" >/dev/null
yes | vercel env rm AI_LOG_LEVEL production --scope "$TEAM" >/dev/null 2>&1 || true
printf "%s" "debug" | vercel env add AI_LOG_LEVEL production --scope "$TEAM" >/dev/null

# 2) Redeploy the alias target to pick up envs
vercel redeploy "$ALIAS" --scope "$TEAM" >/dev/null

# 3) Trigger the SSE endpoint (POST)
curl -N -sS -X POST -H 'Accept: text/event-stream' -H 'Content-Type: application/json' \
  --data '{"courseTitle":"probe","scope":"probe","message":"hello"}' \
  "$ALIAS/api/tutor/stream" | sed -n '1,10p' || true

# 4) Show the most recent runtime logs
echo
echo "=== RECENT LOGS (tail) ==="
vercel logs "$ALIAS" --scope "$TEAM" | tail -n 120
