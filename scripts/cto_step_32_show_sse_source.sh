#!/usr/bin/env bash
set -euo pipefail

echo "Locating tutor/stream route…"
found=0

# App Router variants
while IFS= read -r f; do
  [ -n "$f" ] || continue
  echo "=== $f ==="
  sed -n '1,200p' "$f"
  echo
  found=1
done < <(find web -type f \( -name 'route.ts' -o -name 'route.js' -o -name 'route.mjs' -o -name 'route.cjs' \) -path '*/api/tutor/stream/*' 2>/dev/null)

# Pages Router fallback
if [ "$found" -eq 0 ]; then
  for f in web/pages/api/tutor/stream.ts web/pages/api/tutor/stream.js; do
    if [ -f "$f" ]; then
      echo "=== $f ==="
      sed -n '1,200p' "$f"
      echo
      found=1
    fi
  done
fi

# If still nothing, show references
if [ "$found" -eq 0 ]; then
  echo "No route file found. Showing references:"
  grep -RIn --exclude-dir node_modules --exclude-dir .next "tutor/stream" web | head -n 80 || true
fi
