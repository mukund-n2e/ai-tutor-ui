#!/usr/bin/env bash
set -Eeuo pipefail
APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
mkdir -p ./.cto_logs

# Ensure we're on clean main
git fetch origin --prune --quiet
git switch -C main >/dev/null 2>&1 || git checkout -B main
git reset --hard origin/main

# New tiny branch
TS="$(date -u +%Y%m%d_%H%M%S)"
BR="redeploy-${TS}"
git switch -C "$BR"

# Harmless touch in public/ to trigger a build
mkdir -p "$APP_DIR/public"
echo "redeploy ${TS}" > "$APP_DIR/public/.vercel_redeploy.txt"
git add "$APP_DIR/public/.vercel_redeploy.txt"
git commit -m "chore: trigger Vercel deploy (${TS})" >/dev/null

# Push
git push -u origin "$BR" --force-with-lease >/dev/null 2>&1 || true

# Build PR/Compare URL from remote
REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac

# If gh is available, create PR; otherwise print compare link
PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr create --head "$BR" --title "chore: trigger Vercel deploy (${TS})" --body "Tiny change in public/ to kick a Vercel Git deploy." 2>/dev/null | tail -n1)"
fi

echo "=== CTO REDEPLOY PR SUMMARY START ==="
echo "Branch: $BR"
[ -n "$PR_URL" ] && echo "PR: $PR_URL"
[ -z "$PR_URL" ] && [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "Action: Merge the PR in the browser (Squash + delete branch)."
echo "=== CTO REDEPLOY PR SUMMARY END ==="


