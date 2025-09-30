#!/usr/bin/env bash
set -Eeuo pipefail
BR="wp008-courses-clean"

# Build PR URL from repo remote
REMOTE="$(git remote get-url origin 2>/dev/null || echo "")"
REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac
PR_URL="${GH_URL:+$GH_URL/pull/16}"

STATE="UNKNOWN"

if command -v gh >/dev/null 2>&1; then
  # Prefer discovering the PR by branch (in case the number changes)
  URL="$(gh pr list --head "$BR" --json url -q '.[0].url' 2>/dev/null || true)"
  [ -n "$URL" ] && PR_URL="$URL"

  # Approve + try to squash-merge; fall back gracefully
  gh pr review "$BR" --approve >/dev/null 2>&1 || true
  gh pr merge  "${PR_URL:-$BR}" --squash --admin --delete-branch -y >/dev/null 2>&1 || \
  gh pr merge  "${PR_URL:-$BR}" --squash --delete-branch -y >/dev/null 2>&1 || true

  # Check state
  STATE="$(gh pr view "${PR_URL:-$BR}" --json state -q .state 2>/dev/null || echo "UNKNOWN")"
else
  STATE="CLI_NOT_AVAILABLE"
fi

echo "=== CTO MERGE ONLY SUMMARY START ==="
echo "PR: ${PR_URL:-<unknown>}"
echo "State: ${STATE}"
[ "$STATE" != "MERGED" ] && echo "If not merged, open the PR above and click 'Squash and merge' (check 'Delete branch')."
echo "=== CTO MERGE ONLY SUMMARY END ==="


