#!/usr/bin/env bash
set -Eeuo pipefail

TEAM_SLUG="${TEAM_SLUG:-ai-tutor-7f989507}"
PROJECT="${PROJ:-ai-tutor-web}"
ALIAS="${ALIAS:-tutorweb-cyan.vercel.app}"

# Token (env or ~/.vercel_token), sanitized
if [ -z "${VERCEL_TOKEN:-}" ]; then
  if [ -f "$HOME/.vercel_token" ]; then
    VERCEL_TOKEN="$(tr -d '\r\n"' < "$HOME/.vercel_token")"
    export VERCEL_TOKEN
  else
    echo "ERROR: VERCEL_TOKEN not set and ~/.vercel_token missing." >&2; exit 2
  fi
fi

echo "== Selecting READY candidates via CLI =="
RAW=$(vercel list "$PROJECT" --prod --scope "$TEAM_SLUG" --token $VERCEL_TOKEN 2>/dev/null | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g' || true)
if [ -z "$RAW" ]; then echo "ERROR: empty vercel list" >&2; exit 3; fi
echo "$RAW" | sed -n '1,24p'

# Iterate candidates found in table (newest first)
echo "$RAW" | while IFS= read -r line; do
  # Extract first https URL from the line (works for table rows or url-only lines)
  url=$(printf '%s\n' "$line" | awk '{for(i=1;i<=NF;i++) if($i ~ /^https:\/\//){print $i; exit}}')
  [ -z "$url" ] && continue
  CAND="$url"
  echo "candidate=$CAND"

  echo "== verify_base (candidate) =="
  if ! scripts/verify_base.sh "$CAND"; then
    echo "Candidate failed verify_base; trying next…" >&2
    continue
  fi

  echo "== Playwright (candidate) =="
  set +e
  BASE_URL="$CAND" npx --yes playwright test tests/acceptance.spec.ts --reporter=list | tee /tmp/pw_candidate.out
  PW_CODE=${PIPESTATUS[0]}
  set -e
  if [ $PW_CODE -ne 0 ]; then
    echo "Candidate failed E2E; trying next…" >&2
    continue
  fi

  echo "== Alias switch =="
  HOST_NO_SCHEME="${CAND#https://}"
  vercel alias set "$HOST_NO_SCHEME" "$ALIAS" --scope "$TEAM_SLUG" --token $VERCEL_TOKEN

  echo "== Alias cache-bust headers =="
  curl -sSI "https://$ALIAS/?__bust=$(date +%s)" | sed -n '1,20p'

  echo "== verify_base (alias) =="
  if ! scripts/verify_base.sh "https://$ALIAS"; then
    echo "Alias verify failed after promotion." >&2
    exit 10
  fi

  echo "== Playwright (alias) =="
  set +e
  BASE_URL="https://$ALIAS" npx --yes playwright test tests/acceptance.spec.ts --reporter=list | tee /tmp/pw_alias.out
  PW_ALIAS=${PIPESTATUS[0]}
  set -e
  if [ $PW_ALIAS -ne 0 ]; then
    echo "E2E failed on alias after promotion." >&2
    exit 11
  fi

  echo "== DONE: Promoted and verified =="
  exit 0
done

echo "ERROR: Exhausted READY candidates; none passed verification." >&2
exit 12
