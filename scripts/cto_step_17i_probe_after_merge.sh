#!/usr/bin/env bash
set -Eeuo pipefail
URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
mkdir -p ./.cto_logs
TS="$(date -u +%Y%m%d_%H%M%S)"
LOG="./.cto_logs/courses_prod_probe_${TS}.log"

probe() {
  local path="$1"; local needle="$2"
  local limit=80; local sleep_s=10
  for i in $(seq 1 $limit); do
    local t=$(date +%s)
    local body code
    body="$(curl -fsSL "$URL$path?nocache=$t" -H 'Cache-Control: no-cache' 2>>"$LOG" || true)"
    code="$([ -n "$body" ] && echo 200 || curl -s -o /dev/null -w '%{http_code}' "$URL$path?nocache=$t" 2>>"$LOG")"
    if [ "$code" = "200" ] && echo "$body" | grep -qi "$needle"; then
      echo "Probe $path: PASS"; return 0
    fi
    sleep $sleep_s
  done
  echo "Probe $path: FAIL (timeout)"; return 1
}

echo "Probing $URL … (log: $LOG)"
R1="$(probe "/courses" "Courses")" || true
R2="$(probe "/courses/getting-started" "Getting Started with the AI Tutor")" || true

echo "=== CTO PROD PROBE SUMMARY START ==="
echo "Prod URL: $URL"
echo "$R1"
echo "$R2"
echo "Log: $LOG"
echo "=== CTO PROD PROBE SUMMARY END ==="


