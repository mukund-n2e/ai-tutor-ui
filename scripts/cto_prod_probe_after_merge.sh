#!/usr/bin/env bash
set -euo pipefail

URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

echo "== Current Prod Status =="
for p in "/" "/api/health" "/smoke" "/courses" "/courses/getting-started" "/tutor" "/api/tutor/stream"; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" "${URL}${p}?ts=$(date +%s)" || echo 000)
  echo "$p -> $code"
done



