#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-/Users/mt/n2e-AI-tutor}"
cd "$REPO_DIR"

if [[ ! -d .git ]]; then
  echo "Not a git repo at $REPO_DIR" >&2; exit 1
fi
if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found" >&2; exit 1
fi

OWNER=$(gh repo view --json owner -q .owner.login)
REPO=$(gh repo view --json name -q .name)
BRANCH=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo main)

echo "== Harden branch protection on $OWNER/$REPO@$BRANCH =="

# Fetch existing required contexts; fallback to our two PR checks if empty
CTX_FILE=$(mktemp)
if ! gh api -X GET "repos/$OWNER/$REPO/branches/$BRANCH/protection/required_status_checks/contexts" >"$CTX_FILE" 2>/dev/null; then
  printf '%s' '[]' >"$CTX_FILE"
fi

PROTECT_JSON_FILE=$(mktemp)
python3 - "$CTX_FILE" >"$PROTECT_JSON_FILE" <<'PY'
import json, sys
ctx_path = sys.argv[1]
try:
    with open(ctx_path, 'r', encoding='utf-8') as f:
        ctx = json.load(f)
except Exception:
    ctx = []
if not isinstance(ctx, list):
    ctx = []
for x in ["PR checks (lint + tests) / lint", "PR checks (lint + tests) / tests"]:
    if x not in ctx:
        ctx.append(x)
payload = {
  "required_status_checks": {"strict": True, "contexts": ctx},
  "enforce_admins": True,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": True,
    "require_code_owner_reviews": False,
    "required_approving_review_count": 1
  },
  "restrictions": None,
  "required_linear_history": True,
  "allow_force_pushes": False,
  "allow_deletions": False,
  "required_conversation_resolution": True
}
print(json.dumps(payload))
PY

echo "== Apply protection JSON =="
gh api -X PUT "repos/$OWNER/$REPO/branches/$BRANCH/protection" \
  -H "Accept: application/vnd.github+json" \
  --input "$PROTECT_JSON_FILE" >/dev/null

echo "== Verify protection summary =="
gh api "repos/$OWNER/$REPO/branches/$BRANCH/protection" -q '{required_status_checks,enforce_admins,required_pull_request_reviews,required_linear_history,allow_force_pushes,allow_deletions,required_conversation_resolution}' | jq .

# Log
TS=$(date -u +"%Y-%m-%d %H:%M UTC")
printf -- "- %s — Branch protection hardened on %s (strict, 1 review, resolve conv, admin enforce, linear history, no force-push/delete) — @cursor\n" "$TS" "$BRANCH" >> docs/LOG.md || true
git add docs/LOG.md && git commit -m "docs(log): harden branch protection for $BRANCH" || true
git push || true

echo "Done."


