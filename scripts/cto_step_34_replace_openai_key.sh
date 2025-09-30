#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="https://tutorweb-cyan.vercel.app"

read -r -s -p "Paste a working OPENAI_API_KEY: " KEY; echo
[ -n "$KEY" ] || { echo "No key entered"; exit 2; }

echo -n "Checking models… "
M=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $KEY" https://api.openai.com/v1/models || true)
echo "$M"

echo -n "Checking chat gpt-4o-mini… "
C=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  https://api.openai.com/v1/chat/completions \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"ping"}]}' || true)
echo "$C"

[ "$C" = "200" ] || { echo "Key is invalid/unauthorized (chat=$C). Use a different key."; exit 3; }

vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
yes | vercel env rm OPENAI_API_KEY production --scope "$TEAM" >/dev/null 2>&1 || true
printf "%s" "$KEY" | vercel env add OPENAI_API_KEY production --scope "$TEAM" >/dev/null
vercel redeploy "$ALIAS" --scope "$TEAM" >/dev/null
echo "openai-fixed"
