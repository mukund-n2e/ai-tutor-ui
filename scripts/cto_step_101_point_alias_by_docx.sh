#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="tutorweb-cyan.vercel.app"

# Work from repo root
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

# Ensure correct Vercel project/team
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null || true

# Get newest Production deployments (table)
vercel ls "$PROJECT" --scope "$TEAM" --prod > /tmp/vls.txt 2>/dev/null || true

# Candidate URLs: newest "Ready" rows first
CANDIDATES=$(awk '
  /vercel\.app/ {
    url=""; ready=0;
    for (i=1;i<=NF;i++) if ($i ~ /^https:\/\/[a-z0-9-]+\.vercel\.app$/) url=$i;
    if ($0 ~ /Ready/) ready=1;
    if (url != "" && ready==1) print url;
  }' /tmp/vls.txt)

PICK=""
for URL in $CANDIDATES; do
  echo "[probe] $URL"

  # 1) Onboarding 200
  o=$(curl -s -o /dev/null -w "%{http_code}" "$URL/onboarding")
  [ "$o" = "200" ] || { echo "  - onboarding:$o (skip)"; continue; }

  # 2) Session 200
  SURL="$URL/session?verb=Create&persona=Creator&minutes=20&task=hello"
  s=$(curl -s -o /dev/null -w "%{http_code}" "$SURL")
  [ "$s" = "200" ] || { echo "  - session:$s (skip)"; continue; }

  # 3) DOCX export returns ZIP magic 0x504b
  curl -sS -o /tmp/_out.docx -X POST "$URL/api/export/docx" \
       -H 'Content-Type: application/json' \
       --data '{"title":"PRD Session","content":"Docx probe"}' || true
  hex=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/_out.docx 2>/dev/null || echo "")
  if [ "$hex" = "504b" ]; then
    echo "  - docx:OK ($hex)"
    PICK="$URL"; break
  else
    echo "  - docx:BAD (hex:$hex) -> skip"
  fi
done

[ -n "$PICK" ] || { echo "ERR_NO_DOCX_READY"; exit 1; }

echo "[alias] ${ALIAS} → ${PICK}"
vercel alias set "$PICK" "$ALIAS" --scope "$TEAM" >/dev/null

# Final verify via alias (onboarding, session, docx)
AON=$(curl -s -o /dev/null -w "%{http_code}" "https://${ALIAS}/onboarding")
ASE=$(curl -s -o /dev/null -w "%{http_code}" "https://${ALIAS}/session?verb=Create&persona=Creator&minutes=20&task=hello")
curl -sS -o /tmp/_alias.docx -X POST "https://${ALIAS}/api/export/docx" \
     -H 'Content-Type: application/json' \
     --data '{"title":"PRD Session","content":"Docx probe (alias)"}' || true
AHEX=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/_alias.docx 2>/dev/null || echo "")

echo "ALIAS_ONBOARDING:$AON"
echo "ALIAS_SESSION:$ASE"
echo "ALIAS_DOCX_HEX:$AHEX"

if [ "$AON" = "200" ] && [ "$ASE" = "200" ] && [ "$AHEX" = "504b" ]; then
  echo "RELEASE_POINTED"
else
  echo "ALIAS_NOT_READY"; exit 1
fi



