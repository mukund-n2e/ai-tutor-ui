#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(pwd)"
# Try common candidates within the repo first (fast)
CANDS="$(find "$ROOT" -maxdepth 2 -type d \( -iname "*design*" -o -iname "*figma*" -o -iname "*pack*" \) 2>/dev/null || true)"
# If none, also try the original hinted path as a fallback
[ -d "/Users/mt/n2e-AI-tutor/ai-tutor-design-pack-v5" ] && CANDS="$CANDS
/Users/mt/n2e-AI-tutor/ai-tutor-design-pack-v5"
best=""; best_count=0
for d in $CANDS; do
  [ -d "$d" ] || continue
  count="$(find "$d" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.svg" -o -iname "*.webp" \) 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${count:-0}" -gt "$best_count" ]; then best="$d"; best_count="$count"; fi
done
if [ -n "$best" ] && [ "$best_count" -ge 5 ]; then
  printf "%s\n" "$best"
  exit 0
fi
exit 1
