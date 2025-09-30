#!/usr/bin/env bash
set -Eeuo pipefail
echo "=== PR Sanity Check: tokens.css, onboarding nav, lesson success tint ==="

fail=0

# 1) tokens.css has 64px header + success tint token
if grep -qE -- "--header-height:\s*64px" web/src/styles/tokens.css; then
  echo "✓ tokens.css: --header-height is 64px"
else
  echo "✗ tokens.css: --header-height not set to 64px"
  fail=1
fi
if grep -q -- "--feedback-success-tint" web/src/styles/tokens.css; then
  echo "✓ tokens.css: --feedback-success-tint token present"
else
  echo "✗ tokens.css: missing --feedback-success-tint"
  fail=1
fi

# 2) Onboarding page uses router.push (not window.location)
ob="web/src/app/onboarding/page.tsx"
if [ -f "$ob" ] && \
   grep -q "useRouter" "$ob" && \
   grep -q "router\.push(" "$ob" && \
   ! grep -q "window\.location" "$ob"; then
  echo "✓ onboarding: uses router.push()"
else
  echo "✗ onboarding: not using router.push() (or window.location present)"
  fail=1
fi

# 3) Lesson success banner uses token, not raw rgba
css="web/src/styles/lesson.module.css"
if [ -f "$css" ]; then
  if grep -q "background: var(--feedback-success-tint)" "$css" && \
     ! grep -q "rgba(5,\s*150,\s*105,\s*0\.1)" "$css"; then
    echo "✓ lesson: success banner uses tokenized success tint"
  else
    echo "✗ lesson: success banner still uses raw rgba or missing tokenized background"
    fail=1
  fi
else
  echo "… lesson.module.css not found (ok if that route isn't merged yet)"
fi

echo "=== Done ==="
exit $fail
