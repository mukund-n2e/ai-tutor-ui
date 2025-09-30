#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
APP_APP_DIR="$APP_DIR/src/app"
SRC_SCR="$APP_APP_DIR/screens"
SRC_USCR="$APP_APP_DIR/__screens"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/step19b_alias_fix_build_${TS}.log"
BR="wp019b-fix-screens-alias-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"; need npm || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"

# Only add reverse alias if /screens exists and /__screens is missing
if [ -d "$SRC_SCR" ] && [ ! -d "$SRC_USCR" ]; then
  mkdir -p "$SRC_USCR/[slug]"
  cat > "$SRC_USCR/page.tsx" <<'TSX'
export { metadata } from '../screens/page';
export { default } from '../screens/page';
TSX
  cat > "$SRC_USCR/[slug]/page.tsx" <<'TSX'
export { generateStaticParams, generateMetadata } from '../../screens/[slug]/page';
export { default } from '../../screens/[slug]/page';
TSX
fi

# Build check
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 160 "$BUILD_LOG" || true; exit 2; }

# Commit + PR
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$SRC_USCR" 2>/dev/null || true
git commit -m "fix(screens): add /__screens alias that re-exports from /screens (resolve import error)" >/dev/null 2>&1 || true
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
  [ -z "$PR_URL" ] && PR_URL="$(gh pr create --head "$BR" --title "fix(screens): add /__screens alias → /screens" --body "Reverse alias so both /screens and /__screens resolve without refactors.")"
fi

echo "=== CTO 19b ALIAS FIX SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "Files: $SRC_USCR/page.tsx , $SRC_USCR/[slug]/page.tsx"
echo "=== CTO 19b ALIAS FIX SUMMARY END ==="
