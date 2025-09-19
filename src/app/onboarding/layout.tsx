import BetaBadge from '@/src/components/BetaBadge';
export default function OnboardingLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      <BetaBadge />
    </>
  );
}
