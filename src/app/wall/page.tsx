import Header from '../../components/Header';
import '../../styles/tokens.css';

export default function Wall() {
  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Header />
      <main className="pt-[var(--header-height)]">
        <div className="mx-auto max-w-[1200px] px-4 py-8">
          <h1 className="text-2xl font-bold text-[var(--text-high)] mb-4">Pick a quick win</h1>
          <p className="text-[var(--text-mid)] mb-8">One skill. One small win. About 15 minutes.</p>
          <div className="text-[var(--text-low)]">Courses will appear here.</div>
        </div>
      </main>
    </div>
  );
}
