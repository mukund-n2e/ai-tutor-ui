#!/usr/bin/env bash
set -euo pipefail

URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

echo "== Brand & Core Probes =="
paths=(
  "/"
  "/api/health"
  "/api/tutor/stream"
  "/brand/logo.svg"
  "/brand/favicon.svg"
  "/brand/apple-touch-icon.png"
)
for p in "${paths[@]}"; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" "${URL}${p}?ts=$(date +%s)" || echo 000)
  echo "$p -> $code"
done

echo "== Home contains brand markup =="
home=$(curl -fsSL "${URL}/?ts=$(date +%s)" || true)
if echo "$home" | grep -qi 'class="brand"\|/brand/logo.svg\|Nudge2Edge'; then
  echo "brand markup: FOUND"
else
  echo "brand markup: NOT FOUND"
fi



