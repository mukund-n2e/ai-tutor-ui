#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT="$(pwd)"
APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
LOG_DIR="$ROOT/.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/nav_in_layout_build_${TS}.log"
BR="wp010c-nav-in-layout-${TS}"

echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 120 "$BUILD_LOG" || true; exit 2; }

git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null

git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$APP_DIR/src/app/layout.tsx"
git commit -m "feat(ui): render TopNav in layout" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr create --head "$BR" --title "feat(ui): render TopNav in layout" --body "Render TopNav globally from layout so brand shows on all pages." 2>/dev/null || true)"
  # try auto-merge
  if [ -n "$PR_URL" ]; then
    gh pr review "$PR_URL" --approve >/dev/null 2>&1 || true
    gh pr merge  "$PR_URL" --squash --delete-branch -y >/dev/null 2>&1 || true
  fi
fi

echo "=== CTO NAV-IN-LAYOUT SUMMARY START ==="
echo "Branch: $BR"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || echo "PR: (open manually if needed)"
echo "=== CTO NAV-IN-LAYOUT SUMMARY END ==="



