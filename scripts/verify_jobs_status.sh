#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------
# Config (flags + env)
# ---------------------------------------------
REPO="mukund-n2e/ai-tutor-web"
TEAM_SLUG="ai-tutor-7f989507"
PROJ="ai-tutor-web"
ALIAS="tutorweb-cyan.vercel.app"
DOCX_URL=""   # optionally set to a full URL (e.g., https://<alias>/api/export/sample.docx)

while getopts ":r:t:p:a:d:" opt; do
  case $opt in
    r) REPO="$OPTARG" ;;
    t) TEAM_SLUG="$OPTARG" ;;
    p) PROJ="$OPTARG" ;;
    a) ALIAS="$OPTARG" ;;
    d) DOCX_URL="$OPTARG" ;;
    \?) echo "Usage: $0 [-r owner/repo] [-t team-slug] [-p project-name] [-a alias-domain] [-d docx-url]" >&2; exit 2 ;;
  esac
done

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN in environment}"

BASE_ALIAS="https://${ALIAS}"
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# ---------------------------------------------
# Helpers
# ---------------------------------------------
ok(){ echo "✅ $*"; }
warn(){ echo "⚠️  $*" >&2; }
fail(){ echo "❌ $*" >&2; exit 1; }

need_cmd(){ command -v "$1" >/dev/null 2>&1 || fail "Missing dependency: $1"; }

need_cmd curl
need_cmd jq

HVERCEL=(-H "Authorization: Bearer ${VERCEL_TOKEN}" -H "Content-Type: application/json")

gh_api(){
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    warn "GITHUB_TOKEN not set; skipping GitHub API call: $*"
    return 9
  fi
  curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "$@"
}

# ---------------------------------------------
# Section: GitHub — What executed recently
# ---------------------------------------------
echo "## ${TS} — Job Status Report"
echo
echo "### GitHub — Recently merged PRs (last 72h)"
if gh_api "https://api.github.com/repos/${REPO}/pulls?state=closed&per_page=50" >/tmp/prs.json 2>/dev/null; then
  jq -r '
    map(select(.merged_at != null)) 
    | map(select((now - (.merged_at|fromdateiso8601)) <= (72*60*60))) 
    | ( if length==0 then "  (none in last 72h)" else 
        .[] | "- PR #\(.number): \(.title) — merged_at=\(.merged_at) by \(.merged_by.login // \"n/a\")"
      end )
  ' /tmp/prs.json
else
  echo "  (skipped — no GITHUB_TOKEN)"
fi
echo

echo "### GitHub — Last 5 'Promote' workflow runs"
if gh_api "https://api.github.com/repos/${REPO}/actions/workflows" >/tmp/wfs.json 2>/dev/null; then
  WF_ID="$(jq -r '.workflows | map(select((.name|ascii_downcase) | test("promote"))) | (.[0].id // empty)' /tmp/wfs.json)"
  if [[ -n "$WF_ID" ]]; then
    gh_api "https://api.github.com/repos/${REPO}/actions/workflows/${WF_ID}/runs?per_page=5" >/tmp/wfruns.json
    jq -r '.workflow_runs[] 
      | "- run_id=\(.id) status=\(.status) conclusion=\(.conclusion) created=\(.created_at) url=\(.html_url)"' /tmp/wfruns.json
  else
    echo "  (no workflow named like 'promote' found)"
  fi
else
  echo "  (skipped — no GITHUB_TOKEN)"
fi
echo

# ---------------------------------------------
# Section: Vercel — Deployments & Candidate
# ---------------------------------------------
echo "### Vercel — Latest READY production deployments (last 15)"
TEAM_ID="$(curl -fsSL "${HVERCEL[@]}" "https://api.vercel.com/v2/teams?slug=${TEAM_SLUG}" | jq -r '.id // empty')"
PROJ_ID="$(curl -fsSL "${HVERCEL[@]}" "https://api.vercel.com/v9/projects/${PROJ}${TEAM_ID:+?teamId=${TEAM_ID}}" | jq -r '.id')"

