import Header from '../../components/Header';
import '../../styles/tokens.css';

export default function Pricing() {
  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Header />
      <main className="pt-[var(--header-height)]">
        <div className="mx-auto max-w-[1200px] px-4 py-8">
          <h1 className="text-2xl font-bold text-[var(--text-high)] mb-4">Pick your level</h1>
          <p className="text-[var(--text-mid)]">AU/IN pricing with Stripe checkout</p>
        </div>
      </main>
    </div>
  );
}
