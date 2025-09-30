import Link from 'next/link';
import Header from '../../../components/Header';
import Card from '../../../components/Card';
import '../../../styles/tokens.css';
import styles from '../../../styles/system.module.css';

export default function TermsPage() {
  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.wideContainer}>
          <div className={styles.legalGrid}>
            <div className={styles.legalContent}>
              <h1 className={styles.legalTitle} data-testid="legal-terms-title">
                Terms of use
              </h1>
              <p className={styles.legalSubtitle}>
                Plain-English terms for AI‑Tutor.
              </p>
              <p className={styles.legalUpdated} data-testid="legal-terms-updated">
                Last updated: September 2025
              </p>

              <div className={styles.legalToc} data-testid="legal-terms-toc">
                <h2 className={styles.legalTocTitle}>Contents</h2>
                <ul className={styles.legalTocList}>
                  <li className={styles.legalTocItem}>
                    <a href="#using" className={styles.legalTocLink}>Using AI‑Tutor</a>
                  </li>
                  <li className={styles.legalTocItem}>
                    <a href="#content" className={styles.legalTocLink}>Your content & IP</a>
                  </li>
                  <li className={styles.legalTocItem}>
                    <a href="#payments" className={styles.legalTocLink}>Payments & access (L2/L3/L4)</a>
                  </li>
                  <li className={styles.legalTocItem}>
                    <a href="#acceptable" className={styles.legalTocLink}>Acceptable use</a>
                  </li>
                  <li className={styles.legalTocItem}>
                    <a href="#disclaimers" className={styles.legalTocLink}>Disclaimers</a>
                  </li>
                  <li className={styles.legalTocItem}>
                    <a href="#limits" className={styles.legalTocLink}>Limits of liability</a>
                  </li>
                  <li className={styles.legalTocItem}>
                    <a href="#termination" className={styles.legalTocLink}>Termination</a>
                  </li>
                  <li className={styles.legalTocItem}>
                    <a href="#contact" className={styles.legalTocLink}>Contact</a>
                  </li>
                </ul>
              </div>

              <section className={styles.legalSection} id="using" data-testid="legal-terms-sec-using">
                <h2 className={styles.legalSectionTitle}>Using AI‑Tutor</h2>
                <p className={styles.legalBody}>
                  You must be 16+ and legally able to agree to these terms.
                </p>
                <p className={styles.legalBody}>
                  We may update features and terms; we&apos;ll note the date at the top.
                </p>
              </section>

              <section className={styles.legalSection} id="content" data-testid="legal-terms-sec-content">
                <h2 className={styles.legalSectionTitle}>Your content & IP</h2>
                <p className={styles.legalBody}>
                  You own your inputs and outputs where law allows. You grant us a limited license to process your inputs to run the service.
                </p>
                <p className={styles.legalBody}>
                  Don&apos;t enter sensitive personal or confidential data you&apos;re not allowed to share.
                </p>
              </section>

              <section className={styles.legalSection} id="payments" data-testid="legal-terms-sec-payments">
                <h2 className={styles.legalSectionTitle}>Payments & access</h2>
                <p className={styles.legalBody}>
                  L1 is free. Paid levels (L2/L3/L4) are one‑year access from purchase.
                </p>
                <p className={styles.legalBody}>
                  Payments are handled by Stripe; pricing is shown in your market at checkout.
                </p>
              </section>

              <section className={styles.legalSection} id="acceptable" data-testid="legal-terms-sec-acceptable">
                <h2 className={styles.legalSectionTitle}>Acceptable use</h2>
                <ul className={styles.legalBullets}>
                  <li className={styles.legalBullet}>
                    No unlawful, harmful, or abusive use.
                  </li>
                  <li className={styles.legalBullet}>
                    No attempts to reverse engineer or overload the service.
                  </li>
                  <li className={styles.legalBullet}>
                    No automated scraping.
                  </li>
                </ul>
              </section>

              <section className={styles.legalSection} id="disclaimers" data-testid="legal-terms-sec-disclaimers">
                <h2 className={styles.legalSectionTitle}>Disclaimers</h2>
                <p className={styles.legalBody}>
                  Service is provided &quot;as is.&quot; We don&apos;t guarantee outcomes or uninterrupted availability.
                </p>
              </section>

              <section className={styles.legalSection} id="limits" data-testid="legal-terms-sec-limits">
                <h2 className={styles.legalSectionTitle}>Limits of liability</h2>
                <p className={styles.legalBody}>
                  To the extent permitted by law, we&apos;re not liable for indirect or consequential losses.
                </p>
              </section>

              <section className={styles.legalSection} id="termination" data-testid="legal-terms-sec-termination">
                <h2 className={styles.legalSectionTitle}>Termination</h2>
                <p className={styles.legalBody}>
                  We may suspend or end access for violations. You can stop using the service at any time.
                </p>
              </section>

              <section className={styles.legalSection} id="contact" data-testid="legal-terms-sec-contact">
                <h2 className={styles.legalSectionTitle}>Contact</h2>
                <p className={styles.legalBody}>
                  Questions about these terms: <a href="mailto:support@ai-tutor.example" className="text-[var(--brand-accent)] hover:underline">support@ai-tutor.example</a>
                </p>
              </section>
            </div>

            <aside className={styles.legalAside} role="region" aria-label="Quick links">
              <Card>
                <h3 className={styles.legalTocTitle}>Quick links</h3>
                <ul className={styles.legalTocList}>
                  <li className={styles.legalTocItem}>
                    <Link href="/legal/privacy" className={styles.legalTocLink}>
                      Privacy policy
                    </Link>
                  </li>
                  <li className={styles.legalTocItem}>
                    <Link href="/pricing" className={styles.legalTocLink}>
                      Pricing & access
                    </Link>
                  </li>
                  <li className={styles.legalTocItem}>
                    <Link href="/account" className={styles.legalTocLink}>
                      Support
                    </Link>
                  </li>
                </ul>
              </Card>
            </aside>
          </div>
        </div>
      </main>
    </div>
  );
}
