#!/usr/bin/env bash
set -euo pipefail
URL="${1:-https://tutorweb-cyan.vercel.app/api/tutor/stream}"

echo "Probing SSE at $URL"
status="$(curl -s -o /dev/null -w '%{http_code}' -H 'Accept: text/event-stream' "$URL" || true)"
if [ "$status" = "200" ]; then
  echo "GET 200; streaming first lines ↓"
  curl -N -sS -H 'Accept: text/event-stream' "$URL" | sed -n '1,20p'
  exit 0
fi

echo "GET returned $status; trying POST…"
curl -N -sS -X POST -H 'Accept: text/event-stream' -H 'Content-Type: application/json' \
  --data '{"q":"ping"}' "$URL" | sed -n '1,20p'
