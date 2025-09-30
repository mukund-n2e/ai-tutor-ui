#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
SRC="./.cto_env_backups/tutor_web.env"
KEY="OPENAI_API_KEY"

# Ensure we’re operating on the right project/team
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null

# Pull value from backup
VAL="$(awk -F= -v k="$KEY" '$1==k{print substr($0,index($0,"=")+1); exit}' "$SRC" || true)"
if [ -z "${VAL:-}" ]; then
  echo "ERROR: $KEY not found in $SRC" >&2
  exit 2
fi

# Replace in PRODUCTION and redeploy the alias target
yes | vercel env rm "$KEY" production --scope "$TEAM" >/dev/null 2>&1 || true
printf "%s" "$VAL" | vercel env add "$KEY" production --scope "$TEAM" >/dev/null
vercel redeploy https://tutorweb-cyan.vercel.app --scope "$TEAM" >/dev/null
echo "openai-key-set"
