#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="tutorweb-cyan.vercel.app"

# Always run within repo root
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

# Link to ensure correct project/team
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null || true

# Get list of Production deployments (newest first), filter those that appear "Ready"
vercel ls "$PROJECT" --scope "$TEAM" --prod > /tmp/vls.txt 2>/dev/null || true

CANDIDATES=$(awk '
  /vercel\.app/ {
    url=""; ready=0;
    for(i=1;i<=NF;i++) if ($i ~ /^https:\/\/[a-z0-9-]+\.vercel\.app$/) url=$i;
    if ($0 ~ /Ready/) ready=1;
    if (url != "" && ready==1) print url;
  }' /tmp/vls.txt)

pick_ok=""

for url in $CANDIDATES; do
  echo "[probe] $url"

  # 1) Onboarding page
  o=$(curl -s -o /dev/null -w "%{http_code}" "$url/onboarding")
  [ "$o" = "200" ] || { echo "  - onboarding $o"; continue; }

  # 2) Session page (with SSR moves marker ideally present)
  s_url="$url/session?verb=Create&persona=Creator&minutes=20&task=hello"
  s=$(curl -s -o /dev/null -w "%{http_code}" "$s_url")
  [ "$s" = "200" ] || { echo "  - session $s"; continue; }
  curl -s "$s_url" | grep -q 'data-ssr-moves=' || { echo "  - no SSR moves"; continue; }

  # 3) Export .docx endpoint (check magic ZIP header 0x504b)
  curl -sS -o /tmp/_t.docx -X POST "$url/api/export/docx" \
    -H 'Content-Type: application/json' \
    --data '{"title":"PRD Session","content":"Line 1\nLine 2"}' || true
  hex=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/_t.docx 2>/dev/null || true)
  [ "$hex" = "504b" ] || { echo "  - export/docx failed (hex:$hex)"; continue; }

  pick_ok="$url"
  break
done

if [ -z "$pick_ok" ]; then
  echo "ERR_NO_READY_RELEASE"
  echo "--- recent prod list (for reference) ---"
  sed -n '1,40p' /tmp/vls.txt
  exit 1
fi

echo "[alias] ${ALIAS} → ${pick_ok}"
vercel alias set "$pick_ok" "$ALIAS" --scope "$TEAM" >/dev/null
echo "RELEASE_POINTED"
