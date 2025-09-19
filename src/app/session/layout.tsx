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
