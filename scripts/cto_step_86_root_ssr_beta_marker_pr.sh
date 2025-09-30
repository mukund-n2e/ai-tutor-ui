#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

ROOT="web/src/app/layout.tsx"
BR="wp031-root-ssr-beta-$(date -u +%Y%m%d_%H%M%S)"

[ -f "$ROOT" ] || { echo "Missing $ROOT"; exit 1; }

# Inject a hidden SSR beta marker immediately after the first {children}
node - <<'NODE'
const fs = require('fs'); const p = 'web/src/app/layout.tsx';
let s = fs.readFileSync(p,'utf8'); const before = s;
if (!/data-ssr-beta/.test(s) && /\{children\}/.test(s)) {
  s = s.replace(/\{children\}/, `{children}
        {/* SSR beta marker for monitors */}
        <div data-ssr-beta="true" style={{ display: 'none' }}>BETA</div>`);
}
if (s !== before) { fs.writeFileSync(p, s); console.log('patched'); } else { console.log('no-change'); }
NODE

git checkout -b "$BR"
git add "$ROOT"
git commit -m "chore(beta): add SSR beta marker in root layout so all routes inherit it"
git push -u origin "$BR"
gh pr create --fill --base main --head "$BR"
