#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BR="wp026-home-redirect-$(date -u +%Y%m%d_%H%M%S)"
FILE="web/src/app/page.tsx"

mkdir -p "$(dirname "$FILE")"
cat > "$FILE" <<'TS'
import { redirect } from 'next/navigation';

export default function Home() {
  redirect('/onboarding');
}
TS

git checkout -b "$BR"
git add "$FILE"
git commit -m "chore: redirect home to /onboarding to drop learners into PRD flow"
git push -u origin "$BR"

gh pr create --fill --base main --head "$BR"
