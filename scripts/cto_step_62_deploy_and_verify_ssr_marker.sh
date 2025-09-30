#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
BASE="https://tutorweb-cyan.vercel.app"

# Always run from repo root (the folder that contains /web)
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Remote Production deploy (non-interactive)
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel pull --yes --environment=production --scope "$TEAM" >/dev/null
vercel deploy --prod --scope "$TEAM"

# Verify: page exists, SSR marker present, SSE still streams
echo -n "SESSION: "
curl -s -o /dev/null -w "%{http_code}\n" "$BASE/session?verb=Create&persona=Creator&minutes=20&task=hello"

echo -n "SSR_MARKER: "
curl -s "$BASE/session?verb=Create&persona=Creator&minutes=20&task=hello" \
| grep -E -o 'data-ssr-moves="[^"]+"' || echo "miss"

echo "SSE_HEAD:"
curl -N -sS -H 'Accept: text/event-stream' \
  "$BASE/api/tutor/stream?courseTitle=Create%20%E2%80%94%20Creator&scope=Probe&message=hello" \
| sed -n '1,6p'



