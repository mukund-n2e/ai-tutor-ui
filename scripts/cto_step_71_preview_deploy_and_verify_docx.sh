#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"

# Run from repo root (folder that contains /web)
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# 1) Link + pull PREVIEW settings (non-interactive)
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel pull --yes --environment=preview --scope "$TEAM" >/dev/null

# 2) Build (preview target) and deploy prebuilt (preview)
vercel build --scope "$TEAM"
URL=$(vercel deploy --prebuilt --scope "$TEAM" | grep -Eo 'https://[^ ]+\.vercel\.app' | tail -n1)
echo "preview=$URL"

# 3) Verify /api/export/docx on the preview URL: headers + magic bytes (PK)
echo "— headers —"
HDRS=$(curl -sS -D - -o /dev/null -X POST "$URL/api/export/docx" \
  -H 'Content-Type: application/json' \
  --data '{"title":"PRD Session","content":"Line 1\nLine 2"}' | tr -d '\r' | sed -n '1,10p')
echo "$HDRS"

echo "— download —"
curl -sS -o /tmp/test.docx -X POST "$URL/api/export/docx" \
  -H 'Content-Type: application/json' \
  --data '{"title":"PRD Session","content":"Line 1\nLine 2"}'

HEX=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/test.docx 2>/dev/null || true)
echo "MAGIC_HEX: $HEX"

if echo "$HDRS" | grep -qi 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' \
  && echo "$HDRS" | grep -qi 'Content-Disposition:' \
  && [ "$HEX" = "504b" ]; then
  echo "DOCX_OK preview=$URL"
else
  echo "DOCX_NOT_OK preview=$URL"; exit 1
fi
