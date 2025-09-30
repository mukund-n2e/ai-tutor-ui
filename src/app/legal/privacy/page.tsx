import Link from 'next/link';
import Header from '../../../components/Header';
import Card from '../../../components/Card';
import '../../../styles/tokens.css';
import styles from '../../../styles/system.module.css';

export default function PrivacyPage() {
  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.wideContainer}>
          <div className={styles.legalGrid}>
            <div className={styles.legalContent}>
              <h1 className={styles.legalTitle} data-testid="legal-privacy-title">
                Privacy policy
              </h1>
              <p className={styles.legalSubtitle}>
                How we handle your data at AI‑Tutor.
              </p>
              <p className={styles.legalUpdated} data-testid="legal-privacy-updated">
                Last updated: September 2025
              </p>

              <div className={styles.legalToc} data-testid="legal-privacy-toc">
                <h2 className={styles.legalTocTitle}>Contents</h2>
                <ul className={styles.legalTocList}>
                  <li className={styles.legalTocItem}>
                    <a href="#data-we-store" className={styles.legalTocLink}>Data we store</a>
                  </li>
                  <li className={styles.legalTocItem}>
                    <a href="#how-we-use-it" className={styles.legalTocLink}>How we use it</a>
                  </li>
                  <li className={styles.legalTocItem}>
                    <a href="#your-controls" className={styles.legalTocLink}>Your controls</a>
                  </li>
                  <li className={styles.legalTocItem}>
                    <a href="#contact" className={styles.legalTocLink}>Contact</a>
                  </li>
                </ul>
              </div>

              <section className={styles.legalSection} id="data-we-store" data-testid="legal-privacy-sec-data-we-store">
                <h2 className={styles.legalSectionTitle}>Data we store</h2>
                <p className={styles.legalBody}>
                  We collect minimal data to provide the service:
                </p>
                <ul className={styles.legalBullets}>
                  <li className={styles.legalBullet}>
                    Your email address for account access and communication
                  </li>
                  <li className={styles.legalBullet}>
                    Session data (prompts, responses) only when you choose to save progress
                  </li>
                  <li className={styles.legalBullet}>
                    Payment information processed securely through Stripe (we don&apos;t store card details)
                  </li>
                  <li className={styles.legalBullet}>
                    Basic usage analytics to improve the service (anonymized)
                  </li>
                </ul>
              </section>

              <section className={styles.legalSection} id="how-we-use-it" data-testid="legal-privacy-sec-how-we-use-it">
                <h2 className={styles.legalSectionTitle}>How we use it</h2>
                <p className={styles.legalBody}>
                  Your data is used solely to:
                </p>
                <ul className={styles.legalBullets}>
                  <li className={styles.legalBullet}>
                    Provide AI tutoring and maintain your learning progress
                  </li>
                  <li className={styles.legalBullet}>
                    Send you important service updates and security notifications
                  </li>
                  <li className={styles.legalBullet}>
                    Process payments and manage your subscription
                  </li>
                  <li className={styles.legalBullet}>
                    Improve our service through aggregated, anonymous usage patterns
                  </li>
                </ul>
                <p className={styles.legalBody}>
                  We never sell your data or use it for advertising. We don&apos;t share personal information with third parties except as required by law or to provide the service (like payment processing).
                </p>
              </section>

              <section className={styles.legalSection} id="your-controls" data-testid="legal-privacy-sec-your-controls">
                <h2 className={styles.legalSectionTitle}>Your controls</h2>
                <p className={styles.legalBody}>
                  You have full control over your data:
                </p>
                <ul className={styles.legalBullets}>
                  <li className={styles.legalBullet}>
                    <strong>Incognito by default:</strong> Sessions aren&apos;t saved unless you explicitly choose to save them
                  </li>
                  <li className={styles.legalBullet}>
                    <strong>Export:</strong> Download your saved sessions and progress at any time
                  </li>
                  <li className={styles.legalBullet}>
                    <strong>Delete:</strong> Remove your account and all associated data permanently
                  </li>
                  <li className={styles.legalBullet}>
                    <strong>Correct:</strong> Update your email or other account information
                  </li>
                </ul>
                <p className={styles.legalBody}>
                  To exercise these rights, contact us at the email below.
                </p>
              </section>

              <section className={styles.legalSection} id="contact" data-testid="legal-privacy-sec-contact">
                <h2 className={styles.legalSectionTitle}>Contact</h2>
                <p className={styles.legalBody}>
                  Questions about privacy or data handling: <a href="mailto:privacy@ai-tutor.example" className="text-[var(--brand-accent)] hover:underline">privacy@ai-tutor.example</a>
                </p>
                <p className={styles.legalBody}>
                  We&apos;ll respond within 7 days and work with you to address any concerns.
                </p>
              </section>
            </div>

            <aside className={styles.legalAside} role="region" aria-label="Quick links">
              <Card>
                <h3 className={styles.legalTocTitle}>Quick links</h3>
                <ul className={styles.legalTocList}>
                  <li className={styles.legalTocItem}>
                    <Link href="/legal/terms" className={styles.legalTocLink}>
                      Terms of use
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
