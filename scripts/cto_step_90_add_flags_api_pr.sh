#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

BR="wp034-flags-api-$(date -u +%Y%m%d_%H%M%S)"
FILE="web/src/app/api/flags/route.ts"

mkdir -p "$(dirname "$FILE")"
cat > "$FILE" <<'TS'
export const dynamic = 'force-dynamic';

export async function GET() {
  return Response.json(
    {
      beta: true,
      moves: ['Understand', 'Draft', 'Polish'],
      version: process.env.VERCEL_GIT_COMMIT_SHA ?? null,
      ts: new Date().toISOString(),
    },
    { headers: { 'Cache-Control': 'no-store' } }
  );
}
TS

git checkout -b "$BR"
git add "$FILE"
git commit -m "feat(api): /api/flags to expose beta + moves for monitors"
git push -u origin "$BR"

gh pr create --fill --base main --head "$BR"
