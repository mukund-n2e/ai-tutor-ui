#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

BR="wp035-fix-flags-404-$(date -u +%Y%m%d_%H%M%S)"
FILE="web/src/app/api/flags/route.ts"

# If the file is missing, create it; if present, ensure Node runtime and bump content to trigger build.
mkdir -p "$(dirname "$FILE")"
if [ ! -f "$FILE" ]; then
  cat > "$FILE" <<'TS'
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET() {
  return Response.json(
    {
      beta: true,
      moves: ['Understand','Draft','Polish'],
      ts: new Date().toISOString(),
    },
    { headers: { 'Cache-Control': 'no-store' } }
  );
}
TS
else
  # Prepend runtime if missing; also append a harmless comment to ensure a new commit.
  node - <<'NODE'
const fs=require('fs'); const p='web/src/app/api/flags/route.ts';
let s=fs.readFileSync(p,'utf8');
if(!/export const runtime\s*=/.test(s)){
  s = "export const runtime = 'nodejs';\n" + s;
}
s += "\n// bump: " + new Date().toISOString() + "\n";
fs.writeFileSync(p,s);
console.log('bumped', p);
NODE
fi

git checkout -b "$BR"
git add "$FILE"
git commit -m "fix(api): ensure /api/flags present + node runtime (force Git deploy)"
git push -u origin "$BR"

gh pr create --fill --base main --head "$BR"
