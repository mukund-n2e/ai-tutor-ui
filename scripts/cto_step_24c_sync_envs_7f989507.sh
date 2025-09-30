#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
SRC_ENV="./.cto_env_backups/tutor_web.env"
[ -f "$SRC_ENV" ] || { echo "Missing $SRC_ENV"; exit 2; }

echo "Linking to $PROJECT in $TEAM..."
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null

getv(){ grep -E "^$1=" "$SRC_ENV" | head -n1 | sed 's/^[^=]*=//' || true; }
setk(){
  local k="$1"; local v; v="$(getv "$k")"
  [ -n "$v" ] || return 0
  yes | vercel env rm "$k" production --scope "$TEAM" >/dev/null 2>&1 || true
  printf "%s" "$v" | vercel env add "$k" production --scope "$TEAM" >/dev/null
  echo "set $k"
}

for k in OPENAI_API_KEY OPENAI_BASE_URL OPENAI_ORG_ID OPENAI_PROJECT \
         ANTHROPIC_API_KEY GEMINI_API_KEY MISTRAL_API_KEY GROQ_API_KEY \
         OPENROUTER_API_KEY TOGETHER_API_KEY DEEPSEEK_API_KEY XAI_API_KEY \
         SESSION_TOKEN_CAP; do
  setk "$k"
done

echo "Redeploying alias target to pick up envs..."
vercel redeploy https://tutorweb-cyan.vercel.app --scope "$TEAM" >/dev/null || true
echo "synced-7f989507"
