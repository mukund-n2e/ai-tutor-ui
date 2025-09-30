#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

BR="wp029-ssr-beta-marker-$(date -u +%Y%m%d_%H%M%S)"

# Onboarding layout: ensure SSR beta marker
mkdir -p web/src/app/onboarding
cat > web/src/app/onboarding/layout.tsx <<'TS'
import BetaBadge from '@/src/components/BetaBadge';

export default function OnboardingLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      {/* SSR-visible beta marker for monitors */}
      <div data-ssr-beta="true" style={{ display: 'none' }}>BETA</div>
      <BetaBadge />
    </>
  );
}
TS

# Session layout: keep SSR moves marker, add SSR beta marker
mkdir -p web/src/app/session
cat > web/src/app/session/layout.tsx <<'TS'
import BetaBadge from '@/src/components/BetaBadge';

export default function SessionLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      {/* Hidden SSR markers for monitors */}
      <div data-ssr-moves="Understand Draft Polish" style={{ display: 'none' }}>
        Understand Draft Polish
      </div>
      <div data-ssr-beta="true" style={{ display: 'none' }}>BETA</div>
      <BetaBadge />
    </>
  );
}
TS

git checkout -b "$BR"
git add web/src/app/onboarding/layout.tsx web/src/app/session/layout.tsx
git commit -m "chore(beta): add SSR-visible beta marker to onboarding & session layouts"
git push -u origin "$BR"

gh pr create --fill --base main --head "$BR"
