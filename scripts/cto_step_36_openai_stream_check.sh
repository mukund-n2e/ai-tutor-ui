#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT

# Pull prod env to get the key in use
vercel env pull "$TMP" --environment=production --scope "$TEAM" >/dev/null
KEY="$(awk -F= '$1=="OPENAI_API_KEY"{print substr($0,index($0,"=")+1)}' "$TMP")"
[ -n "${KEY:-}" ] || { echo "OPENAI_API_KEY missing in prod"; exit 2; }

# Make the exact streaming call our SSE route makes
curl -N -sS \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  https://api.openai.com/v1/chat/completions \
  -d '{
    "model":"gpt-4o-mini",
    "stream": true,
    "temperature": 0.3,
    "messages": [
      {"role":"system","content":"You are a tiny probe."},
      {"role":"user","content":"say hello in 3 words"}
    ]
  }' | sed -n '1,30p'
