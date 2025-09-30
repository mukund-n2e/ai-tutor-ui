#!/usr/bin/env bash
set -euo pipefail
BASE="https://tutorweb-cyan.vercel.app"

echo "/ HEAD:"
curl -sI "$BASE" | sed -n '1p;/^location:/Ip'

echo -n "/onboarding: "
curl -s -o /dev/null -w "%{http_code}\n" "$BASE/onboarding"

# Pass if root redirects to /onboarding and /onboarding is 200
HEAD_OK=$(curl -sI "$BASE")
REDIR=$(printf "%s" "$HEAD_OK" | grep -i '^location: .*\/onboarding' || true)
ROOT_STATUS=$(printf "%s" "$HEAD_OK" | sed -n '1p')
ONB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/onboarding")

if [ -n "$REDIR" ] && printf "%s" "$ROOT_STATUS" | grep -q ' 30[1278] ' && [ "$ONB_STATUS" = "200" ]; then
  echo "OK"
else
  echo "NOT-OK"; exit 1
fi
