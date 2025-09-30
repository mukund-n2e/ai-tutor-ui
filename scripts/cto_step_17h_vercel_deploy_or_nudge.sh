#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# --- Config / Detect ---
APP_DIR="."
if [ -d "web" ] && [ -f "web/package.json" ]; then APP_DIR="web"; fi
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

ROOT="$(pwd)"
mkdir -p "$ROOT/.cto_logs"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$ROOT/.cto_logs/vercel_build_${TS}.log"
DEPLOY_LOG="$ROOT/.cto_logs/vercel_deploy_${TS}.log"
PROBE_LOG="$ROOT/.cto_logs/courses_prod_probe_${TS}.log"

need(){ command -v "$1" >/dev/null 2>&1; }

# --- Try Vercel CLI path (preferred) ---
VC="no"
if need vercel; then
  VC="yes"
  echo "Using Vercel CLI for production deploy…"
  pushd "$APP_DIR" >/dev/null

  # Pull env and project linkage (best-effort; works if the project is already linked on this machine)
  set +e
  vercel pull --yes --environment=production >/dev/null 2>&1
  VPULL=$?
  set -e

  # Build and deploy with CLI (build → .vercel/output, then prebuilt deploy)
  echo "vercel build --prod  (log: $BUILD_LOG)"
  set +e
  vercel build --prod >"$BUILD_LOG" 2>&1
  VBUILD=$?
  set -e

  if [ $VBUILD -eq 0 ]; then
    echo "vercel deploy --prebuilt --prod --yes  (log: $DEPLOY_LOG)"
    set +e
    vercel deploy --prebuilt --prod --yes >"$DEPLOY_LOG" 2>&1
    VDEPLOY=$?
    set -e
  else
    VDEPLOY=1
  fi

  popd >/dev/null

  if [ $VBUILD -eq 0 ] && [ $VDEPLOY -eq 0 ]; then
    echo "Vercel CLI deploy triggered."
  else
    echo "Vercel CLI path failed (build=$VBUILD deploy=$VDEPLOY). Falling back to Git 'nudge' PR."
    VC="no"
  fi
fi

# --- Fallback: tiny PR to trigger Git deploy ---
if [ "$VC" = "no" ]; then
  echo "Triggering Git-based deploy via tiny PR…"
  # Ensure clean main locally
  git fetch origin --prune --quiet
  git switch -C main >/dev/null 2>&1 || git checkout -B main
  git reset --hard origin/main

  # Create tiny branch that touches a harmless public file
  BR="redeploy-${TS}"
  git switch -C "$BR"
  mkdir -p "$APP_DIR/public"
  echo "redeploy ${TS}" > "$APP_DIR/public/.vercel_redeploy.txt"
  git add "$APP_DIR/public/.vercel_redeploy.txt"
  git commit -m "chore: trigger vercel deploy (redeploy ${TS})" >/dev/null

  # Push and PR
  git push -u origin "$BR" --force-with-lease >/dev/null 2>&1 || true

  # Build repo URL
  REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
  case "$REMOTE" in
    git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
    https://github.com/*) GH_URL="$REMOTE";;
    *) GH_URL="";;
  esac

  PR_URL=""
  if need gh; then
    set +e
    PR_URL="$(gh pr create --head "$BR" --title "chore: trigger vercel deploy (${TS})" --body "Tiny change in public/ to kick a Vercel Git deploy." 2>/dev/null | tail -n1)"
    gh pr review "$BR" --approve >/dev/null 2>&1 || true
    gh pr merge  "${PR_URL:-$BR}" --squash --admin --delete-branch -y >/dev/null 2>&1 || \
    gh pr merge  "${PR_URL:-$BR}" --squash --delete-branch -y >/dev/null 2>&1 || true
    set -e
  else
    [ -n "$GH_URL" ] && echo "Open and merge: $GH_URL/compare/$BR?expand=1"
  fi
fi

# --- Probe production with cache-busting until Courses is live ---
echo "Probing $PROD_URL … (log: $PROBE_LOG)"
probe_once() {
  local path="$1"; local needle="$2"; local t
  t="$(date +%s)"
  local body code
  body="$(curl -fsSL "$PROD_URL$path?nocache=$t" -H 'Cache-Control: no-cache' 2>>"$PROBE_LOG" || true)"
  code="$([ -n "$body" ] && echo 200 || curl -s -o /dev/null -w '%{http_code}' "$PROD_URL$path?nocache=$t" 2>>"$PROBE_LOG")"
  if [ "$code" = "200" ] && echo "$body" | grep -qi "$needle"; then echo "yes"; else echo "no"; fi
}
wait_for() {
  local path="$1"; local needle="$2"; local label="$3"
  local limit=80; local sleep_s=10
  for i in $(seq 1 $limit); do
    if [ "$(probe_once "$path" "$needle")" = "yes" ]; then echo "$label: PASS"; return 0; fi
    sleep $sleep_s
  done
  echo "$label: FAIL (timeout)"; return 1
}

R1="$(wait_for "/courses" "Courses" "Prod /courses")" || true
R2="$(wait_for "/courses/getting-started" "Getting Started with the AI Tutor" "Prod /courses/getting-started")" || true

echo "=== CTO VERCEL DEPLOY/NUDGE SUMMARY START ==="
echo "Vercel CLI used: $VC"
echo "Prod URL: $PROD_URL"
echo "Build log: $BUILD_LOG"
echo "Deploy log: $DEPLOY_LOG"
echo "$R1"
echo "$R2"
echo "Probe log: $PROBE_LOG"
echo "=== CTO VERCEL DEPLOY/NUDGE SUMMARY END ==="


