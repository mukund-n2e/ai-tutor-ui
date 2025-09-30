#!/usr/bin/env bash
set -euo pipefail

VERCEL_TOKEN="${VERCEL_TOKEN:-}"
if [ -z "$VERCEL_TOKEN" ]; then
  VERCEL_TOKEN="$(cat ~/.vercel_token 2>/dev/null || true)"
fi
[ -n "$VERCEL_TOKEN" ] || { echo "set VERCEL_TOKEN" >&2; exit 2; }
TEAM_SLUG="${TEAM_SLUG:-ai-tutor-7f989507}"
PROJ="${PROJ:-ai-tutor-web}"

HDR=(-H "Authorization: Bearer $VERCEL_TOKEN" -H "Content-Type: application/json")

# 1) Resolve teamId by listing teams (supported). If not found, leave empty.
TEAM_ID="$(
  curl -fsSL "${HDR[@]}" "https://api.vercel.com/v2/teams?limit=200" \
  | jq -r --arg SLUG "$TEAM_SLUG" '.teams[]? | select(.slug==$SLUG) | .id' | head -n1
)"
echo "teamId=${TEAM_ID:-<none>}"

# 2) Resolve projectId
get_proj_id() {
  local url="https://api.vercel.com/v9/projects/${PROJ}"
  [ -n "${TEAM_ID:-}" ] && url="${url}?teamId=${TEAM_ID}"
  curl -fsSL "${HDR[@]}" "$url" | jq -r '.id'
}
if ! PROJ_ID="$(get_proj_id)"; then
  echo "projectId lookup with teamId failed; retrying without teamId…" >&2
  PROJ_ID="$(curl -fsSL "${HDR[@]}" "https://api.vercel.com/v9/projects/${PROJ}" | jq -r '.id')"
fi
echo "projectId=$PROJ_ID"

# 3) List prod deployments, pick latest READY/SUCCEEDED
CANDIDATE_DOMAIN="$(
  curl -fsSL "${HDR[@]}" \
    "https://api.vercel.com/v13/deployments?projectId=${PROJ_ID}&target=production&limit=50${TEAM_ID:+&teamId=${TEAM_ID}}" \
  | jq -r '
      .deployments
      | map(select(((.readyState // .state) | ascii_upcase) as $s | ($s=="READY" or $s=="SUCCEEDED")))
      | sort_by(.created) | last | .url // empty
    '
)"
test -n "$CANDIDATE_DOMAIN" || { echo "No READY prod deployments found" >&2; exit 2; }

CANDIDATE_URL="https://${CANDIDATE_DOMAIN}"
echo "candidate=$CANDIDATE_URL"


