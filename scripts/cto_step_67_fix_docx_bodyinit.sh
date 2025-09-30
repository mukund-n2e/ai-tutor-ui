#!/usr/bin/env bash
set -euo pipefail
BR="wp024-fix-export-docx-bodyinit-$(date -u +%Y%m%d_%H%M%S)"
FILE="web/src/app/api/export/docx/route.ts"

[ -f "$FILE" ] || { echo "Missing $FILE"; exit 1; }

# Replace `return new Response(buf, …)` with Uint8Array body
node - <<'NODE'
const fs=require('fs');const p='web/src/app/api/export/docx/route.ts';
let s=fs.readFileSync(p,'utf8'), b=s;
if (/new Response\(\s*buf\s*,/.test(s)) {
  s=s.replace(/return\s+new\s+Response\(\s*buf\s*,/,
              'const u8 = new Uint8Array(buf);\n    return new Response(u8,');
} else {
  // Fallback: inject u8 after Packer and force Response(u8,…)
  s=s.replace(/const\s+buf\s*=\s*await\s+Packer\.toBuffer\(doc\);\s*/,'$&\n    const u8 = new Uint8Array(buf);\n');
  s=s.replace(/return\s+new\s+Response\(\s*([^)]+)\s*,/, 'return new Response(u8,');
}
if (s!==b){fs.writeFileSync(p,s);console.log('patched');} else {console.log('no-change');}
NODE

git checkout -b "$BR"
git add "$FILE"
git commit -m "fix(export): use Uint8Array for Response body (BodyInit) instead of Buffer"
git push -u origin "$BR" >/dev/null 2>&1 || git push -u origin "$BR"
gh pr create --fill --base main --head "$BR"
