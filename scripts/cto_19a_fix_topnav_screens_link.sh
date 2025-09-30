#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
TN="$APP_DIR/src/components/TopNav.tsx"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/topnav_screens_fix_build_${TS}.log"
BR="wp019a-fix-topnav-screens-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"; need npm || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"
[ -f "$TN" ] || die "TopNav not found at $TN"

cp "$TN" "$TN.bak.$TS"

# 1) Ensure Link import
if ! grep -q "from 'next/link'" "$TN"; then
  sed -i.bak "1s|^|import Link from 'next/link';\n|" "$TN" && rm -f "$TN.bak"
fi

# 2) Remove any stray Screens link lines (outside <nav>) to avoid dupes
#    This removes the conditional link wherever it currently sits.
sed -i.bak "/NEXT_PUBLIC_SHOW_SCREENS/d" "$TN" && rm -f "$TN.bak"

# 3) Insert the conditional link *before* </nav>
if grep -q "</nav>" "$TN"; then
  awk '1; /<\/nav>/{print "      {process.env.NEXT_PUBLIC_SHOW_SCREENS === '\''1'\'' && (<Link href=\"/__screens\">Screens</Link>)}"}' "$TN" > "$TN.tmp" && mv "$TN.tmp" "$TN"
else
  echo "WARN: </nav> not found in $TN; leaving file untouched. See backup $TN.bak.$TS" >&2
fi

# 4) Build to verify
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 160 "$BUILD_LOG" || true; exit 2; }

# 5) Commit + PR
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$TN"
git commit -m "fix(nav): place Screens link inside <nav> and ensure Link import (19a harness)" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac
PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr create --head "$BR" --title "fix(nav): Screens link inside <nav> (19a)" --body "Move conditional dev link into the <nav> to avoid JSX parse error; ensure Link import. Idempotent.")" || true
fi

echo "=== CTO 19a TOPNAV FIX SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "File: $TN"
echo "=== CTO 19a TOPNAV FIX SUMMARY END ==="
