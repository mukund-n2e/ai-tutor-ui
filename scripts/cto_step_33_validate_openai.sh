#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT

vercel env pull "$TMP" --environment=production --scope "$TEAM" >/dev/null
OPENAI="$(awk -F= '$1=="OPENAI_API_KEY"{print substr($0,index($0,"=")+1)}' "$TMP")"
[ -n "$OPENAI" ] || { echo "OPENAI_API_KEY is empty in prod"; exit 2; }

printf "models:           "
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $OPENAI" https://api.openai.com/v1/models

printf "chat gpt-4o-mini: "
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $OPENAI" -H "Content-Type: application/json" \
  https://api.openai.com/v1/chat/completions \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"ping"}]}'
