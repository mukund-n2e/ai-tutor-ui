#!/usr/bin/env bash
set -euo pipefail
BASE="https://tutorweb-cyan.vercel.app"
TRIES=12

for i in $(seq 1 $TRIES); do
  TS=$(date +%s)
  STATUS=$(curl -s -o /tmp/flags.json -w "%{http_code}" "$BASE/api/flags?t=$TS")
  if [ "$STATUS" = "200" ] \
     && grep -q '"beta"[[:space:]]*:[[:space:]]*true' /tmp/flags.json \
     && grep -q '"Understand"' /tmp/flags.json \
     && grep -q '"Draft"' /tmp/flags.json \
     && grep -q '"Polish"' /tmp/flags.json; then
    echo "HTTP: $STATUS"
    head -c 400 /tmp/flags.json; echo
    echo "FLAGS_OK"; exit 0
  fi
  sleep 3
done

echo "HTTP: ${STATUS:-unknown}"
head -c 400 /tmp/flags.json 2>/dev/null || true; echo
echo "FLAGS_NOT_OK"; exit 1
