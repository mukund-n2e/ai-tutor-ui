#!/usr/bin/env bash
set -euo pipefail
BASE="https://tutorweb-cyan.vercel.app"

ONB=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/onboarding")
SES=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/session?verb=Create&persona=Creator&minutes=20&task=hello")

SSE=$(curl -N -sS -H 'Accept: text/event-stream' \
  "$BASE/api/tutor/stream?courseTitle=Create%20%E2%80%94%20Creator&scope=Probe&message=hello" \
  | sed -n '1,12p')

echo "ONBOARDING: $ONB"
echo "SESSION_PAGE: $SES"
echo "SSE_HEAD:"
echo "$SSE"

if [ "$ONB" = "200" ] && [ "$SES" = "200" ] && grep -E -q '^data: |"delta"|^\[DONE\]' <<<"$SSE"; then
  echo "OK"
else
  echo "NOT-OK"; exit 1
fi
