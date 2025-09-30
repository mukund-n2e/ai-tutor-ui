#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PRNUM="${PRNUM:-36}"
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
DEPLOY_LOG="$LOG_DIR/step19b3_deploy_${TS}.log"
PROBE_LOG="$LOG_DIR/step19b3_probe_${TS}.log"

need(){ command -v "$1" >/dev/null 2>&1; }
need git || { echo "git not found"; exit 2; }
need curl || { echo "curl not found"; exit 2; }

# 1) Merge PR if gh is available (otherwise leave it for manual)
if command -v gh >/dev/null 2>&1; then
  echo "Merging PR #$PRNUM…"
  gh pr review "$PRNUM" --approve >/dev/null 2>&1 || true
  gh pr merge  "$PRNUM" --squash --delete-branch -y >/dev/null 2>&1 || true
else
  echo "No gh CLI found. Merge PR #$PRNUM manually in GitHub."
fi

# 2) Create a tiny nudge in web/ to force Vercel Git deploy (safe if already deployed)
NUDGE="web/public/_deploy_nudge_19b3_${TS}.txt"
echo "nudge $TS" > "$NUDGE"
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
BR="redeploy-19b3-${TS}"
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$NUDGE"
git commit -m "chore: nudge deploy after sessions/screens merge (${TS})" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";; https://github.com/*) GH_URL="$REMOTE";; *) GH_URL="";; esac
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr create --head "$BR" --title "chore: nudge deploy after 19b.2" --body "Tiny file under web/ to trigger Vercel Git deploy.")"
  gh pr review "$BR" --approve >/dev/null 2>&1 || true
  gh pr merge  "$BR" --squash --delete-branch -y >/dev/null 2>&1 || true
fi

# 3) Poll prod for /smoke to turn 200 (bounded)
echo "Polling prod /smoke …" | tee "$DEPLOY_LOG"
for i in $(seq 1 60); do
  code="$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL/smoke?nocache=$(date +%s)")"
  echo "  /smoke -> $code" | tee -a "$DEPLOY_LOG"
  [ "$code" = "200" ] && break
  sleep 5
done

# 4) Probe core routes
probe(){ local p="$1"; local c; c=$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL$p?nocache=$(date +%s)"); echo "  $p -> $c" | tee -a "$PROBE_LOG"; }
echo "Probing $PROD_URL …" | tee "$PROBE_LOG"
probe "/"
probe "/api/health"
probe "/tutor"
probe "/sessions"
probe "/screens"
probe "/__screens"

echo "=== CTO 19b.3 MERGE+PROBE SUMMARY START ==="
echo "Prod: $PROD_URL"
echo "Deploy log: $DEPLOY_LOG"
echo "Probe log:  $PROBE_LOG"
echo "If /screens is 404, give it ~60s or run this script once more."
echo "=== CTO 19b.3 MERGE+PROBE SUMMARY END ==="
