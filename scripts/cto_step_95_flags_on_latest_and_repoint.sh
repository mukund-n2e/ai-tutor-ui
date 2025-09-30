#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
ALIAS="https://tutorweb-cyan.vercel.app"

# 1) Find the project's latest Production URL (not the alias)
INFO="$(vercel inspect "$ALIAS" --scope "$TEAM" 2>/dev/null || true)"
PROD="$(printf "%s\n" "$INFO" | sed -n 's/^Production:[[:space:]]*//p' | awk '{print $1}' | head -n1)"

if [ -z "${PROD:-}" ]; then
  echo "ERR: Could not resolve latest Production URL."
  echo "$INFO" | sed -n '1,40p'
  exit 1
fi

echo "Latest PROD = $PROD"

# 2) Test /api/flags on the latest prod
STATUS="$(curl -s -o /tmp/flags.json -w "%{http_code}" "$PROD/api/flags?t=$(date +%s)")"
echo "FLAGS_STATUS: $STATUS"
head -c 300 /tmp/flags.json; echo

OK=1
[ "$STATUS" = "200" ] || OK=0
grep -q '"beta"[[:space:]]*:[[:space:]]*true' /tmp/flags.json || OK=0
grep -q '"Understand"' /tmp/flags.json || OK=0
grep -q '"Draft"' /tmp/flags.json || OK=0
grep -q '"Polish"' /tmp/flags.json || OK=0

if [ $OK -eq 1 ]; then
  echo "Repointing alias to latest prod…"
  vercel alias set "$PROD" tutorweb-cyan.vercel.app --scope "$TEAM"
  echo "ALIAS_UPDATED"
else
  echo "FLAGS_NOT_READY_ON_LATEST_PROD"
  exit 1
fi
