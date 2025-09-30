import Header from '../../../components/Header';
import '../../../styles/tokens.css';

export default function LessonL105() {
  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Header />
      <main className="pt-[var(--header-height)]">
        <div className="mx-auto max-w-[1200px] px-4 py-8">
          <h1 className="text-2xl font-bold text-[var(--text-high)] mb-4">Rescue your inbox</h1>
          <p className="text-[var(--text-mid)] mb-8">Learn to tame email overload with AI-powered strategies.</p>
          <div className="space-y-4">
            <div className="p-4 border border-[var(--border)] rounded-[var(--radius-card)]">
              <h2 className="text-lg font-semibold text-[var(--text-high)] mb-2">Lesson Content</h2>
              <p className="text-[var(--text-mid)]">Interactive lesson content will appear here.</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
