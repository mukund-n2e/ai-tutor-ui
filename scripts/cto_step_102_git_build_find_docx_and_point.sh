#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS_HOST="tutorweb-cyan.vercel.app"
ALIAS_URL="https://${ALIAS_HOST}"

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

# Prefer .vercel/project.json orgId if present (more reliable than a stale slug)
if [ -f .vercel/project.json ]; then
  TID="$(node -e "try{const j=require('./.vercel/project.json'); if(j&&j.orgId) console.log(j.orgId)}catch{}" 2>/dev/null || true)"
  if [ -n "$TID" ]; then
    TEAM="$TID"
  fi
fi

# Ensure Vercel context is correct
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null || true

echo "[1/4] Scan existing Ready prod deployments and test DOCX…"
scan_and_pick() {
  # Prefer JSON listing; fall back to table parsing
  local urls=""
  if vercel list "$PROJECT" --scope "$TEAM" --prod --json >/tmp/vls.json 2>/dev/null; then
    node -e "const a=require('/tmp/vls.json'); if(Array.isArray(a)){const c=a.filter(x=>(x.target||'').toLowerCase()==='production' && (x.state||'').toLowerCase()==='ready').sort((p,q)=>(+new Date(q.createdAt||q.created||0))-(+new Date(p.createdAt||p.created||0))); c.slice(0,12).forEach(x=>console.log('https://'+x.url));}" >/tmp/candidates.txt
  else
    vercel ls "$PROJECT" --scope "$TEAM" --prod >/tmp/vls.txt 2>/dev/null || true
    awk '/vercel\.app/ { url=""; ready=0; for(i=1;i<=NF;i++) if ($i ~ /^https:\/\/[a-z0-9-]+\.vercel\.app$/) url=$i; if ($0 ~ /Ready/) ready=1; if (url != "" && ready==1) print url; }' /tmp/vls.txt | head -n 12 >/tmp/candidates.txt
  fi

  urls="$(cat /tmp/candidates.txt || true)"
  [ -n "$urls" ] || return 1

  for URL in $urls; do
    echo "  - probe $URL"
    # Onboarding 200
    [ "$(curl -s -o /dev/null -w '%{http_code}' "$URL/onboarding")" = "200" ] || { echo "    onboarding !200"; continue; }
    # Session 200
    SURL="$URL/session?verb=Create&persona=Creator&minutes=20&task=hello"
    [ "$(curl -s -o /dev/null -w '%{http_code}' "$SURL")" = "200" ] || { echo "    session !200"; continue; }
    # DOCX magic 0x504b
    curl -sS -o /tmp/_out.docx -X POST "$URL/api/export/docx" \
         -H 'Content-Type: application/json' \
         --data '{"title":"PRD Session","content":"Docx probe"}' || true
    hex="$(hexdump -n 2 -e '2/1 "%02x"' /tmp/_out.docx 2>/dev/null || true)"
    if [ "$hex" = "504b" ]; then
      echo "    docx OK ($hex)"
      echo "$URL" > /tmp/PICK_URL
      return 0
    else
      echo "    docx BAD (hex:$hex)"
    fi
  done
  return 1
}

if ! scan_and_pick; then
  echo "[2/4] No Ready prod with working DOCX. Trigger a new Git Production build…"
  branch="wp037-prod-release-$(date -u +%Y%m%d_%H%M%S)"
  touch "web/public/_deploy-trigger-$(date -u +%Y%m%d_%H%M%S).txt"
  git checkout -B "$branch" >/dev/null 2>&1 || git checkout -b "$branch"
  git add web/public/_deploy-trigger-* >/dev/null
  git commit -m "chore(deploy): trigger Production build for DOCX + PRD loop" >/dev/null
  git push -u origin "$branch" >/dev/null
  gh pr create --fill --base main --head "$branch"
  gh pr merge --squash --delete-branch

  echo "[3/4] Poll newest Ready Production until DOCX works…"
  # Poll up to ~15 minutes (60 * 15s)
  for i in $(seq 1 60); do
    if scan_and_pick; then break; fi
    sleep 15
  done
fi

[ -s /tmp/PICK_URL ] || { echo "ERR_NO_READY_RELEASE"; exit 1; }
PICK="$(cat /tmp/PICK_URL)"
echo "[4/4] Point alias ${ALIAS_HOST} → ${PICK} and verify via alias"

if ! vercel alias set "$PICK" "$ALIAS_HOST" --scope "$TEAM" >/dev/null; then
  echo "WARN: alias set failed via CLI (possibly not authenticated for scope $TEAM)."
  echo "Command to run manually: vercel alias set '$PICK' '$ALIAS_HOST' --scope '$TEAM'"
fi

AON="$(curl -s -o /dev/null -w '%{http_code}' "$ALIAS_URL/onboarding")"
ASE="$(curl -s -o /dev/null -w '%{http_code}' "$ALIAS_URL/session?verb=Create&persona=Creator&minutes=20&task=hello")"
curl -sS -o /tmp/_alias.docx -X POST "$ALIAS_URL/api/export/docx" \
     -H 'Content-Type: application/json' \
     --data '{"title":"PRD Session","content":"Docx probe (alias)"}' || true
AHEX="$(hexdump -n 2 -e '2/1 "%02x"' /tmp/_alias.docx 2>/dev/null || true)"

echo "ALIAS_ONBOARDING:$AON"
echo "ALIAS_SESSION:$ASE"
echo "ALIAS_DOCX_HEX:$AHEX"

if [ "$AON" = "200" ] && [ "$ASE" = "200" ] && [ "$AHEX" = "504b" ]; then
  echo "RELEASE_POINTED"
else
  echo "ALIAS_NOT_READY"; exit 1
fi



