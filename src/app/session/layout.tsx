import BetaBadge from '@/components/BetaBadge';

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
