#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROD="https://ai-tutor-5twb2rxne-ai-tutor-7f989507.vercel.app"
ALIAS="https://tutorweb-cyan.vercel.app"
echo "PROD=$PROD"
ON=$(curl -s -o /dev/null -w "%{http_code}" "$PROD/onboarding")
echo "ONBOARDING:$ON"
SE=$(curl -s -o /dev/null -w "%{http_code}" "$PROD/session?verb=Create&persona=Creator&minutes=20&task=hello")
echo "SESSION:$SE"
echo "SSE_HEAD:"
curl -N -sS -H "Accept: text/event-stream" "$PROD/api/tutor/stream?courseTitle=Probe&scope=Probe&message=hello" | sed -n "1,3p" > /tmp/_sse_head.txt || true
sed -n "1,3p" /tmp/_sse_head.txt
grep -q "^data:" /tmp/_sse_head.txt
curl -sS -o /tmp/out.docx -X POST "$PROD/api/export/docx" -H "Content-Type: application/json" --data "{\"title\":\"PRD Session\",\"content\":\"Line1\"}"
MAGIC=$(hexdump -n 2 -e "2/1 \"%02x\"" /tmp/out.docx)
echo "DOCX_MAGIC:$MAGIC"
[ "$MAGIC" = "504b" ]
vercel alias set "$PROD" tutorweb-cyan.vercel.app --scope "$TEAM" | sed -n "1,80p"
AO=$(curl -s -o /dev/null -w "%{http_code}" "$ALIAS/onboarding")
AS=$(curl -s -o /dev/null -w "%{http_code}" "$ALIAS/session?verb=Create&persona=Creator&minutes=20&task=hello")
echo "ALIAS_ONBOARDING:$AO"
echo "ALIAS_SESSION:$AS"
