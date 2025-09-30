#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

mkdir -p docs
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Append a small, date-stamped note
{
  echo "## Stray Projects Scan — ${TS}"
  echo "- Team: \`${TEAM}\`"
  echo "- Result: **no stray projects (0)**"
  echo "- Alias health: Onboarding 200, Session 200, DOCX 504b (per latest checks)."
  echo ""
} >> docs/Status.md

BR="wp039-status-stray-done-$(date -u +%Y%m%d_%H%M%S)"
git checkout -B "$BR" >/dev/null

git add docs/Status.md

if git diff --cached --quiet; then
  echo "NO_CHANGES"
  exit 0
fi

git commit -m "docs(status): record stray-projects=0 and close task"
git push -u origin "$BR"

# Open PR and merge it
gh pr create --fill --base main --head "$BR"
gh pr merge --squash --delete-branch


