#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
SRC_ENV="./.cto_env_backups/tutor_web.env"
[ -f "$SRC_ENV" ] || { echo "Missing $SRC_ENV"; exit 2; }

# Likely keys used by the SSE upstream. Add more if needed.
KEYS=(
  OPENAI_API_KEY OPENAI_BASE_URL OPENAI_ORG_ID OPENAI_PROJECT
  ANTHROPIC_API_KEY GEMINI_API_KEY MISTRAL_API_KEY GROQ_API_KEY
  OPENROUTER_API_KEY TOGETHER_API_KEY DEEPSEEK_API_KEY XAI_API_KEY
  SESSION_TOKEN_CAP
)

getv(){ grep -E "^$1=" "$SRC_ENV" | head -n1 | sed 's/^[^=]*=//' || true; }

echo "Linking to $PROJECT …"
vercel link --project "$PROJECT" --yes >/dev/null

for k in "${KEYS[@]}"; do
  v="$(getv "$k")"
  [ -n "$v" ] || continue
  # Remove if exists (auto-confirm), then add fresh value from backup (stdin)
  yes | vercel env rm "$k" production --scope "$TEAM" >/dev/null 2>&1 || true
  printf "%s" "$v" | vercel env add "$k" production --scope "$TEAM" >/dev/null
  echo "set $k"
done

echo "Redeploying current prod with updated env…"
vercel redeploy https://tutorweb-cyan.vercel.app --prod --scope "$TEAM" >/dev/null
echo "synced-and-redeployed"
