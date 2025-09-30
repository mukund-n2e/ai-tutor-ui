#!/usr/bin/env bash
set -Eeuo pipefail

APP_FILES=(
  web/src/components/TopNav.tsx
  web/src/app/robots.ts
  web/src/app/sitemap.ts
  .github/workflows/nightly-prod-probe.yml
)

TS=20250917_033117
BR=wp012-wrapups-

# Clean any stray files from earlier interruptions
rm -f -- ./200 
