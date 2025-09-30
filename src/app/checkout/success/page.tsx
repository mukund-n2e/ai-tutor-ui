import Link from 'next/link';
import { Suspense } from 'react';
import Header from '../../../components/Header';
import Card from '../../../components/Card';
import '../../../styles/tokens.css';
import styles from '../../../styles/system.module.css';

type PageProps = { 
  searchParams?: Promise<{ [key: string]: string | string[] | undefined }> 
};

function SuccessContent({ searchParams }: { searchParams: { [key: string]: string | string[] | undefined } | undefined }) {
  const level = typeof searchParams?.level === 'string' ? searchParams.level.toUpperCase() : null;
  const sessionId = typeof searchParams?.session_id === 'string' ? searchParams.session_id : null;
  
  const ctaText = level ? `Start Level ${level}` : 'Browse courses';
  const ctaHref = level ? `/wall?via=success&level=${level}` : '/wall?via=success';

  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.container}>
          <Card className={styles.statusCard}>
            <div className={styles.statusHeaderRow}>
              <span aria-hidden="true" className={styles.iconSuccess}>✓</span>
              <h1 className={styles.statusTitle} data-testid="chk-success-title">
                Payment confirmed
              </h1>
            </div>

            <p className={styles.statusSubtitle}>
              You&apos;re all set.
            </p>

            <div className={styles.statusActions}>
              <Link
                href={ctaHref}
                className="inline-flex items-center justify-center font-medium min-touch h-11 px-8 rounded-[var(--radius-button)]
                           bg-[var(--brand-accent)] text-[var(--brand-accent-foreground)] hover:bg-[var(--brand-accent-hover)]
                           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[var(--brand-accent)]"
                data-testid="chk-success-cta"
              >
                {ctaText}
              </Link>
            </div>

            <p className={styles.statusNote}>
              Private by default. Nothing saved unless you say so.
            </p>
            
            {sessionId && (
              <p className={styles.statusMeta} aria-live="polite">
                Ref: {sessionId}
              </p>
            )}
          </Card>
        </div>
      </main>
    </div>
  );
}

export default async function SuccessPage({ searchParams }: PageProps) {
  const resolvedSearchParams = await searchParams;
  
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <SuccessContent searchParams={resolvedSearchParams} />
    </Suspense>
  );
}