#!/usr/bin/env bash
set -euo pipefail
BASE="https://tutorweb-cyan.vercel.app"
echo "GET $BASE/api/flags"
curl -sS -D - -H 'Accept: application/json' "$BASE/api/flags" \
 | sed -n '1,200p'
