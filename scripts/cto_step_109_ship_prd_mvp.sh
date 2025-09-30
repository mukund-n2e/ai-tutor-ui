#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS_HOST="tutorweb-cyan.vercel.app"
BRANCH_PREFIX="wp040-screens-brand-courses-ship"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

# Token for vercel CLI (env or ~/.vercel_token)
TOKEN="${VERCEL_TOKEN:-}"
if [ -z "$TOKEN" ] && [ -f "$HOME/.vercel_token" ]; then TOKEN="$(cat "$HOME/.vercel_token" 2>/dev/null || true)"; fi
TOK_ARG=""; [ -n "$TOKEN" ] && TOK_ARG="--token $TOKEN"

echo "[0] Prechecks"
git status --porcelain | sed -n '1,120p' || true
node -v && npm -v | cat || true
gh --version | cat || true
vercel --version | cat || true

# Ensure link context
vercel link --project "$PROJECT" --yes --scope "$TEAM" $TOK_ARG >/dev/null || true

echo "[1] Create branch and PR"
BR=$(printf "%s-%s" "$BRANCH_PREFIX" "$(date -u +%Y%m%d_%H%M%S)")
git checkout -B "$BR" >/dev/null
git add -A || true
git commit -m "feat(ui): ship screens registry + brand + two courses + PRD verifier" >/dev/null || true
git push -u origin "$BR" >/dev/null
gh pr create --fill --base main --head "$BR"
gh pr merge --squash --delete-branch

echo "[2] Wait for Ready Production deployments and probe"
scan_ready() {
  local out="/tmp/vls.json"
  vercel list "$PROJECT" --scope "$TEAM" --prod --json $TOK_ARG >"$out" 2>/dev/null || return 1
  node -e "const fs=require('fs');try{const a=JSON.parse(fs.readFileSync('$out','utf8'));const r=(Array.isArray(a)?a:[]).filter(x=>(x.target||'').toLowerCase()==='production'&&(x.state||'').toLowerCase()==='ready').sort((p,q)=>new Date(q.createdAt||q.created)-new Date(p.createdAt||p.created));r.slice(0,12).forEach(x=>console.log('https://'+x.url));}catch(e){}" | sed -n '1,200p'
}

probe_candidate() {
  local URL="$1"
  echo "  - probe $URL"
  local ONB=$(curl -s -o /dev/null -w '%{http_code}' "$URL/onboarding")
  [ "$ONB" = "200" ] || { echo "    onboarding !200"; return 1; }
  local SES=$(curl -s -o /dev/null -w '%{http_code}' "$URL/session?verb=Create&persona=Creator&minutes=20&task=hello")
  [ "$SES" = "200" ] || { echo "    session !200"; return 1; }
  local SCR=$(curl -s -o /dev/null -w '%{http_code}' "$URL/screens")
  [ "$SCR" = "200" ] || { echo "    screens !200"; return 1; }
  local FLG=$(curl -sS "$URL/api/flags" || true)
  echo "$FLG" | grep -q '"beta":true' || { echo "    flags missing beta:true"; return 1; }
  echo "$FLG" | grep -q 'Understand' || { echo "    flags missing moves"; return 1; }
  curl -sN --max-time 6 -H 'Accept: text/event-stream' "$URL/api/tutor/stream?courseTitle=Probe&scope=Probe&message=hello" >/tmp/_sse 2>/dev/null || true
  [ -s /tmp/_sse ] || { echo "    sse no data"; return 1; }
  curl -sS -o /tmp/_out.docx -X POST "$URL/api/export/docx" -H 'Content-Type: application/json' --data '{"title":"PRD Session","content":"Docx probe"}' || true
  local HEX=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/_out.docx 2>/dev/null || true)
  [ "$HEX" = "504b" ] || { echo "    docx BAD (hex:$HEX)"; return 1; }
  echo "    OK (flags+SSE+DOCX)"
  echo "$URL" > /tmp/PICK_READY
  return 0
}

pick_ready() {
  local urls=$(scan_ready || true)
  [ -n "$urls" ] || return 1
  for u in $urls; do
    probe_candidate "$u" && return 0
  done
  return 1
}

if ! pick_ready; then
  echo "[2b] No passing Ready yet; trigger a new deploy and retry"
  touch "web/public/_deploy-$(date -u +%Y%m%d_%H%M%S).txt"
  RBR="wp041-trigger-docx-$(date -u +%Y%m%d_%H%M%S)"
  git checkout -B "$RBR" >/dev/null
  git add web/public/_deploy-* && git commit -m "chore(deploy): trigger prod for DOCX" >/dev/null || true
  git push -u origin "$RBR" >/dev/null
  gh pr create --fill --base main --head "$RBR"
  gh pr merge --squash --delete-branch
  for i in $(seq 1 40); do
    if pick_ready; then break; fi
    sleep 15
  done
fi

[ -s /tmp/PICK_READY ] || { echo "ERR_NO_READY_PASS"; exit 1; }
PICK=$(cat /tmp/PICK_READY)
echo "[3] Point alias $ALIAS_HOST → $PICK"
if ! vercel alias set "$PICK" "$ALIAS_HOST" --scope "$TEAM" $TOK_ARG >/dev/null 2>&1; then
  echo "WARN: alias set failed via CLI; manual command:" >&2
  echo "vercel alias set '$PICK' '$ALIAS_HOST' --scope '$TEAM' $TOK_ARG" >&2
fi

echo "[4] Re-verify via alias"
AON=$(curl -s -o /dev/null -w '%{http_code}' "https://$ALIAS_HOST/onboarding")
ASE=$(curl -s -o /dev/null -w '%{http_code}' "https://$ALIAS_HOST/session?verb=Create&persona=Creator&minutes=20&task=hello")
curl -sS -o /tmp/_alias.docx -X POST "https://$ALIAS_HOST/api/export/docx" -H 'Content-Type: application/json' --data '{"title":"PRD Session","content":"Docx probe (alias)"}' || true
AHEX=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/_alias.docx 2>/dev/null || true)
echo "ALIAS_ONBOARDING:$AON"
echo "ALIAS_SESSION:$ASE"
echo "ALIAS_DOCX_HEX:$AHEX"

if [ "$AON" = "200" ] && [ "$ASE" = "200" ] && [ "$AHEX" = "504b" ]; then
  echo "ALIAS_OK"
else
  echo "ALIAS_NOT_READY"; exit 1
fi

echo "[5] Append status note"
mkdir -p docs
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
{
  echo "## Ship PRD MVP — ${TS}"
  echo "- Picked Ready: ${PICK}"
  echo "- Alias ${ALIAS_HOST}: Onboarding ${AON}, Session ${ASE}, DOCX ${AHEX}"
  echo ""
} >> docs/Status.md

SBR="wp040-ship-status-$(date -u +%Y%m%d_%H%M%S)"
git checkout -B "$SBR" >/dev/null
git add docs/Status.md && git commit -m "docs(status): record PRD MVP ship and alias" >/dev/null || true
git push -u origin "$SBR" >/dev/null
gh pr create --fill --base main --head "$SBR"
gh pr merge --squash --delete-branch

echo "DONE"


