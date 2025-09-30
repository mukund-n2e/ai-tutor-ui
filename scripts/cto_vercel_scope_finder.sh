#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
need(){ command -v "$1" >/dev/null 2>&1; }
need vercel || { echo "vercel CLI not found"; exit 2; }

echo "Scopes (team slugs):"
vercel teams ls || true

echo
echo "Searching for projects named tutor_web or ai-tutor-web across scopes…"
while read -r slug _; do
  [ -z "$slug" ] && continue
  echo "— scope: $slug"
  vercel projects ls --scope "$slug" 2>/dev/null | grep -E '(^| )tutor_web|ai-tutor-web' || echo "  (none)"
done < <(vercel teams ls 2>/dev/null | awk 'NR>1{print $1, $2}')

echo
echo "If you find the right scope slug, run: vercel switch <slug>"



