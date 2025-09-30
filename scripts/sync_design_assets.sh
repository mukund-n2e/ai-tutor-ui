#!/usr/bin/env bash
set -euo pipefail

SRC="design/frames"
DST="web/public/design/expected"

mkdir -p "$DST"
rsync -a --delete "$SRC"/ "$DST"/
echo "Synced $SRC -> $DST"