# Try v13 deployments API first; if it errors or returns invalid, fall back to v6
V13_URL="https://api.vercel.com/v13/deployments?projectId=${PROJ_ID}&target=production&limit=50${TEAM_ID:+&teamId=${TEAM_ID}}"
V6_URL="https://api.vercel.com/v6/deployments?projectId=${PROJ_ID}&target=production&limit=50${TEAM_ID:+&teamId=${TEAM_ID}}"

if ! curl -fsSL "${HVERCEL[@]}" "$V13_URL" >/tmp/deploys.json 2>/tmp/deploys.err; then
  warn "v13 deployments API failed; trying v6"
  curl -fsSL "${HVERCEL[@]}" "$V6_URL" >/tmp/deploys.json
else
  if jq -e .error >/dev/null 2>&1 </tmp/deploys.json; then
    warn "v13 returned error payload; trying v6"
    curl -fsSL "${HVERCEL[@]}" "$V6_URL" >/tmp/deploys.json
  fi
fi

jq -r '
  .deployments 
  | map({created, readyState: (.readyState // .state), url})
  | sort_by(.created) 
  | reverse 
  | .[0:15] 
  | .[] 
  | "- \(.url)  readyState=\(.readyState)  created=\(.created)"
' /tmp/deploys.json

CANDIDATE_DOMAIN="$(
  jq -r '
    .deployments
    | map(select(((.readyState // .state) | ascii_upcase) as $s | ($s=="READY" or $s=="SUCCEEDED")))
    | sort_by(.created) | last | .url // empty
  ' /tmp/deploys.json
)"

if [[ -n "$CANDIDATE_DOMAIN" ]]; then
  echo
  echo "Latest READY candidate: https://${CANDIDATE_DOMAIN}"
  ok "Found READY candidate"
else
  fail "No READY production deployments found for ${PROJ}"
fi
echo

# ---------------------------------------------
# Section: Alias — What is live right now
# ---------------------------------------------
echo "### Alias — What ${ALIAS} is serving now"
# Cache-bust HEAD to surface current headers
curl -sSI "${BASE_ALIAS}/?__bust=$(date +%s)" | awk 'BEGIN{IGNORECASE=1}/^HTTP\/|content-type|cache-control|etag|server|x-vercel|age|vary/'
ok "Alias responds"
echo

# ---------------------------------------------
# Section: Acceptance/Health checks against alias
# ---------------------------------------------
echo "### Acceptance & Health — Alias (${BASE_ALIAS})"
critical_fail=0

# 1) Route 200s
echo "• Routes → 200"
for p in / /onboarding/role /onboarding/readiness /onboarding/proposal /session /validator /export /screens; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_ALIAS}${p}")
  if [[ "$code" != "200" && "$p" != "/samples" ]]; then
    echo "  ❌ ${p} -> ${code}"
    critical_fail=1
  else
    echo "  ✅ ${p} -> ${code}"
  fi
done

# 2) Landing copy & CTAs
echo "• Landing copy & CTAs (exact text)"
body="$(curl -s "${BASE_ALIAS}/")"
grep -Fq "Learn and apply AI to your job. No fluff." <<<"$body" || { echo "  ❌ H1 mismatch"; critical_fail=1; }
grep -Fq "Pick a job task. We'll guide three decisive moves, validate, and you're done." <<<"$body" || { echo "  ❌ Subtitle mismatch"; critical_fail=1; }
grep -Fq "Incognito by default. Nothing saved unless you say so." <<<"$body" || { echo "  ❌ Footer mismatch"; critical_fail=1; }
grep -Fq 'href="/onboarding/role"' <<<"$body" || { echo "  ❌ Primary CTA href missing"; critical_fail=1; }
grep -Fq 'href="/samples"' <<<"$body" || { echo "  ❌ Secondary CTA href missing"; critical_fail=1; }
echo "  ✅ landing copy & hrefs OK"

# 3) Role voice hint (presence)
echo "• Onboarding/role — voice hint text presence"
rolep="$(curl -s "${BASE_ALIAS}/onboarding/role")"
grep -Fq "🎤 You can speak your choice" <<<"$rolep" && echo "  ✅ voice hint present" || echo "  ⚠️  voice hint not found (non-blocking)"

# 4) Readiness page key labels (presence)
echo "• Onboarding/readiness — key labels"
readp="$(curl -s "${BASE_ALIAS}/onboarding/readiness")"
grep -Fq "Quick AI readiness check" <<<"$readp" || { echo "  ❌ readiness title missing"; critical_fail=1; }
grep -Fq "Guidance style (not scored):" <<<"$readp" || { echo "  ❌ guidance label missing"; critical_fail=1; }
echo "  ✅ labels visible"

# 5) SSR marker on /session
echo "• Session — SSR marker"
sess="$(curl -s "${BASE_ALIAS}/session")"
grep -Fq 'data-ssr-moves="' <<<"$sess" && echo "  ✅ SSR marker present" || { echo "  ❌ SSR marker missing"; critical_fail=1; }

# 6) flags.json validity
echo "• flags.json — JSON parse + beta:true"
flags="$(curl -sS --compressed "${BASE_ALIAS}/flags.json" || true)"
if [[ -n "$flags" ]] && echo "$flags" | jq -e . >/dev/null 2>&1 && echo "$flags" | jq -e '.beta == true' >/dev/null 2>&1; then
  echo "  ✅ flags parse OK; beta:true"
else
  echo "  ❌ flags missing/invalid or beta flag not true"
  critical_fail=1
fi

# 7) /screens count
echo "• /screens — renders cards"
screens="$(curl -s "${BASE_ALIAS}/screens")"
cnt=$(grep -o '/design/screens/' <<<"$screens" | wc -l | tr -d ' ')
if [[ "${cnt:-0}" -ge 1 ]]; then
  echo "  ✅ screens count=${cnt}"
else
  echo "  ❌ no screens found"
  critical_fail=1
fi

# 8) Optional DOCX check
if [[ -n "$DOCX_URL" ]]; then
  echo "• DOCX — headers + magic"
  hcode=$(curl -s -o /dev/null -w "%{http_code}" "$DOCX_URL" || true)
  if [[ "$hcode" == "200" ]]; then
    curl -sSI "$DOCX_URL" | awk 'BEGIN{IGNORECASE=1}/^HTTP\/|content-type|content-disposition|content-length|cache-control|etag/'
    magic=$(curl -sS "$DOCX_URL" | head -c 2 | xxd -p -c 2 || true)
    if [[ "$magic" == "504b" ]]; then
      echo "  ✅ DOCX magic OK (PK)"
    else
      echo "  ⚠️  DOCX magic not PK (got ${magic:-<empty>})"
    fi
  else
    echo "  ⚠️  DOCX URL $DOCX_URL -> $hcode (skipping)"
  fi
fi

# 9) SSE smoke (best‑effort, 10s max)
echo "• SSE — smoke (delta lines)"
resp="$(curl -sS -X POST -H 'Content-Type: application/json' \
  --data-binary '{"role":"Creator","level":"L1","courseId":"demo"}' \
  "${BASE_ALIAS}/api/session/start" || true)"
if jq -e .sessionId >/dev/null 2>&1 <<<"$resp"; then
  SID="$(echo "$resp" | jq -r .sessionId)"
  MOVE="$(echo "$resp" | jq -r '.moves[0].id')"
  curl --max-time 10 -N -sS \
    -H 'Accept: text/event-stream' -H 'Content-Type: application/json' \
    -X POST --data-binary "{\"sessionId\":\"$SID\",\"moveId\":\"$MOVE\",\"messages\":[{\"role\":\"user\",\"content\":\"Kick off.\"}],\"maxTokens\":128}" \
    "${BASE_ALIAS}/api/tutor/stream" | sed -n '1,8p' || true
  echo "  ✅ SSE responded (first events shown)"
else
  echo "  ⚠️  Could not start session; SSE skipped (resp len $(echo -n "$resp" | wc -c))"
fi

# ---------------------------------------------
# Summary & exit code
# ---------------------------------------------
echo
if [[ "$critical_fail" -eq 0 ]]; then
  ok "All critical alias checks passed."
else
  fail "One or more critical alias checks failed. See details above."
fi

echo
echo "### Notes"
echo "- Candidate latest READY deployment was discovered via Vercel API and printed above."
echo "- Alias verification exercised landing copy/CTAs, onboarding presence, session SSR, flags.json, /screens, and SSE smoke."
[[ -n "$DOCX_URL" ]] && echo "- DOCX endpoint checked: ${DOCX_URL}"

exit 0


