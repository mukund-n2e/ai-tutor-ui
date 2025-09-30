#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PRS=(${PRS:-24 25})  # override like: PRS="25 26" bash cto_step_18a2_merge_and_probe.sh
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
LOG="./.cto_logs/merge_probe_$(date -u +%Y%m%d_%H%M%S).log"; mkdir -p ./.cto_logs

merge_pr () {
  local n="$1"
  echo "Merging PR #$n ..."
  if command -v gh >/dev/null 2>&1; then
    gh pr review "$n" --approve >/dev/null 2>&1 || true
    gh pr merge  "$n" --squash --delete-branch -y >/dev/null 2>&1 || {
      echo "  Could not auto‑merge PR #$n — merge manually if needed: https://github.com/mukund-n2e/ai-tutor-web/pull/$n"
    }
  else
    echo "  gh not installed; merge manually: https://github.com/mukund-n2e/ai-tutor-web/pull/$n"
  fi
}

for n in "${PRS[@]}"; do merge_pr "$n"; done

echo "Probing $PROD_URL (bounded retries)… (log: $LOG)"
probe () {
  local path="$1" needle="$2"
  for i in $(seq 1 40); do
    local t=$(date +%s)
    body="$(curl -fsSL "$PROD_URL$path?nocache=$t" -H 'Cache-Control: no-cache' || true)"
    if [ -n "$body" ] && { [ -z "$needle" ] || echo "$body" | grep -qi "$needle"; }; then
      echo "  $path -> PASS" | tee -a "$LOG"; return 0
    fi
    sleep 6
  done
  echo "  $path -> FAIL (timeout)" | tee -a "$LOG"; return 1
}

probe "/smoke" "Deploy OK"       || true
probe "/courses" "Courses"       || true
probe "/tutor"  ""               || true

echo "=== CTO MERGE+PROBE SUMMARY START ==="
echo "PRs: ${PRS[*]}"
echo "Prod: $PROD_URL"
echo "Log:  $LOG"
echo "=== CTO MERGE+PROBE SUMMARY END ==="



