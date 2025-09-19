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
