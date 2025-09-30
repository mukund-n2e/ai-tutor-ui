#!/usr/bin/env bash
set -euo pipefail
BASE="https://tutorweb-cyan.vercel.app"

# 1) Session page should be live
S=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/session?verb=Create&persona=Creator&minutes=20&task=hello")
echo "SESSION: $S"
ok=true; [ "$S" = "200" ] || ok=false

# 2) Page should show the Move 1 header
curl -s "$BASE/session?verb=Create&persona=Creator&minutes=20&task=hello" | head -n 200 | grep -E -q 'Move 1.*Understand' \
  && echo "HAS_MOVE1_HEADER: yes" || { echo "HAS_MOVE1_HEADER: no"; ok=false; }

# 3) Tutor SSE should stream (simulate Move 1 prompt)
echo "SSE_HEAD:"
curl -N -sS -X POST -H 'Accept: text/event-stream' -H 'Content-Type: application/json' \
  --data '{"courseTitle":"Create — Creator","scope":"Probe","message":"Move 1 - Understand: Ask 3 crisp clarifying questions and state 3 constraints about: hello"}' \
  "$BASE/api/tutor/stream" | sed -n '1,8p'

$ok && echo "OK" || { echo "NOT-OK"; exit 1; }



