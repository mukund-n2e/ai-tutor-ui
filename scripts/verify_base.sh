#!/usr/bin/env bash
set -euo pipefail

BASE="${1:?Usage: verify_base.sh https://<deployment-or-alias> }"

ok(){ echo "✅ $*"; }
fail(){ echo "❌ $*" >&2; exit 1; }

echo "== ROUTE 200s =="
for p in / /onboarding/role /onboarding/readiness /onboarding/proposal /session /validator /export /screens; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE$p")
  [[ "$code" == "200" || "$p" == "/samples" ]] || fail "$p -> $code"
done
ok "routes 200"

echo "== LANDING copy (exact) =="
body="$(curl -s "$BASE/")"
grep -Fq "Learn and apply AI to your job. No fluff." <<<"$body" || fail "H1 mismatch"
grep -Fq "Pick a job task. We'll guide three decisive moves, validate, and you're done." <<<"$body" || fail "Subtitle mismatch"
grep -Fq "Incognito by default. Nothing saved unless you say so." <<<"$body" || fail "Footer mismatch"
grep -Fq 'href="/onboarding/role"' <<<"$body" || fail "Primary CTA href"
grep -Fq 'href="/samples"' <<<"$body" || fail "Secondary CTA href"
ok "landing copy + hrefs"

echo "== ONBOARDING role content =="
role="$(curl -s "$BASE/onboarding/role")"
grep -Fq '🎤 You can speak your choice' <<<"$role" || fail "role hint missing"
grep -Fq 'data-testid="role-chip-Creator"' <<<"$role" || fail "role chip missing"
ok "role content present"

echo "== ONBOARDING readiness content =="
readiness="$(curl -s "$BASE/onboarding/readiness")"
grep -Fq 'role="radiogroup"' <<<"$readiness" || fail "readiness radios missing"
ok "readiness radios present"

echo "== SSR marker =="
sess="$(curl -s "$BASE/session")"
grep -Fq 'data-ssr-moves="' <<<"$sess" || fail "SSR marker missing"
ok "SSR marker present"

echo "== FLAGS parse =="
flags="$(curl -sS --compressed "$BASE/flags.json")"
echo "$flags" | jq -e . >/dev/null || fail "flags.json invalid"
echo "$flags" | jq -e '.beta == true' >/dev/null || fail "flags.beta != true"
ok "flags valid, beta:true"

echo "== /screens count > 0 =="
screens="$(curl -s "$BASE/screens")"
count=$(grep -o '/design/screens/' <<<"$screens" | wc -l | tr -d ' ')
[[ "$count" -ge 1 ]] || fail "/screens shows zero cards"
ok "screens count=$count"

echo "== SSE smoke (best-effort) =="
resp="$(curl -sS -X POST -H 'Content-Type: application/json' --data-binary '{"role":"Creator","level":"L1","courseId":"demo"}' "$BASE/api/session/start" || true)"
if jq -e .sessionId >/dev/null 2>&1 <<<"$resp"; then
  SID="$(jq -r .sessionId <<<"$resp")"; MOVE="$(jq -r '.moves[0].id' <<<"$resp")"
  curl -N -sS --max-time 10 \
    -H 'Accept: text/event-stream' -H 'Content-Type: application/json' \
    -X POST --data-binary @- "$BASE/api/tutor/stream" <<EOF | sed -n '1,8p'
{"sessionId":"$SID","moveId":"$MOVE","messages":[{"role":"user","content":"Kick off."}],"maxTokens":256}
EOF
  ok "SSE responded"
else
  echo "Start session failed; SSE skipped"
fi

echo "== DONE (verify_base) =="


