#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ROOT="web"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Ensure we’re pointing at the right project+team and pull PRODUCTION envs
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel env pull "$TMP/prod.env" --environment=production --scope "$TEAM" >/dev/null

# Collect env keys referenced in repo (SSE route included)
grep -RhoE 'process\.env\.[A-Z0-9_]+' "$ROOT" 2>/dev/null \
 | sed 's/.*process\.env\.//' | sort -u > "$TMP/keys_used.txt"

# Keys currently present in PRODUCTION
awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/{print $1}' "$TMP/prod.env" | sort -u > "$TMP/keys_have.txt"

echo "MISSING:"
comm -23 "$TMP/keys_used.txt" "$TMP/keys_have.txt" || true
