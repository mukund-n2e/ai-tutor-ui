#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="https://tutorweb-cyan.vercel.app"

# 1) Build PRODUCTION at repo root (needs project settings)
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel pull --yes --environment=production --scope "$TEAM" >/dev/null
vercel build --prod --scope "$TEAM"

# 2) Copy prebuilt output into a clean temp, to BOTH locations:
#    - .vercel/output
#    - web/.vercel/output  (for projects with rootDirectory="web")
TD="$(mktemp -d -t vercel-prebuilt-XXXX)"
mkdir -p "$TD/.vercel/output" "$TD/web/.vercel/output"
cp -R .vercel/output/* "$TD/.vercel/output/"
cp -R .vercel/output/* "$TD/web/.vercel/output/"
echo "tmp=$TD"

# 3) Deploy from temp ROOT (no pull here; avoids path doubling). Both paths exist anyway.
(
  cd "$TD"
  vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
  vercel deploy --prebuilt --prod --scope "$TEAM"
)

# 4) Verify export endpoint on the prod alias (headers + PK magic)
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
