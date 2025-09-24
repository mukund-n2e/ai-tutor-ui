'use client';
import { useRouter } from 'next/navigation';
import { useSessionStore } from '@/store/sessionStore';

const demoCourseFor = (role?: string, level?: string) => ({
  id: 'quickwin-demo',
  title: 'Quick Win for ' + (role ?? 'User'),
  heroMoves: [
    { id: 'm1', title: 'Understand' },
    { id: 'm2', title: 'Draft' },
    { id: 'm3', title: 'Polish' }
  ]
});

export default function OnboardingProposalPage() {
  const router = useRouter();
  const { role, level } = useSessionStore(s => s.profile);
  const setCourse = useSessionStore(s => s.setCourse);
  const startSession = useSessionStore(s => s.startSession);

  const course = demoCourseFor(role, level);
  const subtitle = `Curated for ${role ?? '—'} at Level ${level ?? '—'}`;

  async function onStart() {
    const res = await fetch('/api/session/start', {
      method: 'POST', headers: { 'Content-Type':'application/json' },
      body: JSON.stringify({ role, level, courseId: course.id })
    });
    if (!res.ok) return;
    const json = await res.json();
    setCourse({ id: course.id, title: course.title, heroMoves: course.heroMoves });
    startSession({ sessionId: json.sessionId, tokenCap: json.tokenCap, moves: json.moves ?? course.heroMoves });
    router.push('/session');
  }

  return (
    <main className="mx-auto max-w-3xl p-6">
      <h1 className="text-2xl font-semibold mb-2">Your Quick Win</h1>
      <p className="text-sm text-gray-600 mb-4">{subtitle}</p>
      <p className="text-xs text-gray-500 mb-6">Tools collected later.</p>

      <section className="mb-6">
        <h2 className="font-medium mb-2">Hero moves</h2>
        <ol className="list-decimal ml-5 space-y-1">
          {course.heroMoves.map(m => (
            <li key={m.id} data-testid="hero-move">{m.title}</li>
          ))}
        </ol>
      </section>

      <button className="px-4 py-2 rounded bg-black text-white mr-3" onClick={onStart}>Start</button>
      <button className="px-3 py-2 text-sm underline" onClick={()=>router.push('/courses')}>See other options</button>
    </main>
  );
}


