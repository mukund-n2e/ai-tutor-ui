#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="tutorweb-cyan.vercel.app"

# Ensure we're linked
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null

# Try JSON listing to get the newest PRODUCTION deployment URL
latest_prod=""
if vercel list "$PROJECT" --scope "$TEAM" --json >/tmp/vls.json 2>/dev/null; then
  latest_prod=$(node -e "const a=require('/tmp/vls.json'); const p=a.find(x=>x.target==='production'||x.target==='PRODUCTION'); if(p) console.log('https://'+p.url)")
fi
# Fallback to `vercel ls`
if [ -z "$latest_prod" ] && vercel ls "$PROJECT" --scope "$TEAM" --json >/tmp/vls.json 2>/dev/null; then
  latest_prod=$(node -e "const a=require('/tmp/vls.json'); const p=a.find(x=>x.target==='production'||x.target==='PRODUCTION'); if(p) console.log('https://'+p.url)")
fi
# Grep fallback
if [ -z "$latest_prod" ]; then
  vercel list "$PROJECT" --scope "$TEAM" --prod >/tmp/vls.txt || vercel ls "$PROJECT" --scope "$TEAM" --prod >/tmp/vls.txt || true
  latest_prod=$(grep -Eo 'https://[a-z0-9-]+\.vercel\.app' /tmp/vls.txt | head -n1 || true)
fi

if [ -z "$latest_prod" ]; then echo "ERR_NO_PROD_URL"; exit 1; fi
echo "PROD=$latest_prod"

# Verify /api/flags on that prod
status=$(curl -s -o /tmp/flags.json -w "%{http_code}" "$latest_prod/api/flags?t=$(date +%s)")
echo "FLAGS_STATUS=$status"
head -c 300 /tmp/flags.json; echo
ok=1
[ "$status" = "200" ] || ok=0
grep -q '"beta"[[:space:]]*:[[:space:]]*true' /tmp/flags.json || ok=0
grep -q '"Understand"' /tmp/flags.json || ok=0
grep -q '"Draft"' /tmp/flags.json || ok=0
grep -q '"Polish"' /tmp/flags.json || ok=0
[ $ok -eq 1 ] || { echo "FLAGS_NOT_READY_ON_LATEST_PROD"; exit 1; }

# Repoint alias to that prod
vercel alias set "$latest_prod" "$ALIAS" --scope "$TEAM"
echo "ALIAS_UPDATED"
