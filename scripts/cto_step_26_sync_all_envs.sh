#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
SRC_ENV="./.cto_env_backups/tutor_web.env"

[ -f "$SRC_ENV" ] || { echo "Missing $SRC_ENV"; exit 2; }

echo "Linking $PROJECT in $TEAM..."
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null

echo "Syncing PRODUCTION envs from $SRC_ENV..."
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  line="${line#export }"
  if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
    key="${line%%=*}"; val="${line#*=}"
    yes | vercel env rm "$key" production --scope "$TEAM" >/dev/null 2>&1 || true
    printf "%s" "$val" | vercel env add "$key" production --scope "$TEAM" >/dev/null
    echo "set $key"
  fi
done < "$SRC_ENV"

echo "Redeploying alias target to pick up envs..."
vercel redeploy https://tutorweb-cyan.vercel.app --scope "$TEAM" >/dev/null
echo "envs-synced"
