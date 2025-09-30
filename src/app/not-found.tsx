import Link from 'next/link';
import Header from '../components/Header';
import Card from '../components/Card';
import '../styles/tokens.css';
import styles from '../styles/system.module.css';

export default function NotFound() {
  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.container}>
          <Card className={styles.statusCard}>
            <h1 className={styles.statusTitle} data-testid="sys-404-title">
              We couldn&apos;t find that
            </h1>
            
            <p className={styles.statusSubtitle}>
              The page you&apos;re looking for doesn&apos;t exist or has been moved.
            </p>
            
            <div className={styles.statusActions}>
              <Link
                href="/"
                className="inline-flex items-center justify-center font-medium min-touch h-11 px-8 rounded-[var(--radius-button)]
                           bg-[var(--brand-accent)] text-[var(--brand-accent-foreground)] hover:bg-[var(--brand-accent-hover)]
                           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[var(--brand-accent)]"
              >
                Back to home
              </Link>
            </div>
            
            <p className={styles.statusNote}>
              If you think this is a mistake, let us know.
            </p>
          </Card>
        </div>
      </main>
    </div>
  );
}