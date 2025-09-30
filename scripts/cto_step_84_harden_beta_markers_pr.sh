#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

BR="wp030-harden-beta-markers-$(date -u +%Y%m%d_%H%M%S)"

# 1) Inject data-ssr-beta into the existing SSR moves div on Session layout
SL="web/src/app/session/layout.tsx"
if [ -f "$SL" ]; then
  node - <<'NODE'
const fs = require('fs'); const p = 'web/src/app/session/layout.tsx';
let s = fs.readFileSync(p, 'utf8'), b = s;
if (!/data-ssr-beta=/.test(s) && /data-ssr-moves="/.test(s)) {
  s = s.replace(/data-ssr-moves="[^"]+"/, m => m + ' data-ssr-beta="true"');
}
if (s !== b) { fs.writeFileSync(p, s); console.log('patched session/layout'); } else { console.log('no-change session/layout'); }
NODE
else
  echo "WARN: missing $SL" >&2
fi

# 2) Add an SSR beta marker immediately after {children} in Onboarding layout
OL="web/src/app/onboarding/layout.tsx"
if [ -f "$OL" ]; then
  node - <<'NODE'
const fs = require('fs'); const p = 'web/src/app/onboarding/layout.tsx';
let s = fs.readFileSync(p, 'utf8'), b = s;
if (/\{children\}/.test(s) && !/data-ssr-beta/.test(s)) {
  s = s.replace(/\{children\}/, `{children}
      {/* SSR beta marker for monitors */}
      <div data-ssr-beta="true" style={{ display: 'none' }}>BETA</div>`);
}
if (s !== b) { fs.writeFileSync(p, s); console.log('patched onboarding/layout'); } else { console.log('no-change onboarding/layout'); }
NODE
else
  echo "WARN: missing $OL" >&2
fi

git checkout -b "$BR"
git add web/src/app/session/layout.tsx web/src/app/onboarding/layout.tsx || true
git commit -m "chore(beta): add SSR beta marker to reliable SSR elements (session moves div + onboarding layout)"
git push -u origin "$BR"

gh pr create --fill --base main --head "$BR"
