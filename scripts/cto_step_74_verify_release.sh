#!/usr/bin/env bash
set -euo pipefail
BASE="https://tutorweb-cyan.vercel.app"

echo -n "ONBOARDING: "; curl -s -o /dev/null -w "%{http_code}\n" "$BASE/onboarding"
echo -n "SESSION:    "; curl -s -o /dev/null -w "%{http_code}\n" "$BASE/session?verb=Create&persona=Creator&minutes=20&task=hello"

echo -n "SSR_MARKER: "
curl -s "$BASE/session?verb=Create&persona=Creator&minutes=20&task=hello" \
| grep -E -o 'data-ssr-moves="[^"]+"' || echo "miss"

echo "SSE_HEAD:"
curl -N -sS -X POST -H 'Accept: text/event-stream' -H 'Content-Type: application/json' \
  --data '{"courseTitle":"Create — Creator","scope":"Probe","message":"Move 1 - Understand: Ask 3 crisp clarifying questions about: hello"}' \
  "$BASE/api/tutor/stream" | sed -n '1,6p'

echo "— export docx —"
HDRS=$(curl -sS -D - -o /dev/null -X POST "$BASE/api/export/docx" \
  -H 'Content-Type: application/json' \
  --data '{"title":"PRD Session","content":"Line 1\nLine 2"}' | tr -d '\r' | sed -n '1,10p')
echo "$HDRS"
curl -sS -o /tmp/test.docx -X POST "$BASE/api/export/docx" \
  -H 'Content-Type: application/json' \
  --data '{"title":"PRD Session","content":"Line 1\nLine 2"}'
HEX=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/test.docx 2>/dev/null || true)
echo "MAGIC_HEX: $HEX"

OK=1
[[ "$HEX" == "504b" ]] || OK=0
echo "$HDRS" | grep -qi 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' || OK=0
echo "$HDRS" | grep -qi 'Content-Disposition:' || OK=0

[[ $OK -eq 1 ]] && echo "RELEASE_OK" || { echo "RELEASE_NOT_OK"; exit 1; }
