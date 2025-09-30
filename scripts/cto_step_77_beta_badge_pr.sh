#!/usr/bin/env bash
set -euo pipefail
BR="wp027-beta-badge-$(date -u +%Y%m%d_%H%M%S)"

# 1) Reusable badge (client component; SSR markup still renders)
mkdir -p web/src/components
cat > web/src/components/BetaBadge.tsx <<'TS'
'use client';
export default function BetaBadge() {
  return (
    <div data-ssr-beta="true" style={{
      position:'fixed', top:12, right:12, zIndex:1000,
      padding:'6px 10px', borderRadius:999,
      background:'#fff7ed', color:'#9a3412',
      border:'1px solid #fed7aa', fontSize:12, fontWeight:600,
      boxShadow:'0 1px 2px rgba(0,0,0,0.06)'
    }}>
      BETA
    </div>
  );
}
TS

# 2) Onboarding layout wrapper that adds the badge
mkdir -p web/src/app/onboarding
cat > web/src/app/onboarding/layout.tsx <<'TS'
import BetaBadge from '@/src/components/BetaBadge';
export default function OnboardingLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      <BetaBadge />
    </>
  );
}
TS

# 3) Session layout: keep SSR 3-move marker and add badge
mkdir -p web/src/app/session
cat > web/src/app/session/layout.tsx <<'TS'
import BetaBadge from '@/src/components/BetaBadge';

export default function SessionLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      {/* Hidden SSR marker for 3-move verification */}
      <div data-ssr-moves="Understand Draft Polish" style={{ display: 'none' }}>
        Understand Draft Polish
      </div>
      <BetaBadge />
    </>
  );
}
TS

git checkout -b "$BR"
git add web/src/components/BetaBadge.tsx web/src/app/onboarding/layout.tsx web/src/app/session/layout.tsx
git commit -m "chore(beta): show BETA badge on Onboarding & Session (SSR-visible marker)"
git push -u origin "$BR"
gh pr create --fill --base main --head "$BR"
