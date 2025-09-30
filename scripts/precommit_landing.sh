#!/usr/bin/env bash
set -euo pipefail

# Allowlist while we finish Landing; update this per screen
# Allow legacy quarantine moves during refactor
ALLOW_RE='^(web/src/app/\(marketing\)/|web/src/components/(Header|Button|Chip|Card)\.tsx|web/src/styles/(tokens|landing\.module)\.css|public/assets/|design/|tests/e2e/landing\.spec\.ts|scripts/|web/src/legacy/)'

changed=$(git diff --cached --name-only)

viol=0
while read -r f; do
  [ -z "$f" ] && continue
  if ! echo "$f" | grep -Eq "$ALLOW_RE"; then
    echo "❌ Blocked (out of scope): $f"
    viol=1
  fi
done <<< "$changed"
[ $viol -eq 0 ] || exit 1

# Only scan added lines within web/src to avoid matching this script or other non-web files
bad=$(git diff --cached -U0 -- web/src | grep -E "^\+.*(style=\{\{|bg-white|gray-50|gray-100|#[0-9A-Fa-f]{3,6})" || true)
if [ -n "$bad" ]; then
  echo "❌ Disallowed style patterns in staged changes:"
  echo "$bad"
  exit 1
fi

echo "✅ Pre-commit checks passed."


