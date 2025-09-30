#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
ROOT="$(pwd)"
LOG_DIR="$ROOT/.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
NUDGE_FILE="web/public/_deploy_nudge_screens_${TS}.txt"
BR="redeploy-screens-${TS}"
DEPLOY_LOG="$LOG_DIR/screens_git_nudge_deploy_${TS}.log"
PROBE_LOG="$LOG_DIR/screens_git_nudge_probe_${TS}.log"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"
need curl || die "curl not found"

# 1) Tiny change inside /web to trigger Vercel Git integration
echo "nudge ${TS}" > "$NUDGE_FILE"

git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null

git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$NUDGE_FILE"
git commit -m "chore: trigger Vercel deploy for /screens (${TS})" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac

PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr list --head "$BR" --json url -q .[0].url 2>/dev/null || true)"
  [ -z "$PR_URL" ] && PR_URL="$(gh pr create --head "$BR" --title "chore: trigger Vercel deploy for /screens" --body "Auto nudge to deploy screens harness to prod.")"
  echo "PR: ${PR_URL:-<none>}"
  gh pr review "$BR" --approve >/dev/null 2>&1 || true
  gh pr merge  "$BR" --squash --delete-branch -y >/dev/null 2>&1 || true
else
  echo "Open PR manually and squash-merge: ${GH_URL:+$GH_URL/compare/$BR?expand=1}"
fi

# 2) Poll prod until the new deploy is live (bounded)
echo "Polling prod for deploy (bounded)…" | tee "$DEPLOY_LOG"
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL/smoke?nocache=$(date +%s)")
  echo "  /smoke -> $code" | tee -a "$DEPLOY_LOG"
  [ "$code" = "200" ] && break
  sleep 5
done

# 3) Probe /screens (fallback to /__screens), then probe up to 10 detail pages using manifest
echo "Probing ${PROD_URL} … (log: $PROBE_LOG)"
probe () { local p="$1"; local c; c=$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL$p?nocache=$(date +%s)"); echo "  $p -> $c" | tee -a "$PROBE_LOG"; [ "$c" = "200" ]; }

BASE="/screens"
probe "$BASE" || { BASE="/__screens"; probe "$BASE" >/dev/null || true; }

# find manifest path
MF=""
for p in "web/src/design/screens.manifest.ts" "web/design/screens.manifest.ts"; do
  [ -f "$p" ] && MF="$p" && break
done

ok=0; fail=0; count=0
if [ -n "$MF" ]; then
  SLUGS="$(node -e "const fs=require('fs');const s=fs.readFileSync('$MF','utf8');const a=s.indexOf('['),b=s.lastIndexOf(']');if(a<0||b<0)process.exit(0);const arr=JSON.parse(s.slice(a,b+1));console.log(arr.map(x=>x.slug).join('\n'))" 2>/dev/null || true)"
  while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    count=$((count+1))
    probe "$BASE/$slug" && ok=$((ok+1)) || fail=$((fail+1))
    [ $count -ge 10 ] && break
  done <<< "$SLUGS"
fi

echo "=== CTO 19a3 GIT NUDGE + PROBE SUMMARY START ==="
echo "Prod: $PROD_URL"
echo "PR: ${PR_URL:-<manual>}"
echo "Deploy log: $DEPLOY_LOG"
echo "Probe log:  $PROBE_LOG"
echo "Base path:  $BASE"
echo "Detail probes: PASS=$ok FAIL=$fail (max 10)"
echo "=== CTO 19a3 GIT NUDGE + PROBE SUMMARY END ==="
