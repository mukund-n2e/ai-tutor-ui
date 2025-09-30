#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

ROOT="web/src/app/layout.tsx"
BR="wp032-body-beta-$(date -u +%Y%m%d_%H%M%S)"
[ -f "$ROOT" ] || { echo "Missing $ROOT"; exit 1; }

# Inject data-ssr-beta="true" directly on the <body ...> tag if not present
node - <<'NODE'
const fs=require('fs'); const p='web/src/app/layout.tsx';
let s=fs.readFileSync(p,'utf8'), b=s;
if(!/data-ssr-beta/.test(s)){
  s=s.replace(/<body([^>]*)>/, (m,attrs)=>`<body data-ssr-beta="true"\${attrs}>`);
}
if(s!==b){ fs.writeFileSync(p,s); console.log('patched'); } else { console.log('no-change'); }
NODE

git checkout -b "$BR"
git add "$ROOT"
git commit -m "chore(beta): add SSR beta marker on <body> so all routes inherit it"
git push -u origin "$BR"
gh pr create --fill --base main --head "$BR"
