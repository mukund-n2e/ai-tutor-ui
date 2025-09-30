#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS_HOST="tutorweb-cyan.vercel.app"
ALIAS_URL="https://${ALIAS_HOST}"

# Always run from the repo root's web dir (avoids path confusion)
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT/web"

# Ensure we're linked to the right project/team
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null || true

echo "[scan] polling Production deployments until one serves /api/flags …"
FOUND=""
TRIES=60
SLEEP=5

for i in $(seq 1 $TRIES); do
  # List prod deployments (table). Newest at the top.
  vercel ls "$PROJECT" --scope "$TEAM" --prod > /tmp/vls.txt 2>/dev/null || true

  # Extract candidate URLs from rows that are Ready OR Building (we'll test them)
  URLS=$(awk '/vercel\.app/ { 
      url=""; ready=0; build=0;
      for (i=1;i<=NF;i++) if ($i ~ /^https:\/\/[a-z0-9-]+\.vercel\.app$/) url=$i;
      if ($0 ~ /Ready/) ready=1; if ($0 ~ /Building|Queued/) build=1;
      if (url != "" && (ready==1 || build==1)) print url;
    }' /tmp/vls.txt | head -n 8)

  # Probe each candidate for /api/flags
  for url in $URLS; do
    STATUS=$(curl -s -o /tmp/flags.json -w "%{http_code}" "$url/api/flags?t=$(date +%s)")
    if [ "$STATUS" = "200" ] \
       && grep -q '"beta"[[:space:]]*:[[:space:]]*true' /tmp/flags.json \
       && grep -q '"Understand"' /tmp/flags.json \
       && grep -q '"Draft"' /tmp/flags.json \
       && grep -q '"Polish"' /tmp/flags.json; then
      echo "[hit] $url serves /api/flags ✓"
      FOUND="$url"
      break
    fi
  done

  [ -n "$FOUND" ] && break
  sleep "$SLEEP"
done

if [ -z "$FOUND" ]; then
  echo "ERR_NO_READY_FLAGS"
  echo "--- recent prod list ---"
  sed -n '1,40p' /tmp/vls.txt
  exit 1
fi

echo "[alias] $ALIAS_HOST → $FOUND"
vercel alias set "$FOUND" "$ALIAS_HOST" --scope "$TEAM" >/dev/null

# Final verify via alias
STATUS_ALIAS=$(curl -s -o /tmp/flags_alias.json -w "%{http_code}" "$ALIAS_URL/api/flags?t=$(date +%s)")
OK=1
[ "$STATUS_ALIAS" = "200" ] || OK=0
grep -q '"beta"[[:space:]]*:[[:space:]]*true' /tmp/flags_alias.json || OK=0
grep -q '"Understand"' /tmp/flags_alias.json || OK=0
grep -q '"Draft"' /tmp/flags_alias.json || OK=0
grep -q '"Polish"' /tmp/flags_alias.json || OK=0

[ $OK -eq 1 ] && echo "ALIAS_UPDATED" || { echo "ALIAS_NOT_UPDATED"; exit 1; }
