#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="https://tutorweb-cyan.vercel.app"

read -r -s -p "Paste a WORKING OPENAI_API_KEY: " KEY; echo
# Trim any stray CR/LF
KEY="$(printf '%s' "$KEY" | tr -d '\r\n')"
[ -n "$KEY" ] || { echo "No key entered"; exit 2; }

echo -n "Validating key against OpenAI… "
CHAT=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  https://api.openai.com/v1/chat/completions \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"ping"}]}' || true)
echo "$CHAT"
[ "$CHAT" = "200" ] || { echo "Key not valid (chat=$CHAT). Use a different key."; exit 3; }

echo "Setting OPENAI_API_KEY in PRODUCTION and redeploying…"
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
yes | vercel env rm OPENAI_API_KEY production --scope "$TEAM" >/dev/null 2>&1 || true
printf "%s" "$KEY" | vercel env add OPENAI_API_KEY production --scope "$TEAM" >/dev/null
vercel redeploy "$ALIAS" --scope "$TEAM" >/dev/null

echo "Probing SSE…"
curl -N -sS -H 'Accept: text/event-stream' \
  "$ALIAS/api/tutor/stream?courseTitle=probe&scope=probe&message=hello" | sed -n '1,30p'
