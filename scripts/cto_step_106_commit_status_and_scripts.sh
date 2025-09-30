#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

BR="wp038-status-and-scripts-$(date -u +%Y%m%d_%H%M%S)"
git checkout -B "$BR" >/dev/null

# Stage the status note and any cto_step scripts you created
git add docs/Status.md cto_step_*.sh || true

# Commit only if there are changes
if git diff --cached --quiet; then
  echo "NO_CHANGES"
  exit 0
fi

git commit -m "chore: record Vercel/alias status and add helper scripts"
git push -u origin "$BR"

# Open PR and merge it
gh pr create --fill --base main --head "$BR"
gh pr merge --squash --delete-branch


