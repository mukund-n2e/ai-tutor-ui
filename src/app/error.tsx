'use client';

import { useEffect } from 'react';
import Header from '../components/Header';
import Card from '../components/Card';
import '../styles/tokens.css';
import styles from '../styles/system.module.css';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Log the error to an error reporting service
    console.error('Client error boundary:', error);
  }, [error]);

  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.container}>
          <Card className={styles.statusCard}>
            <div className={styles.statusHeaderRow}>
              <span aria-hidden="true" className={styles.iconError}>!</span>
              <h1 className={styles.statusTitle} data-testid="sys-500-title">
                Something went wrong
              </h1>
            </div>
            
            <p className={styles.statusSubtitle}>
              We&apos;re sorry, but something unexpected happened. Please try again.
            </p>
            
            <div className={styles.statusActions}>
              <button
                onClick={reset}
                className="inline-flex items-center justify-center font-medium min-touch h-11 px-8 rounded-[var(--radius-button)]
                           bg-[var(--brand-accent)] text-[var(--brand-accent-foreground)] hover:bg-[var(--brand-accent-hover)]
                           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[var(--brand-accent)]"
              >
                Try again
              </button>
              <a
                href="mailto:support@aitutor.example"
                className="inline-flex items-center justify-center font-medium min-touch h-11 px-8 rounded-[var(--radius-button)]
                           bg-[var(--surface)] border border-[var(--border)] text-[var(--text-high)] hover:bg-[var(--surface-hover)]
                           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[var(--brand-accent)]"
              >
                Contact support
              </a>
            </div>
            
            <p className={styles.statusNote}>
              If this keeps happening, please let us know what you were doing when it occurred.
            </p>
          </Card>
        </div>
      </main>
    </div>
  );
}