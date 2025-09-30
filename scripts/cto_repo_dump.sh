#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Args
LIGHT=0
for arg in "$@"; do
  case "$arg" in
    --light) LIGHT=1 ;;
  esac
done

# Repo-aware dump script (portable: BSD/macOS compatible)

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

APP_DIR="."
[[ -d "web" ]] && [[ -f "web/package.json" ]] && APP_DIR="web"

OUT="$ROOT/repo-dump-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT" "$OUT/root" "$OUT/app"

# --- Basic metadata ---
{
  echo "==== GIT ===="
  git rev-parse --show-toplevel 2>/dev/null || true
  git branch --show-current 2>/dev/null || true
  git remote get-url origin 2>/dev/null || true
  git status --porcelain 2>/dev/null | wc -l | awk '{print "dirty_files:",$1}' || true
  git log --oneline -n 20 2>/dev/null || true
} > "$OUT/ABOUT.txt"

# --- Tree (files + dirs) ---
git ls-files > "$OUT/files.txt" 2>/dev/null || true
find . -type d -print \
  | awk -F/ 'NF<=4' > "$OUT/tree.txt" 2>/dev/null || true

# --- Package managers (root + app) ---
for f in package.json pnpm-lock.yaml yarn.lock requirements.txt pyproject.toml; do
  [[ -f "$f" ]] && cp "$f" "$OUT/root/" || true
done
if [[ "$APP_DIR" != "." ]]; then
  for f in package.json pnpm-lock.yaml yarn.lock package-lock.json; do
    [[ -f "$APP_DIR/$f" ]] && cp "$APP_DIR/$f" "$OUT/app/" || true
  done
fi

# --- App config likely relevant (root + app) ---
for f in next.config.* tsconfig.json vite.config.* astro.config.* .env.example; do
  [[ -f "$f" ]] && cp "$f" "$OUT/root/" || true
done
if [[ "$APP_DIR" != "." ]]; then
  for f in next.config.* tsconfig.json vite.config.* astro.config.* .env.example; do
    [[ -f "$APP_DIR/$f" ]] && cp "$APP_DIR/$f" "$OUT/app/" || true
  done
fi

# Helper: grep with find (portable, excludes node_modules)
grep_ts_js() {
  local base="$1"; shift
  local pattern="$1"; shift || true
  find "$base" -type f \
    \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
    -not -path '*/node_modules/*' -print0 \
    | xargs -0 grep -nE "$pattern" 2>/dev/null || true
}

# --- App code summaries ---
grep_ts_js "$ROOT" 'openai|anthropic|cohere|stripe|EventSource|WebSocket|SSE|validator' > "$OUT/code-greps.txt" || true

# --- Routes & API (Next.js app/pages) ---
APP_SRC_APP="$APP_DIR/src/app"
APP_APP="$APP_DIR/app"
APP_PAGES="$APP_DIR/pages"
[[ -d "$APP_SRC_APP" ]] && find "$APP_SRC_APP" -type d -print > "$OUT/app-routes.txt" 2>/dev/null || true
[[ -d "$APP_APP" ]] && find "$APP_APP" -type d -print >> "$OUT/app-routes.txt" 2>/dev/null || true
[[ -d "$APP_PAGES" ]] && find "$APP_PAGES" -type d -print > "$OUT/pages-routes.txt" 2>/dev/null || true

# Handlers: functions and route handlers in ts/tsx
{
  [[ -d "$APP_SRC_APP" ]] && grep_ts_js "$APP_SRC_APP" 'export default function|route|\bGET\b|\bPOST\b'
  [[ -d "$APP_APP" ]] && grep_ts_js "$APP_APP" 'export default function|route|\bGET\b|\bPOST\b'
  [[ -d "$APP_PAGES" ]] && grep_ts_js "$APP_PAGES" 'export default function|route|\bGET\b|\bPOST\b'
} > "$OUT/handlers.txt" || true

# --- Security headers & CSP ---
find "$ROOT" -type f -not -path '*/node_modules/*' -print0 \
  | xargs -0 grep -nE 'Content-Security-Policy|frame-ancestors|X-Frame-Options' 2>/dev/null \
  > "$OUT/security-headers.txt" || true

# --- Env usage (sanitized) ---
find "$APP_DIR" -type f -not -path '*/node_modules/*' -print0 \
  | xargs -0 grep -nE 'process\.env\.' 2>/dev/null \
  > "$OUT/env-usage.txt" || true

# --- Build & tests (inside app dir) ---
if [[ -f "$APP_DIR/package.json" ]]; then
  if [[ "$LIGHT" -eq 1 ]]; then
    echo "[light mode] skipped tests and build" > "$OUT/test-output.txt" || true
    echo "[light mode] skipped tests and build" > "$OUT/build-output.txt" || true
  else
    ( cd "$APP_DIR" && npm run -s test ) > "$OUT/test-output.txt" 2>&1 || true
    ( cd "$APP_DIR" && npm run -s build ) > "$OUT/build-output.txt" 2>&1 || true
  fi
fi

# --- Archive ---
tar -czf "$OUT.tar.gz" -C "$(dirname "$OUT")" "$(basename "$OUT")"
echo "Created $OUT.tar.gz"


