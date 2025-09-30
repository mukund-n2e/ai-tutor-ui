#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Ultra-light code view exporter
# Produces a single compressed text file with:
# - file path, size, sha256
# - first N KB of each code file (ts/tsx/js/jsx/css/config)
# Excludes node_modules, .git, build outputs. No installs/builds.

need(){ command -v "$1" >/dev/null 2>&1; }

# Args
LIMIT_KB=16
APP_DIR="."
[[ -d "web" ]] && [[ -f "web/package.json" ]] && APP_DIR="web"
OUT_DIR="$(pwd)"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit-kb) LIMIT_KB="${2:-16}"; shift 2;;
    --app) APP_DIR="${2:-$APP_DIR}"; shift 2;;
    --out-dir) OUT_DIR="${2:-$OUT_DIR}"; shift 2;;
    *) echo "WARN: unknown arg $1" >&2; shift;;
  esac
done

TS="$(date -u +%Y%m%d-%H%M%S)"
OUT_TXT="$OUT_DIR/repo-lightview-$TS.txt"

# Hash helper (portable)
hash_file(){
  if need shasum; then shasum -a 256 "$1" | awk '{print $1}';
  elif need sha256sum; then sha256sum "$1" | awk '{print $1}';
  else echo "sha256-not-available"; fi
}

is_excluded(){
  case "$1" in
    */node_modules/*|*/.git/*|*/.vercel/*|*/coverage/*) return 0;;
  esac
  return 1
}

# Collect and emit
{
  echo "# repo lightview"
  echo "generated: $TS UTC"
  echo "app_dir: $APP_DIR"
  echo "limit_kb: $LIMIT_KB"
  echo
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    is_excluded "$f" && continue
    [[ -f "$f" ]] || continue
    sz=$(wc -c <"$f" | tr -d ' ')
    sha=$(hash_file "$f")
    echo "===== FILE BEGIN: $f (bytes=$sz sha256=$sha) ====="
    # Print first N KB safely (portable dd)
    dd if="$f" bs=1024 count="$LIMIT_KB" 2>/dev/null || true
    echo
    [[ "$sz" -gt $((LIMIT_KB*1024)) ]] && echo "--- [truncated to ${LIMIT_KB}KB] ---"
    echo "===== FILE END: $f ====="
    echo
  done < <( find "$APP_DIR" -type f \
      \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.css" \
         -o -name "package.json" -o -name "tsconfig.json" -o -name "next.config.*" \
         -o -name "postcss.config.*" -o -name "eslint.config.*" -o -name "vitest.config.*" \) \
      -not -path '*/node_modules/*' \
      -not -path '*/.git/*' \
      -not -path '*/.vercel/*' \
      -not -path '*/coverage/*' \
      -print | LC_ALL=C sort )
} > "$OUT_TXT"

# Compress with xz if available, else gzip; fall back to plain
OUT_FINAL="$OUT_TXT"
if need xz; then
  xz -9e -T1 "$OUT_TXT"
  OUT_FINAL="$OUT_TXT.xz"
elif need gzip; then
  gzip -9 "$OUT_TXT"
  OUT_FINAL="$OUT_TXT.gz"
fi

echo "Created $OUT_FINAL"


