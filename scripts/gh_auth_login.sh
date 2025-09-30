#!/usr/bin/env bash
set -Eeuo pipefail

# Requires a GitHub token with: repo, workflow
# Reads from $GH_TOKEN or $GITHUB_TOKEN, or prompts securely

command -v gh >/dev/null || {
  echo "ERROR: gh CLI not found. On macOS: brew install gh" >&2
  exit 1
}

TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
  read -r -s -p "Paste GitHub token (scopes: repo, workflow): " TOKEN
  echo
fi

printf "%s" "$TOKEN" | gh auth login --hostname github.com --with-token
gh config set git_protocol https

echo "== Auth status =="
gh auth status