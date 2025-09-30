#!/usr/bin/env bash
set -euo pipefail
BASE="https://tutorweb-cyan.vercel.app"

STATUS=$(curl -s -o /tmp/flags.json -w "%{http_code}" "$BASE/api/flags")
echo "HTTP: $STATUS"
head -c 400 /tmp/flags.json; echo

OK=1
grep -q '"beta"[[:space:]]*:[[:space:]]*true' /tmp/flags.json || OK=0
grep -q '"moves"[[:space:]]*:' /tmp/flags.json || OK=0
grep -q '"Understand"' /tmp/flags.json || OK=0
grep -q '"Draft"' /tmp/flags.json || OK=0
grep -q '"Polish"' /tmp/flags.json || OK=0

if [ "$STATUS" = "200" ] && [ $OK -eq 1 ]; then
  echo "FLAGS_OK"
else
  echo "FLAGS_NOT_OK"; exit 1
fi
