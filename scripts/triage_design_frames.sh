#!/usr/bin/env bash
set -euo pipefail

echo "== Repo root =="
git rev-parse --show-toplevel

echo; echo "== Current branch/status =="
git status -sb

echo; echo "== 1) PNGs on disk (anywhere) =="
find . -type f -iname "*.png" | sort || true

echo; echo "== 2) PNGs tracked in Git =="
git ls-files "*.png" | sort || true

echo; echo "== 3) Untracked PNGs =="
git ls-files --others --exclude-standard | grep -i '\.png$' || true

echo; echo "== 4) Deletions/Renames in last 48h (PNGs) =="
git log --since="48 hours ago" --name-status --diff-filter=DR -- '*.png' || true

echo; echo "== 5) Any history for design/frames =="
git log --full-history --name-status -- design/frames || echo "No commits reference design/frames"

echo; echo "== 6) Stash entries touching design/frames =="
for i in $(git stash list | nl -w2 -s: | cut -d: -f1); do
  if git stash show -p "stash@{$i}" -- design/frames >/dev/null 2>&1; then
    echo "Found in stash@{$i}"
  fi
done

echo; echo "== 7) Where did design/frames go (filesystem)? =="
ls -la design || echo "design/ not present"
ls -la design/frames || echo "design/frames not present"

echo; echo "== 8) Grep for any references to old frame filenames (if you know some names) =="
# Example: adjust patterns you remember
grep -RIn "Onboarding.*360" -- . || true
