#!/usr/bin/env bash
set -euo pipefail

ALLOWLIST_REGEX='^(design/|web/src/app/(pricing|onboarding|wall|lesson|lesson/L1-05/outline)|web/src/components|web/src/styles|web/src/app/api/checkout|web/public/design/expected/|scripts/|package.json$|\.gitignore$|CODEOWNERS$|\.github/CODEOWNERS$|\.github/workflows/|ai-tutor-design-pack-v4/|archive/dupes/)'

# 1) Block staging outside allowlist while we harden new UI
CHANGED=$(git diff --cached --name-only)
for f in $CHANGED; do
  if [[ ! "$f" =~ $ALLOWLIST_REGEX ]]; then
    echo "Guard: '$f' is outside allowlist during UI hardening. Unstage or update allowlist."
    exit 1
  fi
done

# 2) Block disallowed patterns in added lines
git diff --cached -U0 -- web/src | awk '/^\+/{print}' | \
  grep -E 'style=\{\{|bg-white|gray-50|gray-100|#[0-9A-Fa-f]{3,6}' && {
    echo "Guard: Found inline styles or raw colors in staged changes."; exit 1; } || true

# images must live under design/frames or synced to web/public/design/expected
FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(png|jpg|jpeg|svg)$' || true)
BAD=$(echo "$FILES" | grep -Ev '^design/frames/|^web/public/design/expected/' || true)
if [ -n "$BAD" ]; then
  echo "❌ Images must live in design/frames (public copies go to web/public/design/expected via sync script)"
  echo "$BAD" | sed 's/^/ - /'
  exit 1
fi

exit 0