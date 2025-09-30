#!/usr/bin/env bash
set -euo pipefail
jq -r '.routes[]' design/manifest.ui.json >/dev/null || { echo 'manifest missing'; exit 1; }
missing=0
# Check files exist
jq -r '.files | to_entries[] | .value[]' design/manifest.ui.json | while read -r f; do
  if [ ! -f "$f" ]; then echo "MISSING: $f"; missing=1; fi
done
# Grep banned patterns in components and styles
! grep -R "style={{" web/src/components web/src/app 2>/dev/null | grep -v "web/src/legacy" || { echo 'Inline styles found'; exit 2; }
! grep -R "bg-white\|gray-50\|gray-100" web/src/components 2>/dev/null || { echo 'Raw utility colors found'; exit 3; }
! grep -R "rgba(" web/src/styles 2>/dev/null || { echo 'Raw rgba found in styles'; exit 4; }
# Routes existence (pages)
while read -r p; do
  count=$(find web/src/app -path "*/page.tsx" | sed 's#web/src/app##' | grep -c "^$p$\|^$p/.*")
  [ $count -ge 1 ] || { echo "ROUTE NOT FOUND: $p"; missing=1; }
done < <(jq -r '.routes[]' design/manifest.ui.json | sed 's#^/$#/page.tsx#; s#^/\(.*\)$#/*\1*/page.tsx#')
[ $missing -eq 0 ] || { echo 'Some files/routes missing'; exit 5; }
echo 'UI verification passed.'