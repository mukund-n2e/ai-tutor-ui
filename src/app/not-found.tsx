import Link from 'next/link';
import Header from '../components/Header';
import '../styles/tokens.css';
import styles from '../styles/system.module.css';

export default function NotFound() {
  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.container}>
          <section className={styles.statusCard}>
            <div className={`${styles.statusIcon} ${styles.err}`}>404</div>
            <h1 className={styles.statusTitle}>Page not found</h1>
            <p className={styles.statusBody}>That link doesn&apos;t exist. Want to head back?</p>
            <div className={styles.statusActions}>
              <Link href="/" className="text-[var(--brand-accent)] underline">Go home</Link>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}