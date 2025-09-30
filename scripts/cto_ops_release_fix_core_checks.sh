#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="https://tutorweb-cyan.vercel.app"

# Pick newest Ready production URL
PROD=$(vercel ls "$PROJECT" --scope "$TEAM" --prod \
  | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g' \
  | awk '/Ready/ && /vercel.app/ { for(i=1;i<=NF;i++) if ($i ~ /^https:\/\/[a-z0-9-]+\.vercel\.app$/) { print $i; exit } }')
[ -n "${PROD:-}" ] || { echo "ERR: no Ready production found"; exit 2; }
echo "PROD: $PROD"

# Core checks
ON=$(curl -s -o /dev/null -w "%{http_code}" "$PROD/onboarding")
echo "ONBOARDING:$ON"
[ "$ON" = "200" ]

SE=$(curl -s -o /dev/null -w "%{http_code}" "$PROD/session?verb=Create&persona=Creator&minutes=20&task=hello")
echo "SESSION:$SE"
[ "$SE" = "200" ]

echo "SSE_HEAD:"
curl -N -sS -H 'Accept: text/event-stream' "$PROD/api/tutor/stream?courseTitle=Probe&scope=Probe&message=hello" | sed -n '1,3p' > /tmp/_sse_head.txt || true
sed -n '1,3p' /tmp/_sse_head.txt
grep -q '^data:' /tmp/_sse_head.txt

curl -sS -o /tmp/out.docx -X POST "$PROD/api/export/docx" -H 'Content-Type: application/json' --data '{"title":"PRD Session","content":"Line1"}'
MAGIC=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/out.docx)
[ "$MAGIC" = "504b" ] || { echo "DOCX bad magic ($MAGIC)"; exit 5; }

# Point alias and verify
vercel alias set "$PROD" tutorweb-cyan.vercel.app --scope "$TEAM"

AO=$(curl -s -o /dev/null -w "%{http_code}" "$ALIAS/onboarding")
AS=$(curl -s -o /dev/null -w "%{http_code}" "$ALIAS/session?verb=Create&persona=Creator&minutes=20&task=hello")
echo "ALIAS_ONBOARDING:$AO"
echo "ALIAS_SESSION:$AS"
[ "$AO" = "200" ] && [ "$AS" = "200" ]

echo "OK"


