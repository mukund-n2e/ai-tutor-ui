// web/src/app/page.tsx
import Link from "next/link";

export default function Page() {
  return (
    <>
      <section className="hero">
        <p className="eyebrow">AI Tutor</p>
        <h1>
          Learn and apply AI to your job. No fluff.
        </h1>
        <p className="subhead">
          Pick a job task. We&apos;ll guide three decisive moves, validate, and you&apos;re done.
        </p>

        <div className="cta-row">
          <Link href="/onboarding/role" className="btn btn-primary" aria-label="Start onboarding">
            Try the tutor
          </Link>
          <Link href="/samples" className="btn btn-secondary" aria-label="Watch a quick demo">
            Watch demo
          </Link>
        </div>

        <ul className="chips">
          <li className="chip">Step‑by‑step hints</li>
          <li className="chip">Socratic questions</li>
          <li className="chip">Code explanations</li>
          <li className="chip">Citations & sources</li>
          <li className="chip">LaTeX & markdown</li>
          <li className="chip">Progress‑aware</li>
        </ul>
      </section>

      <footer className="footer">
        <div className="container footer-inner">
          <div>© {new Date().getFullYear()} AI Tutor</div>
          <div>Incognito by default. Nothing saved unless you say so.</div>
        </div>
      </footer>
    </>
  );
}
