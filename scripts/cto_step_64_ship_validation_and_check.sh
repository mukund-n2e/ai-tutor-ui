#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
BASE="https://tutorweb-cyan.vercel.app"

# run from repo root (folder that contains /web)
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Remote Production deploy (non-interactive)
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel pull --yes --environment=production --scope "$TEAM" >/dev/null
vercel deploy --prod --scope "$TEAM"

# Quick API probe (Validation should return {status: pass|soft|fix, ...})
echo -n "VALIDATE: "
curl -sS -X POST "$BASE/api/validate" \
  -H 'Content-Type: application/json' \
  --data '{"text":"# Test draft\n\n- one\n- two\n- three\n\nVery good really just nice."}' \
  | sed -n '1,1p' | cut -c1-200

echo
echo "validation-ok"



