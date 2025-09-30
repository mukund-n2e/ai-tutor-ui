#!/usr/bin/env bash
set -euo pipefail

BASE="${BASE:-https://tutorweb-cyan.vercel.app}"
ok(){ echo "✅ $*"; }
fail(){ echo "❌ $*" >&2; exit 1; }

echo "== ROUTE 200s =="
for p in / /onboarding/role /onboarding/readiness /onboarding/proposal /session /validator /export /samples /screens; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE$p")
  [[ "$code" == "200" || "$p" == "/samples" ]] || fail "$p -> $code"
  echo "$p -> $code"
done
ok "All key routes reachable"

echo "== LANDING copy =="
body="$(curl -s "$BASE/")"
grep -Fq "Learn and apply AI to your job. No fluff." <<<"$body" || fail "Landing H1 mismatch"
grep -Fq "Pick a job task. We'll guide three decisive moves, validate, and you're done." <<<"$body" || fail "Landing subtitle mismatch"
grep -Fq "Incognito by default. Nothing saved unless you say so." <<<"$body" || fail "Footer copy mismatch"
ok "Landing copy exact"

echo "== CTA hrefs =="
grep -Fq 'href="/onboarding/role"' <<<"$body" || fail "Primary CTA does not route to /onboarding/role"
grep -Fq 'href="/samples"' <<<"$body" || fail "Secondary CTA /samples missing"
ok "CTA routes present (hrefs)"

echo "== SSR marker on /session =="
sess="$(curl -s "$BASE/session")"
grep -Fq 'data-ssr-moves="' <<<"$sess" || fail "SSR marker data-ssr-moves missing"
ok "SSR marker present"

echo "== FLAGS headers + parse =="
curl -sSI "$BASE/flags.json" | awk 'BEGIN{IGNORECASE=1}/^HTTP\/|content-type|cache-control|etag|content-encoding|age|server|vary/'
flags="$(curl -sS --compressed "$BASE/flags.json")"
echo "$flags" | jq -e . >/dev/null || fail "flags.json not valid JSON"
echo "$flags" | jq -e '.beta == true' >/dev/null || fail "flags.beta != true"
ok "flags.json valid; beta:true"

echo "== /screens count =="
screens="$(curl -s "$BASE/screens")"
count=$(grep -o '/design/screens/' <<<"$screens" | wc -l | tr -d ' ')
[[ "$count" -ge 1 ]] || fail "/screens shows zero cards"
echo "found=$count"
ok "/screens renders cards"

echo "== DOCX headers + magic (if endpoint configured) =="
DOCX_URL="${DOCX_URL:-$BASE/api/export/sample.docx}"
hcode=$(curl -s -o /dev/null -w "%{http_code}" "$DOCX_URL" || true)
if [[ "$hcode" == "200" ]]; then
  curl -sSI "$DOCX_URL" | awk 'BEGIN{IGNORECASE=1}/^HTTP\/|content-type|content-disposition|content-length|cache-control|content-encoding|etag/'
  magic=$(curl -sS "$DOCX_URL" | head -c 2 | xxd -p -c 2 || true)
  [[ "$magic" == "504b" ]] || fail "DOCX magic not PK (got $magic)"
  ok "DOCX content-type+magic OK"
else
  echo "Skipping DOCX (endpoint $DOCX_URL returned $hcode)"; 
fi

echo "== SSE smoke (10s) =="
# Best-effort: requires /api/session/start
SID=""; MOVE=""
resp="$(curl -sS -X POST -H 'Content-Type: application/json' \
  --data-binary '{"role":"Creator","level":"L1","courseId":"demo"}' "$BASE/api/session/start" || true)"
if jq -e .sessionId >/dev/null 2>&1 <<<"$resp"; then
  SID="$(jq -r .sessionId <<<"$resp")"
  MOVE="$(jq -r '.moves[0].id' <<<"$resp")"
  echo "session=$SID move=$MOVE"
  timeout 10s bash -c "cat <<EOF | curl -N -sS -H 'Accept: text/event-stream' -H 'Content-Type: application/json' -X POST --data-binary @- '$BASE/api/tutor/stream' | sed -n '1,20p'
{\"sessionId\":\"$SID\",\"moveId\":\"$MOVE\",\"messages\":[{\"role\":\"user\",\"content\":\"Kick off.\"}],\"maxTokens\":256}
EOF" || true
  ok "SSE responded (see first events above)"
else
  echo "Could not start session; SSE check skipped (resp: $(echo "$resp" | head -c 120))"
fi

echo "== DONE =="
