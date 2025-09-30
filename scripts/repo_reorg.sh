#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=${DRY_RUN:-true}

say() { echo "[$(date +%H:%M:%S)] $*"; }
doit() { $DRY_RUN && echo "(dry) $*" || eval "$@"; }

# Use git mv when the source is tracked; otherwise fall back to plain mv
is_tracked() { git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; }
mv_smart() {
  local src="$1" dst="$2"
  if is_tracked "$src"; then
    git mv -f "$src" "$dst"
  else
    mv -f "$src" "$dst"
  fi
}

ROOT="$(pwd)"
say "Repo reorg starting (DRY_RUN=$DRY_RUN)"

# 1) Create canonical layout
for d in "design/frames/landing" "design/specs" "design" \
         "public/assets" \
         "apps/web/app/(marketing)" "apps/web/components" "apps/web/styles" \
         "tests/e2e" "scripts" "archive"; do
  [ -d "$d" ] || doit "mkdir -p '$d'"
done

# 2) Move CSS variables (keep tokens as source of truth)
if [ -f "AI-Tutor-CSSVariables.css" ]; then
  doit "mv_smart 'AI-Tutor-CSSVariables.css' 'apps/web/styles/tokens.css'"
fi
if [ -f "AI-Tutor-DesignTokens.json" ]; then
  doit "mv_smart 'AI-Tutor-DesignTokens.json' 'design/DesignTokens.json'"
fi

# 3) Move asset manifest & icons/logo if found
for f in AI-Tutor-AssetManifest.json asset-manifest.json; do
  [ -f "$f" ] && doit "mv_smart '$f' 'design/AI-Tutor-AssetManifest.json'"
done
for f in ai-tutor-logo.svg play-icon.svg check-circle-icon.svg clock-icon.svg; do
  if [ -f "$f" ]; then
    doit "mv_smart '$f' 'public/assets/$f'"
  fi
done

# 4) Move Figma exports (PNGs) into frames folder if at root
for f in landing-360.png landing-768.png landing-1200.png; do
  if [ -f "$f" ]; then
    doit "mv_smart '$f' 'design/frames/landing/$f'"
  fi
done

# 5) Scripts hygiene — move all .sh to scripts/
find . -maxdepth 1 -type f -name "*.sh" ! -path "./scripts/*" -print0 | while IFS= read -r -d '' f; do
  doit "mv_smart '$f' 'scripts/'"
done

# 6) Duplicate file detection (by hash); keep first, move dupes to archive/dupes
mkdir -p archive/dupes
say "Scanning for duplicate files…"
# Use portable hashing (shasum exists on macOS); handle spaces via NUL delimiters
# Only hash files that currently exist to avoid errors on deleted-but-tracked paths
git ls-files -z | while IFS= read -r -d '' f; do
  if [ -e "$f" ]; then
    shasum -a 256 "$f"
  fi
done | sort | awk '{print $1 " " $2}' | \
awk '{ if (seen[$1]++) print $2; else keep[$1]=$2 }' | while read -r dup; do
    # Skip node_modules, build artifacts, and anything already in archive/dupes
    case "$dup" in
      *node_modules*|*.map|*.lock|*.log|archive/dupes/*) continue ;;
    esac
    doit "mv_smart '$dup' 'archive/dupes/'"
done

# 7) Move obsolete figma/spec dumps to archive (heuristic)
for d in figma old_designs legacy_screens; do
  [ -d "$d" ] && doit "git mv -f '$d' 'archive/$d'"
done

say "Reorg complete. Review changes, then commit:"
say "  git status && git add -A && git commit -m 'repo: normalized layout, moved dupes to archive'"
