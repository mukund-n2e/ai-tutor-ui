#!/usr/bin/env bash
set -euo pipefail
BASE="https://tutorweb-cyan.vercel.app"

echo -n "ONBOARDING: "; curl -s -o /dev/null -w "%{http_code}\n" "$BASE/onboarding"
echo -n "ONBOARDING_BETA: "
curl -s "$BASE/onboarding" | grep -E -o 'data-ssr-beta="true"' || echo "miss"

SESSION_URL="$BASE/session?verb=Create&persona=Creator&minutes=20&task=hello"
echo -n "SESSION: "; curl -s -o /dev/null -w "%{http_code}\n" "$SESSION_URL"
echo -n "SESSION_BETA: "
curl -s "$SESSION_URL" | grep -E -o 'data-ssr-beta="true"' || echo "miss"
echo -n "SSR_MOVES: "
curl -s "$SESSION_URL" | grep -E -o 'data-ssr-moves="[^"]+"' || echo "miss"

if curl -s "$BASE/onboarding" | grep -q 'data-ssr-beta="true"' \
   && curl -s "$SESSION_URL" | grep -q 'data-ssr-beta="true"' \
   && curl -s "$SESSION_URL" | grep -q 'data-ssr-moves='; then
  echo "BETA_OK"
else
  echo "BETA_NOT_OK"; exit 1
fi
