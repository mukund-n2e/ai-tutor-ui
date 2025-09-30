#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

if [ ! -f "web/package.json" ]; then
  echo "Run this from the repo root (the folder that contains /web)"
  exit 2
fi

ROOT="$(pwd)"
LOG_DIR="$ROOT/.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
LOG="$LOG_DIR/build_from_root_${TS}.log"

echo "Building web (log: $LOG)..."
(
  cd web
  if [ -f package-lock.json ]; then
    npm ci
  else
    npm install
  fi
  npm run build
) >"$LOG" 2>&1 || { echo "Build FAILED (see $LOG)"; exit 1; }

echo "Build PASS (log: $LOG)"


