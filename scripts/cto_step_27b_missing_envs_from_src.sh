#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel env pull "$TMP/prod.env" --environment=production --scope "$TEAM" >/dev/null

# Only scan source, avoid .next/node_modules noise
grep -RhoE 'process\.env\.[A-Z0-9_]+' web/src 2>/dev/null \
  | sed 's/.*process\.env\.//' | sort -u > "$TMP/keys_used.txt"

awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/{print $1}' "$TMP/prod.env" | sort -u > "$TMP/keys_have.txt"

echo "MISSING:"
comm -23 "$TMP/keys_used.txt" "$TMP/keys_have.txt" || true
