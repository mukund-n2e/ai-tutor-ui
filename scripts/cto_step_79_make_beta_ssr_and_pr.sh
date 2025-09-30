#!/usr/bin/env bash
set -euo pipefail
BR="wp028-beta-ssr-$(date -u +%Y%m%d_%H%M%S)"
FILE="web/src/components/BetaBadge.tsx"

# Fail fast if file missing
[ -f "$FILE" ] || { echo "Missing $FILE"; exit 1; }

# Remove 'use client' so the component is server-rendered (SSR-visible attribute)
if grep -q "^'use client';" "$FILE" || grep -q '^"use client";' "$FILE"; then
  sed -i.bak -e "s/^'use client';//" -e 's/^"use client";//' "$FILE" && rm -f "$FILE.bak"
fi

git checkout -b "$BR"
git add "$FILE"
git commit -m "chore(beta): render BetaBadge on the server so data-ssr-beta is visible in SSR"
git push -u origin "$BR"

gh pr create --fill --base main --head "$BR"
