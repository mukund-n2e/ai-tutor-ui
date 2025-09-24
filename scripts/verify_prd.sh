#!/usr/bin/env bash
set -euo pipefail

URL="${1:-}"
if [ -z "$URL" ]; then echo "Usage: $0 https://<deployment>.vercel.app"; exit 2; fi

ok() { echo "OK: $1"; }
fail() { echo "FAIL: $1"; exit 1; }

code() { curl -s -o /dev/null -w '%{http_code}' "$1"; }

[ "$(code "$URL/onboarding")" = "200" ] || fail "/onboarding !200"
ok "/onboarding 200"

[ "$(code "$URL/session?verb=Create&persona=Creator&minutes=20&task=hello")" = "200" ] || fail "/session !200"
ok "/session 200"

[ "$(code "$URL/screens")" = "200" ] || fail "/screens !200"
ok "/screens 200"

tmpdoc=$(mktemp)
curl -sS -o "$tmpdoc" -X POST "$URL/api/export/docx" -H 'Content-Type: application/json' --data '{"title":"PRD","content":"Probe"}' || true
MAG=$(hexdump -n 2 -e '2/1 "%02x"' "$tmpdoc" 2>/dev/null || true)
[ "$MAG" = "504b" ] || fail "/api/export/docx magic != 504b"
ok "/api/export/docx magic 504b"

FLAGS=$(curl -sS "$URL/api/flags" || true)
 echo "$FLAGS" | grep -q '"beta":true' || fail "/api/flags missing beta:true"
 echo "$FLAGS" | grep -q 'Understand' || fail "/api/flags missing moves"
ok "/api/flags beta:true + moves"

# SSE sample
curl -sN --max-time 6 "$URL/api/tutor/stream?message=hello&courseTitle=Test&scope=Test" -D /tmp/_hdr >/tmp/_sse 2>/dev/null || true
[ -s /tmp/_sse ] || fail "/api/tutor/stream no data"
ok "/api/tutor/stream emits data"
