#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
ALIAS="https://tutorweb-cyan.vercel.app"
SSE="$ALIAS/api/tutor/stream"

echo "[1/3] Tailing logs briefly…"
vercel logs "$ALIAS" --scope "$TEAM" --follow | sed -u 's/^/[LOG] /' &
LOGPID=$!
sleep 1

echo "[2/3] Triggering SSE POST…"
curl -N -sS -X POST -H 'Accept: text/event-stream' -H 'Content-Type: application/json' \
  --data '{"courseTitle":"probe","scope":"probe","message":"hello"}' "$SSE" | sed -n '1,20p' || true

sleep 2
echo "[3/3] Stopping log tail and showing recent lines…"
kill "$LOGPID" >/dev/null 2>&1 || true
vercel logs "$ALIAS" --scope "$TEAM" | tail -n 80
