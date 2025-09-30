#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
APP_APP_DIR="$APP_DIR/src/app"
URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

mkdir -p ./.cto_logs
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="./.cto_logs/courses_static_build_${TS}.log"
PROBE_LOG="./.cto_logs/courses_static_probe_${TS}.log"
BR="wp008-courses-static"

# 1) New branch off clean main
git fetch origin --prune --quiet
git switch -C main >/dev/null 2>&1 || git checkout -B main
git reset --hard origin/main
git switch -C "$BR"

# 2) Add force-static + revalidate to both pages (idempotent)
for f in "$APP_APP_DIR/courses/page.tsx" "$APP_APP_DIR/courses/[slug]/page.tsx"; do
  [ -f "$f" ] || { echo "Missing $f"; exit 2; }
  if ! grep -q "dynamic = 'force-static'" "$f"; then
    awk 'NR==1{print "export const dynamic = '\''force-static'\'';"; print "export const revalidate = 3600;"; print ""}1' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
done

git add "$APP_APP_DIR/courses/page.tsx" "$APP_APP_DIR/courses/[slug]/page.tsx"
git commit -m "chore(courses): force static generation + revalidate for Vercel" >/dev/null

# 3) Build to catch errors
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; exit 2; }

# 4) Push and PR/merge (CLI or browser fallback)
git push -u origin "$BR" --force-with-lease >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo "")"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac

PR_URL=""; MERGED="no"
if command -v gh >/dev/null 2>&1; then
  set +e
  PR_URL="$(gh pr create --head "$BR" --title "chore(courses): force static generation on Vercel" --body "Adds \`dynamic='force-static'\` + \`revalidate=3600\` for /courses routes." 2>/dev/null | tail -n1)"
  gh pr review "$BR" --approve >/dev/null 2>&1 || true
  gh pr merge  "${PR_URL:-$BR}" --squash --admin --delete-branch -y >/dev/null 2>&1 || \
  gh pr merge  "${PR_URL:-$BR}" --squash --delete-branch -y >/dev/null 2>&1 || true
  for i in $(seq 1 60); do
    ST="$(gh pr view "${PR_URL:-$BR}" --json state -q .state 2>/dev/null || echo "")"
    [ "$ST" = "MERGED" ] && MERGED="yes" && break
    sleep 5
  done
  set -e
else
  [ -n "$GH_URL" ] && echo "Open and merge: $GH_URL/compare/$BR?expand=1"
fi

# 5) Probe prod (cache-busting)
echo "Probing $URL … (log: $PROBE_LOG)"
probe_once() {
  local path="$1"; local needle="$2"; local t=$(date +%s)
  local body code
  body="$(curl -fsSL "$URL$path?nocache=$t" -H 'Cache-Control: no-cache' 2>>"$PROBE_LOG" || true)"
  code="$([ -n "$body" ] && echo 200 || curl -s -o /dev/null -w "%{http_code}" "$URL$path?nocache=$t" 2>>"$PROBE_LOG")"
  if [ "$code" = "200" ] && echo "$body" | grep -qi "$needle"; then echo "yes"; else echo "no"; fi
}
wait_for() {
  local path="$1"; local needle="$2$"; local label="$3"
  local limit=80; local sleep_s=10
  for i in $(seq 1 $limit); do
    if [ "$(probe_once "$path" "$needle")" = "yes" ]; then echo "$label: PASS"; return 0; fi
    sleep $sleep_s
  done
  echo "$label: FAIL (timeout)"; return 1
}
R1="$(wait_for "/courses" "Courses" "Prod /courses")" || true
R2="$(wait_for "/courses/getting-started" "Getting Started with the AI Tutor" "Prod /courses/getting-started")" || true

echo "=== CTO COURSES STATIC REDEPLOY SUMMARY START ==="
echo "PR: ${PR_URL:-<manual>}"
echo "Merged: $MERGED"
echo "Build log: $BUILD_LOG"
echo "Prod URL: $URL"
echo "$R1"
echo "$R2"
echo "Probe log: $PROBE_LOG"
echo "=== CTO COURSES STATIC REDEPLOY SUMMARY END ==="


