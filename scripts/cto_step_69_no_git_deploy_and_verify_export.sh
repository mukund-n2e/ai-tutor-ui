#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
BASE="https://tutorweb-cyan.vercel.app"

# Run from repo root (folder that contains /web)
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Link + pull prod settings, then deploy WITHOUT Git association
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel pull --yes --environment=production --scope "$TEAM" >/dev/null
vercel deploy --prod --no-git --scope "$TEAM"

# Verify export endpoint quickly
echo "— checking /api/export/docx headers —"
HDRS=$(curl -sS -D - -o /dev/null -X POST "$BASE/api/export/docx" \
  -H 'Content-Type: application/json' \
  --data '{"title":"PRD Session","content":"Line 1\nLine 2"}' | tr -d '\r' | sed -n '1,10p')
echo "$HDRS"

echo "— downloading file —"
curl -sS -o /tmp/test.docx -X POST "$BASE/api/export/docx" \
  -H 'Content-Type: application/json' \
  --data '{"title":"PRD Session","content":"Line 1\nLine 2"}'

HEX=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/test.docx 2>/dev/null || true)
echo "MAGIC_HEX: $HEX"

if echo "$HDRS" | grep -qi 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' \
  && echo "$HDRS" | grep -qi 'Content-Disposition:' \
  && [ "$HEX" = "504b" ]; then
  echo "DOCX_OK"
else
  echo "DOCX_NOT_OK"; exit 1
fi
