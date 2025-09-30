#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"

# Run from the repo root (folder that contains /web)
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Ensure correct project + env, then trigger a remote build (no local npm)
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel pull --yes --environment=production --scope "$TEAM" >/dev/null

# Deploy to Prod and capture the full build log
vercel deploy --prod --scope "$TEAM" 2>&1 | tee .cto_last_remote_build.log

echo "=== BUILD ERROR TAIL (from 'Failed to compile' onward, else last 150 lines) ==="
awk 'p;/Failed to compile/{p=1} END{ if(!p) system("tail -n 150 .cto_last_remote_build.log") }' .cto_last_remote_build.log
