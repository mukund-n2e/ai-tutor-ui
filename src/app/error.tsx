'use client';
import Link from 'next/link';
import Header from '../components/Header';
import '../styles/tokens.css';
import styles from '../styles/system.module.css';

export default function GlobalError({ error }: { error: Error & { digest?: string } }) {
  return (
    <html><body>
      <div className={styles.page}>
        <Header />
        <main className={styles.main}>
          <div className={styles.container}>
            <section className={styles.statusCard}>
              <div className={`${styles.statusIcon} ${styles.err}`}>500</div>
              <h1 className={styles.statusTitle}>Something went wrong</h1>
              <p className={styles.statusBody}>We hit a snag. Try again or come back later.</p>
              <div className={styles.statusActions}>
                <Link href="/" className="text-[var(--brand-accent)] underline">Go home</Link>
              </div>
            </section>
          </div>
        </main>
      </div>
    </body></html>
  );
}