#!/usr/bin/env bash
set -euo pipefail

ROOT="src"
[ -d "web/src" ] && ROOT="web/src"

echo "=== UI Verifier ==="
missing=0

# Key files/routes we expect to exist
must_have=(
  "$ROOT/styles/tokens.css"
  "$ROOT/components/Header.tsx"
  "$ROOT/components/Button.tsx"
  "$ROOT/components/Card.tsx"
  "$ROOT/components/Chip.tsx"
  "$ROOT/app/page.tsx"                   # landing
  "$ROOT/app/onboarding/page.tsx"        # onboarding
  "$ROOT/app/wall/page.tsx"              # course wall
  "$ROOT/app/lesson/L1-05/outline/page.tsx"  # outline
  "$ROOT/app/pricing/page.tsx"           # pricing/checkout launcher
  "$ROOT/app/checkout/success/page.tsx"  # checkout success
  "$ROOT/app/checkout/error/page.tsx"    # checkout error
  "$ROOT/app/legal/privacy/page.tsx"     # privacy
  "$ROOT/app/legal/terms/page.tsx"       # terms
  "$ROOT/app/not-found.tsx"              # 404
  "$ROOT/app/error.tsx"                  # 500
)

for f in "${must_have[@]}"; do
  if [ ! -f "$f" ]; then echo "MISS: $f"; missing=$((missing+1)); fi
done

# Banned patterns in core components + styles (no inline styles or raw grays)
pat_inline='style=\{\{'
pat_white='bg-white|gray-50|gray-100'
ret=0

if grep -R --line-number -E "$pat_inline" "$ROOT/components" 2>/dev/null; then
  echo "Inline styles found in components"; ret=1; fi

if grep -R --line-number -E "$pat_white" "$ROOT/components" 2>/dev/null; then
  echo "Raw gray/white utilities found in components"; ret=1; fi

# CSS modules: no raw rgba for tints (tokens only)
if grep -R --line-number -E "rgba\(" "$ROOT/styles" 2>/dev/null | grep -v "tokens.css"; then
  echo "Raw rgba found in styles (use tokens)"; ret=1; fi

# Summarize
if [ "$missing" -gt 0 ]; then echo "Missing $missing required files"; ret=1; fi

if [ "$ret" -eq 0 ]; then
  echo "=== Verifier: PASS ==="
else
  echo "=== Verifier: FAIL ==="; exit 2
fi
