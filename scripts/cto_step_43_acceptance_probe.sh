#!/usr/bin/env bash
set -euo pipefail
BASE="https://tutorweb-cyan.vercel.app"

code() { curl -s -o /dev/null -w '%{http_code}' "$1"; }

S1=$(code "$BASE/screens")
H=$(curl -s "$BASE/api/health")
SSE=$(curl -N -sS -H 'Accept: text/event-stream' \
  "$BASE/api/tutor/stream?courseTitle=probe&scope=probe&message=hello" | sed -n '1,10p')

echo "SCREENS: $S1"
echo "HEALTH:  $H"
echo "SSE head:"
echo "$SSE"

ok=true
[[ "$S1" == "200" ]] || ok=false
grep -q '"ok":true' <<<"$H" || ok=false
grep -E -q '^data: |"delta"|^\[DONE\]' <<<"$SSE" || ok=false

$ok && echo "ACCEPTED" || { echo "NOT-ACCEPTED"; exit 1; }
