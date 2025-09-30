#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT="$(pwd)"
APP_DIR="web"
FILE="$APP_DIR/src/app/session/page.tsx"
LOG_DIR="$ROOT/.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/fix_session_any_build_${TS}.log"

[ -f "$FILE" ] || { echo "missing $FILE"; exit 2; }

# Replace `catch (e:any)` with safer unknown handling and setErr message narrowing
# macOS/BSD sed requires an explicit empty suffix for -i
sed -i '' -E 's/catch \(e:\s*any\)/catch (e: unknown)/' "$FILE"
sed -i '' -E 's/setErr\(e\?\.message \|\| '\''stream error'\''\);/setErr(e instanceof Error ? e.message : "stream error");/' "$FILE" || true

# Build to verify lint/types
(
  cd "$APP_DIR"
  npm run build
) >"$BUILD_LOG" 2>&1 || { tail -n 40 "$BUILD_LOG"; exit 1; }

echo OK

