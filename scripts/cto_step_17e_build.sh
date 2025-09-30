#!/usr/bin/env bash
set -Eeuo pipefail
APP_DIR="."
if [ -d "web" ] && [ -f "web/package.json" ]; then APP_DIR="web"; fi
BR="wp008-courses-clean"

# Ensure branch (created in your previous run)
git switch "$BR" >/dev/null 2>&1 || git checkout -b "$BR"

# Ensure logs dir (git clean may have removed it)
mkdir -p ./.cto_logs
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="./.cto_logs/courses_build_${TS}.log"

echo "Building in $APP_DIR … (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm ci && npm run build ) >"$BUILD_LOG" 2>&1 || { 
  echo "=== CTO BUILD SUMMARY START ==="
  echo "Branch: $BR"
  echo "App dir: $APP_DIR"
  echo "Build: FAIL"
  echo "Log: $BUILD_LOG"
  echo "=== CTO BUILD SUMMARY END ==="
  exit 2
}

echo "=== CTO BUILD SUMMARY START ==="
echo "Branch: $BR"
echo "App dir: $APP_DIR"
echo "Build: PASS"
echo "Log: $BUILD_LOG"
echo "=== CTO BUILD SUMMARY END ==="


