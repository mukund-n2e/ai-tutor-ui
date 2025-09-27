// web/src/app/page.tsx
import Link from "next/link";

export default function Page() {
  return (
    <>
      <section className="hero">
        <p className="eyebrow">AI Tutor</p>
        <h1>
          Get unstuck fast—<span className="accent">learn by doing</span>.
        </h1>
        <p className="subhead">
          A focused AI tutor that gives hints, not answers. Socratic prompts,
          code-aware explanations, and citations so you trust what you learn.
        </p>

        <div className="cta-row">
          <Link href="/app" className="btn btn-primary" aria-label="Try the tutor">
            Try the tutor
          </Link>
          <Link href="/demo" className="btn btn-secondary" aria-label="Watch a quick demo">
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
          {/* Add links later if desired; keeping clean per request */}
        </div>
      </footer>
    </>
  );
}
