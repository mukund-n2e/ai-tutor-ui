import Link from 'next/link';
import Header from '../../../components/Header';
import Card from '../../../components/Card';
import '../../../styles/tokens.css';
import styles from '../../../styles/system.module.css';

export default function CheckoutErrorPage() {
  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.container}>
          <Card className={styles.statusCard}>
            <div className={styles.statusHeaderRow}>
              <span aria-hidden="true" className={styles.iconError}>!</span>
              <h1 className={styles.statusTitle} data-testid="chk-error-title">
                Payment didn&apos;t go through
              </h1>
            </div>
            
            <p className={styles.statusSubtitle}>
              No charge has been made. You can try again or contact support.
            </p>
            
            <div className={styles.statusActions}>
              <Link
                href="/pricing?retry=1"
                className="inline-flex items-center justify-center font-medium min-touch h-11 px-8 rounded-[var(--radius-button)]
                           bg-[var(--brand-accent)] text-[var(--brand-accent-foreground)] hover:bg-[var(--brand-accent-hover)]
                           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[var(--brand-accent)]"
                data-testid="chk-error-retry"
              >
                Try again
              </Link>
              <a
                href="mailto:support@aitutor.example"
                className="inline-flex items-center justify-center font-medium min-touch h-11 px-8 rounded-[var(--radius-button)]
                           bg-[var(--surface)] border border-[var(--border)] text-[var(--text-high)] hover:bg-[var(--surface-hover)]
                           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[var(--brand-accent)]"
                data-testid="chk-error-support"
              >
                Contact support
              </a>
            </div>
            
            <p className={styles.statusNote}>
              If you keep seeing this, we&apos;ll sort it—just reach out.
            </p>
          </Card>
        </div>
      </main>
    </div>
  );
}