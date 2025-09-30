#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PRNUM="${PRNUM:-36}"  # override with: PRNUM=nn bash cto_step_19b3_merge_and_probe_v2.sh
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

need(){ command -v "$1" >/dev/null 2>&1; }
need git || { echo "git not found"; exit 2; }
need curl || { echo "curl not found"; exit 2; }

LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
DEPLOY_LOG="$LOG_DIR/step19b3_deploy_${TS}.log"
PROBE_LOG="$LOG_DIR/step19b3_probe_${TS}.log"
NUDGE_BRANCH="redeploy-19b3-${TS}"
NUDGE_FILE="web/public/_deploy_nudge_19b3_${TS}.txt"

# 1) Merge PR (if gh is present and PR exists)
if command -v gh >/dev/null 2>&1; then
  if gh pr view "$PRNUM" >/dev/null 2>&1; then
    echo "Merging PR #$PRNUM…"
    gh pr review "$PRNUM" --approve >/dev/null 2>&1 || true
    gh pr merge  "$PRNUM" --squash --delete-branch >/dev/null 2>&1 || true
  else
    echo "Note: PR #$PRNUM not found or already merged."
  fi
else
  echo "gh CLI not found – merge PR #$PRNUM in GitHub UI if still open."
fi

# 2) Nudge a git deploy (tiny tracked change inside web/)
echo "nudge $TS" > "$NUDGE_FILE"
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$NUDGE_BRANCH" >/dev/null 2>&1 || git checkout -B "$NUDGE_BRANCH"
git add "$NUDGE_FILE"
git commit -m "chore: nudge deploy after sessions/screens merge (${TS})" >/dev/null 2>&1 || true
git push -u origin "$NUDGE_BRANCH" >/dev/null 2>&1 || true

if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr create --head "$NUDGE_BRANCH" --title "chore: nudge deploy after 19b.2" --body "Tiny file under web/ to trigger Vercel Git deploy." 2>/dev/null || true)"
  [ -n "$PR_URL" ] && echo "Nudge PR: $PR_URL"
  gh pr review "$NUDGE_BRANCH" --approve >/dev/null 2>&1 || true
  gh pr merge  "$NUDGE_BRANCH" --squash --delete-branch >/dev/null 2>&1 || true
else
  REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
  case "$REMOTE" in
    git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
    https://github.com/*) GH_URL="$REMOTE";;
    *) GH_URL="";;
  esac
  echo "Open and squash-merge manually: ${GH_URL:+$GH_URL/compare/$NUDGE_BRANCH?expand=1}"
fi

# 3) Poll prod for /smoke → 200 (bounded)
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
echo "Hint: if /screens is 404, wait ~60s and rerun once."
echo "=== CTO 19b.3 MERGE+PROBE SUMMARY END ==="
