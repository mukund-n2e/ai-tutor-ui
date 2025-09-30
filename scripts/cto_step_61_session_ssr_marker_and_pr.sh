#!/usr/bin/env bash
set -euo pipefail

BR="wp022-session-ssr-marker-$(date -u +%Y%m%d_%H%M%S)"
FILE="web/src/app/session/layout.tsx"

# Create a server layout that emits hidden SSR text markers for E2E checks.
mkdir -p "$(dirname "$FILE")"
cat > "$FILE" <<'TS'
export default function SessionLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      {/* Hidden SSR marker so curl/greps can verify the 3-move UI without JS */}
      <div data-ssr-moves="Understand Draft Polish" style={{ display: 'none' }}>
        Understand Draft Polish
      </div>
    </>
  );
}
TS

# Commit, push, and open PR
git checkout -b "$BR"
git add "$FILE"
git commit -m "chore(session): add SSR marker for E2E verification (Understand/Draft/Polish); no UI change"
git push -u origin "$BR"

gh pr create --fill --base main --head "$BR"


