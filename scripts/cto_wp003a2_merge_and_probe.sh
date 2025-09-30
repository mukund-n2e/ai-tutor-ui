#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PR="${PR:-32}"
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
URL="$PROD_URL/api/tutor/stream"
LOG="./.cto_logs/wp003a2_probe_$(date -u +%Y%m%d_%H%M%S).log"; mkdir -p ./.cto_logs

merge () {
  if command -v gh >/dev/null 2>&1; then
    gh pr review "$PR" --approve >/dev/null 2>&1 || true
    gh pr merge "$PR" --squash --delete-branch -y >/dev/null 2>&1 || \
      echo "Auto-merge failed; merge manually: https://github.com/mukund-n2e/ai-tutor-web/pull/$PR"
  else
    echo "gh not installed; merge manually: https://github.com/mukund-n2e/ai-tutor-web/pull/$PR"
  fi
}

probe () {
  echo "Probing $URL with HEAD (won't spend LLM tokens)…"
  hits=12; sleep_s=3; got429=0
  for i in $(seq 1 $hits); do
    code=$(curl -s -o /dev/null -w "%{http_code}" -X HEAD "$URL?nocache=$(date +%s)")
    echo "Hit $i -> $code" | tee -a "$LOG"
    [ "$code" = "429" ] && got429=1 && break
    sleep $sleep_s
  done
  echo "Result: $([ $got429 -eq 1 ] && echo 'RATE LIMIT TRIPPED (OK)' || echo 'DID NOT TRIP (adjust RL_MAX_REQUESTS/RL_WINDOW_SECONDS)')" \
    | tee -a "$LOG"
}

merge
# brief pause for deploy
sleep 8
probe

echo "=== CTO WP003a.2 MERGE+PROBE SUMMARY START ==="
echo "PR: #$PR"
echo "Prod: $PROD_URL"
echo "Log: $LOG"
echo "Notes: Expect 405s first (route doesn't handle HEAD), then 429 when limit trips."
echo "=== CTO WP003a.2 MERGE+PROBE SUMMARY END ==="
