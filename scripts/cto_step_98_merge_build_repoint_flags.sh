#!/usr/bin/env bash
set -euo pipefail

PR="${1:-57}"
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS_HOST="tutorweb-cyan.vercel.app"
ALIAS_URL="https://${ALIAS_HOST}"

# 0) Merge PR (idempotent if already merged)
gh pr merge "$PR" --squash --delete-branch || echo "[merge] skipped (already merged?)"

# 1) Ensure Vercel project is linked
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null || true

# 2) Wait for newest *Ready* Production deployment to appear
echo "[wait] polling for newest Ready Production deploy…"
prod_url=""
for i in {1..20}; do
  # List only Production deployments (text table), newest first
  vercel list "$PROJECT" --scope "$TEAM" --prod >/tmp/vls.txt 2>/dev/null || true
  # Pick first row that has 'Ready' and extract the URL field
  prod_url="$(awk '/Ready/ && /vercel\.app/ {
    for(i=1;i<=NF;i++) if ($i ~ /^https:\/\/[a-z0-9-]+\.vercel\.app$/) { print $i; exit }
  }' /tmp/vls.txt | head -n1 || true)"
  if [ -n "$prod_url" ]; then
    echo "[wait] candidate PROD: $prod_url"
    break
  fi
  sleep 6
done
[ -n "$prod_url" ] || { echo "ERR_NO_READY_PROD"; exit 1; }

# 3) Verify /api/flags on that prod
echo "[check] $prod_url/api/flags"
status=$(curl -s -o /tmp/flags.json -w "%{http_code}" "$prod_url/api/flags?t=$(date +%s)")
ok=1
[ "$status" = "200" ] || ok=0
grep -q '"beta"[[:space:]]*:[[:space:]]*true' /tmp/flags.json || ok=0
grep -q '"Understand"' /tmp/flags.json || ok=0
grep -q '"Draft"' /tmp/flags.json || ok=0
grep -q '"Polish"' /tmp/flags.json || ok=0
if [ $ok -ne 1 ]; then
  echo "FLAGS_NOT_READY_ON_PROD"
  head -c 300 /tmp/flags.json; echo
  exit 1
fi
echo "[check] flags OK on $prod_url"

# 4) Repoint alias to that prod
echo "[alias] $ALIAS_HOST → $prod_url"
vercel alias set "$prod_url" "$ALIAS_HOST" --scope "$TEAM"

# 5) Final verify via alias
status_alias=$(curl -s -o /tmp/flags_alias.json -w "%{http_code}" "$ALIAS_URL/api/flags?t=$(date +%s)")
ok2=1
[ "$status_alias" = "200" ] || ok2=0
grep -q '"beta"[[:space:]]*:[[:space:]]*true' /tmp/flags_alias.json || ok2=0
grep -q '"Understand"' /tmp/flags_alias.json || ok2=0
grep -q '"Draft"' /tmp/flags_alias.json || ok2=0
grep -q '"Polish"' /tmp/flags_alias.json || ok2=0
[ $ok2 -eq 1 ] && echo "ALIAS_UPDATED" || { echo "ALIAS_NOT_UPDATED"; exit 1; }
