#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

BR="wp025-prod-trigger-$(date -u +%Y%m%d_%H%M%S)"
FILE="web/public/_deploy-trigger-$(date -u +%Y%m%d_%H%M%S).txt"

mkdir -p web/public
echo "deploy $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$FILE"

git checkout -b "$BR"
git add "$FILE"
git commit -m "chore(deploy): bump version marker to trigger Vercel Git build"
git push -u origin "$BR"

gh pr create --fill --base main --head "$BR"
