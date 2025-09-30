#!/usr/bin/env bash
set -euo pipefail
BASE="https://tutorweb-cyan.vercel.app"

# Root should redirect to Onboarding
curl -sI "$BASE" | sed -n '1p;/^location:/Ip' | sed -n '1,2p'

# Onboarding: page + beta badge
echo -n "ONBOARDING: "; curl -s -o /dev/null -w "%{http_code}\n" "$BASE/onboarding"
echo -n "BETA_ONBOARDING: "
curl -s "$BASE/onboarding" | grep -E -o 'data-ssr-beta="true"' || echo "miss"

# Session: page + 3-move marker + beta badge
SESSION_URL="$BASE/session?verb=Create&persona=Creator&minutes=20&task=hello"
echo -n "SESSION: "; curl -s -o /dev/null -w "%{http_code}\n" "$SESSION_URL"
echo -n "SSR_MOVES: "
curl -s "$SESSION_URL" | grep -E -o 'data-ssr-moves="[^"]+"' || echo "miss"
echo -n "BETA_SESSION: "
curl -s "$SESSION_URL" | grep -E -o 'data-ssr-beta="true"' || echo "miss"

# SSE head check (Move 1 prompt)
echo "SSE_HEAD:"
curl -N -sS -X POST -H 'Accept: text/event-stream' -H 'Content-Type: application/json' \
  --data '{"courseTitle":"Create — Creator","scope":"Probe","message":"hello"}' \
  "$BASE/api/tutor/stream" | sed -n '1,6p'

# Export .docx headers + magic bytes
HDRS=$(curl -sS -D - -o /dev/null -X POST "$BASE/api/export/docx" \
  -H 'Content-Type: application/json' \
  --data '{"title":"PRD Session","content":"Line 1\nLine 2"}' | tr -d '\r' | sed -n '1,10p')
echo "$HDRS" | sed -n '1,6p'
curl -sS -o /tmp/test.docx -X POST "$BASE/api/export/docx" \
  -H 'Content-Type: application/json' \
  --data '{"title":"PRD Session","content":"Line 1\nLine 2"}'
HEX=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/test.docx 2>/dev/null || true)
echo "MAGIC_HEX: $HEX"

OK=1
echo "$HDRS" | grep -qi 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' || OK=0
echo "$HDRS" | grep -qi 'Content-Disposition:' || OK=0
curl -s "$BASE/onboarding" | grep -q 'data-ssr-beta="true"' || OK=0
curl -s "$SESSION_URL" | grep -q 'data-ssr-beta="true"' || OK=0
curl -s "$SESSION_URL" | grep -q 'data-ssr-moves="' || OK=0
[[ "$HEX" == "504b" ]] || OK=0

if [[ $OK -eq 1 ]]; then echo "BETA_OK"; else echo "BETA_NOT_OK"; exit 1; fi
