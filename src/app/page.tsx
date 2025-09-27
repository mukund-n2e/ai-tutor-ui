import Link from 'next/link';

export default function LandingPage() {
  const verbs = ['Create', 'Automate', 'Analyze', 'Decide', 'Personalize', 'Connect'];
  return (
    <main className="mx-auto max-w-3xl p-6">
      <section className="rounded-2xl border border-orange-100 bg-orange-50/60 px-6 py-10 text-center">
        <h1 className="text-4xl font-bold tracking-tight">
          Learn and apply AI to your job. No fluff.
        </h1>
        <p className="mt-3 text-lg text-gray-600">
          Pick a job task. We&apos;ll guide three decisive moves, validate, and you&apos;re done.
        </p>

        <div className="mt-6 flex flex-col sm:flex-row gap-3 justify-center">
          <Link
            href="/onboarding/role"
            className="inline-flex items-center justify-center rounded-md px-5 py-3 font-medium bg-orange-500 text-white hover:bg-orange-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2"
            data-testid="cta-start-from-work"
          >
            Start from your work
          </Link>
          <Link
            href="/samples"
            className="inline-flex items-center justify-center px-5 py-3 font-medium underline"
            data-testid="cta-try-a-sample"
          >
            Try a sample
          </Link>
        </div>
      </section>

      <div className="mt-8 flex flex-wrap gap-2" aria-label="verbs">
        {verbs.map(v => (
          <span
            key={v}
            className="select-none rounded-full border px-3 py-1 text-sm"
            data-testid={`verb-chip-${v}`}
            aria-disabled="true"
          >
            {v}
          </span>
        ))}
      </div>

      <footer className="mt-12 text-sm text-gray-500">
        Incognito by default. Nothing saved unless you say so.
      </footer>
    </main>
  );
}
