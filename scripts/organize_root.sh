#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=${DRY_RUN:-true}

echo "[organize] DRY_RUN=${DRY_RUN}"

mkdir -p docs design archive misc

keep_list="README.md LICENSE package.json package-lock.json Makefile render.yaml"
keep() {
  local item="$1"; for k in $keep_list; do [ "$item" = "$k" ] && return 0; done; return 1
}

is_tracked(){ git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; }
ensure_dir(){ [ -d "$1" ] || ($DRY_RUN && echo "(dry) mkdir -p '$1'" || mkdir -p "$1"); }
unique_path(){
  local dst="$1" base ext n=1 out="$dst"
  base="${dst%.*}"; ext="${dst##$base}"
  while [ -e "$out" ]; do out="${base}_$n${ext}"; n=$((n+1)); done
  printf '%s' "$out"
}
move() {
  local src="$1" dir="$2" name="${1##*/}" dst="$2/$name"
  ensure_dir "$dir"
  if [ -e "$dst" ]; then dst="$(unique_path "$dst")"; fi
  if $DRY_RUN; then
    echo "(dry) mv '$src' '$dst'"; return 0
  fi
  if is_tracked "$src"; then git mv -f "$src" "$dst" 2>/dev/null || mv -f "$src" "$dst"; else mv -f "$src" "$dst"; fi
}

find . -maxdepth 1 -type f ! -name ".*" -print0 | while IFS= read -r -d '' path; do
  f="${path#./}"
  if keep "$f"; then echo "[keep] $f"; continue; fi

  case "$f" in
    *.md)
      if [ "$f" = "README.md" ]; then echo "[keep] $f"; else echo "[docs] $f"; move "$f" docs/; fi ;;
    *.json)
      case "$f" in
        AI-Tutor-Design-Tokens_*.json|AI-Tutor-Frames-Config_*.json)
          echo "[design] $f"; move "$f" design/ ;;
        *.code-workspace)
          echo "[misc] $f"; move "$f" misc/ ;;
        ctov4-*.json)
          echo "[misc] $f"; move "$f" misc/ ;;
        *) echo "[misc] $f"; move "$f" misc/ ;;
      esac ;;
    *.css)
      echo "[design] $f"; move "$f" design/ ;;
    *.xz|*.zip|*.tar|*.tar.gz)
      echo "[archive] $f"; move "$f" archive/ ;;
    *)
      case "$f" in
        repo-lightview-*.txt.xz)
          echo "[archive] $f"; move "$f" archive/ ;;
        *) echo "[misc] $f"; move "$f" misc/ ;;
      esac ;;
  esac
done

echo "[organize] Done."
