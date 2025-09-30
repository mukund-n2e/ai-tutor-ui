#!/usr/bin/env bash
set -euo pipefail

# Simple guard: prevent banned patterns in core
paths="src/components src/app"
if git diff --cached --name-only | grep -E "^(src/components|src/app)"; then
  if git diff --cached -U0 | grep -E '\+.*style=\{\{|\+.*bg-white|\+.*gray-50|\+.*gray-100'; then
    echo "❌ Banned styles detected in staged changes. Fix before committing."
    exit 1
  fi
fi

echo "✅ Pre-commit guard passed."
