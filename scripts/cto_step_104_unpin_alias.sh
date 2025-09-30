#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="tutorweb-cyan.vercel.app"

# Use orgId from .vercel/project.json if available
if [ -f .vercel/project.json ]; then
  TID="$(node -e "try{const j=require('./.vercel/project.json'); if(j&&j.orgId) console.log(j.orgId)}catch{}" 2>/dev/null || true)"
  if [ -n "$TID" ]; then TEAM="$TID"; fi
fi

# Ensure Vercel context
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null || true

# If there's a pinned alias record, remove it. Otherwise no-op.
if vercel alias ls --scope "$TEAM" | grep -q "$ALIAS"; then
  yes | vercel alias rm "$ALIAS" --scope "$TEAM" >/dev/null || true
  echo "ALIAS_UNPINNED"
else
  echo "ALIAS_ALREADY_UNPINNED"
fi

# Sanity: alias still serves the app + export works
AON=$(curl -s -o /dev/null -w "%{http_code}" "https://$ALIAS/onboarding")
ASE=$(curl -s -o /dev/null -w "%{http_code}" "https://$ALIAS/session?verb=Create&persona=Creator&minutes=20&task=hello")

curl -sS -o /tmp/_alias.docx -X POST "https://$ALIAS/api/export/docx" \
     -H 'Content-Type: application/json' \
     --data '{"title":"Probe","content":"Test"}' || true
AHEX=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/_alias.docx 2>/dev/null || echo "")

echo "ALIAS_ONBOARDING:$AON"
echo "ALIAS_SESSION:$ASE"
echo "ALIAS_DOCX_HEX:$AHEX"


