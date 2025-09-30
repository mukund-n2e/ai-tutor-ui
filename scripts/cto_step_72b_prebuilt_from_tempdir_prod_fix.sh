#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="https://tutorweb-cyan.vercel.app"

# 1) From repo root, build PRODUCTION output
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel pull --yes --environment=production --scope "$TEAM" >/dev/null
vercel build --prod --scope "$TEAM"

# 2) Copy prebuilt into a clean temp dir under web/.vercel/output (project rootDir = 'web')
TD="$(mktemp -d -t vercel-prebuilt-XXXX)"
mkdir -p "$TD/web/.vercel/output"
cp -R .vercel/output/* "$TD/web/.vercel/output/"

# 3) Deploy the prebuilt (no git in TD)
(
  cd "$TD"
  vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
  vercel deploy --prebuilt --prod --scope "$TEAM"
)

# 4) Verify export endpoint on prod alias
echo "— headers —"
HDRS=$(curl -sS -D - -o /dev/null -X POST "$ALIAS/api/export/docx" \
  -H 'Content-Type: application/json' \
  --data '{"title":"PRD Session","content":"Line 1\nLine 2"}' | tr -d '\r' | sed -n '1,10p')
echo "$HDRS"

echo "— download —"
curl -sS -o /tmp/test.docx -X POST "$ALIAS/api/export/docx" \
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
