#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

ROOT="web/src/app/layout.tsx"
BR="wp033-html-beta-$(date -u +%Y%m%d_%H%M%S)"
[ -f "$ROOT" ] || { echo "Missing $ROOT"; exit 1; }

# Inject data-ssr-beta="true" on the <html ...> tag if not already present
node - <<'NODE'
const fs=require('fs'); const p='web/src/app/layout.tsx';
let s=fs.readFileSync(p,'utf8'), b=s;
if(!/data-ssr-beta/.test(s)){
  s=s.replace(/<html\b([^>]*)>/i, (m, attrs)=>`<html data-ssr-beta="true"\${attrs}>`);
}
if(s!==b){ fs.writeFileSync(p,s); console.log('patched'); } else { console.log('no-change'); }
NODE

git checkout -b "$BR"
git add "$ROOT" || true
git commit -m "chore(beta): add SSR beta marker on <html> so every response carries it" || true
git push -u origin "$BR" || true
gh pr create --fill --base main --head "$BR"
