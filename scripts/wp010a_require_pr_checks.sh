#!/usr/bin/env bash
set -euo pipefail

# Enforce repo root (defaults to local path you've locked earlier)
REPO="${REPO_DIR:-/Users/mt/n2e-AI-tutor}"
cd "$REPO"

if [[ ! -d .git ]]; then
  echo "Not a git repo at $REPO"; exit 1
fi

# Require GitHub CLI + auth
if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found — install https://cli.github.com/"; exit 1
fi
gh auth status -h github.com >/dev/null || { echo "gh not authenticated"; exit 1; }

# Resolve repo + branch
GH_REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
DEFAULT_BRANCH="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo main)"
BRANCH="${BRANCH:-$DEFAULT_BRANCH}"

# Read current required status checks contexts (array of strings). If none, start empty.
set +e
_resp=$(gh api -X GET "repos/$GH_REPO/branches/$BRANCH/protection/required_status_checks/contexts" 2>/dev/null)
_rc=$?
set -e
if [ ${_rc} -ne 0 ] || [ -z "${_resp:-}" ]; then
  EXISTING_JSON='[]'
else
  EXISTING_JSON="${_resp}"
fi

# The two job-level checks under the workflow "PR checks (lint + tests)"
WF="PR checks (lint + tests)"
declare -a NEW_CTX=(
  "$WF / lint"
  "$WF / tests"
)

# Merge (dedupe) existing + new via tiny Python (no external jq dependency)
TMP_CTX_FILE="$(mktemp)"
printf '%s' "$EXISTING_JSON" | python3 - "${NEW_CTX[@]}" > "$TMP_CTX_FILE" <<'PY'
import json, sys
existing_text = sys.stdin.read() or "[]"
try:
    existing = json.loads(existing_text) or []
except Exception:
    existing = []
add = sys.argv[1:]
seen, out = set(), []
for x in (existing or []) + add:
    if x and x not in seen:
        seen.add(x)
        out.append(x)
print("\n".join(out))
PY

# Apply contexts using the subresource endpoint (doesn't touch other protection knobs)
ARGS=(
  -X PUT "repos/$GH_REPO/branches/$BRANCH/protection/required_status_checks"
  -H "Accept: application/vnd.github+json"
  -f strict=true
)
while IFS= read -r ctx; do
  ARGS+=( -F "contexts[]=$ctx" )
done < "$TMP_CTX_FILE"

echo "Updating required status checks on $GH_REPO@$BRANCH ..."
# Try to update contexts via subresource; if branch is not protected, enable minimal protection.
set +e
UPDATE_OUT=$(gh api "${ARGS[@]}" 2>&1)
UPDATE_RC=$?
set -e
if [ ${UPDATE_RC} -ne 0 ] && echo "$UPDATE_OUT" | grep -qi 'Branch not protected'; then
  echo "Branch not protected — enabling minimal protection with required checks..."
  # Build JSON for branch protection with required status checks only
  CONTEXTS_JSON=$(python3 - "$TMP_CTX_FILE" <<'PY'
import json,sys
path=sys.argv[1]
with open(path,'r') as f:
    ctx=[line.strip() for line in f if line.strip()]
print(json.dumps(ctx))
PY
  )
  PROTECT_JSON=$(python3 - "$CONTEXTS_JSON" <<'PY'
import json,sys
ctx=json.loads(sys.argv[1])
payload={
  "required_status_checks": {"strict": True, "contexts": ctx},
  "enforce_admins": False,
  "required_pull_request_reviews": None,
  "restrictions": None
}
print(json.dumps(payload))
PY
  )
  printf '%s' "$PROTECT_JSON" | gh api -X PUT "repos/$GH_REPO/branches/$BRANCH/protection" -H "Accept: application/vnd.github+json" --input - >/dev/null
fi

echo "Final required checks:"
gh api -X GET "repos/$GH_REPO/branches/$BRANCH/protection/required_status_checks/contexts" 2>/dev/null | sed 's/^/ - /'

# Log to docs/LOG.md (best-effort)
ts="$(date -u +"%Y-%m-%d %H:%M UTC")"
printf -- "- %s — Branch protection: required checks → %s — @cursor\n" "$ts" "$WF (lint, tests)" >> docs/LOG.md || true
git add docs/LOG.md && git commit -m "docs(log): require $WF (lint, tests) on $BRANCH" || true
git push || true

echo "Done."


