#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

BR="wp008-courses-next15-fix"
APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

mkdir -p ./.cto_logs
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="./.cto_logs/next15_fix_build_${TS}.log"
PROBE_LOG="./.cto_logs/next15_fix_probe_${TS}.log"

# Optional local build (fast, catches regressions)
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; exit 2; }

# Push branch
git push -u origin "$BR" --force-with-lease >/dev/null 2>&1 || true

# Repo URL for fallbacks
REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac

# PR + merge
PR_URL=""; MERGED="no"
if command -v gh >/dev/null 2>&1; then
  set +e
  PR_URL="$(gh pr list --head "$BR" --json url -q '.[0].url' 2>/dev/null || true)"
  [ -z "$PR_URL" ] && PR_URL="$(gh pr create --head "$BR" --title "fix(next15): courses params & tutor client page" --body "Aligns with Next 15 PageProps; forces static for Courses; fixes Tutor page." 2>/dev/null | tail -n1)"
  gh pr review "$BR" --approve >/dev/null 2>&1 || true
  gh pr merge  "${PR_URL:-$BR}" --squash --admin --delete-branch -y >/dev/null 2>&1 || \
  gh pr merge  "${PR_URL:-$BR}" --squash --delete-branch -y >/dev/null 2>&1 || true
  for i in $(seq 1 60); do  # poll for merge
    ST="$(gh pr view "${PR_URL:-$BR}" --json state -q .state 2>/dev/null || echo "")"
    [ "$ST" = "MERGED" ] && MERGED="yes" && break
    sleep 5
  done
  set -e
else
  [ -n "$GH_URL" ] && echo "Open and merge: $GH_URL/compare/$BR?expand=1"
fi

# Probe production with cache-busting (quick loop; bump PROBE_LIMIT if you want longer)
echo "Probing $URL … (log: $PROBE_LOG)"
PROBE_LIMIT="${PROBE_LIMIT:-40}"   # ~5–6 minutes at 8s intervals
probe_once() {
  local path="$1"; local needle="$2"; local t="$(date +%s)"
  local body code
  body="$(curl -fsSL "$URL$path?nocache=$t" -H 'Cache-Control: no-cache' 2>>"$PROBE_LOG" || true)"
  code="$([ -n "$body" ] && echo 200 || curl -s -o /dev/null -w '%{http_code}' "$URL$path?nocache=$t" 2>>"$PROBE_LOG")"
  if [ "$code" = "200" ] && echo "$body" | grep -qi "$needle"; then echo "yes"; else echo "no"; fi
}
wait_for() {
  local path="$1"; local needle="$2"; local label="$3"
  for i in $(seq 1 "$PROBE_LIMIT"); do
    [ "$(probe_once "$path" "$needle")" = "yes" ] && echo "$label: PASS" && return 0
    sleep 8
  done
  echo "$label: FAIL (timeout)"; return 1
}

R1="$(wait_for "/courses" "Courses" "Prod /courses")" || true
R2="$(wait_for "/courses/getting-started" "Getting Started with the AI Tutor" "Prod /courses/getting-started")" || true

echo "=== CTO NEXT15 PUSH+MERGE+PROBE SUMMARY START ==="
[ -n "$GH_URL" ] && echo "Repo: $GH_URL"
[ -n "$PR_URL" ] && echo "PR: $PR_URL"
echo "Merged: $MERGED"
echo "Build log: $BUILD_LOG"
echo "Prod URL: $URL"
echo "$R1"
echo "$R2"
echo "Probe log: $PROBE_LOG"
echo "=== CTO NEXT15 PUSH+MERGE+PROBE SUMMARY END ==="


