#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"

# Run from the repo root (the folder that contains /web)
[ -d web/src/app ] || { echo "Run from the repo root (has /web)"; exit 2; }

# Link + pull Production settings without prompts
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel pull --yes --environment=production --scope "$TEAM" >/dev/null

# Remote build on Vercel (avoids local npm) and ship to Production
vercel deploy --prod --scope "$TEAM"



