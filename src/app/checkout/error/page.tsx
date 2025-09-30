'use client';
import Header from '../../../components/Header';
import Button from '../../../components/Button';
import '../../../styles/tokens.css';
import styles from '../../../styles/system.module.css';
import { useRouter } from 'next/navigation';

export default function CheckoutErrorPage() {
  const router = useRouter();
  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.container}>
          <section className={styles.statusCard}>
            <div className={`${styles.statusIcon} ${styles.err}`}>!</div>
            <h1 className={styles.statusTitle}>Payment didn&apos;t go through</h1>
            <p className={styles.statusBody}>No charge was made. You can try again, or contact support if this keeps happening.</p>
            <div className={styles.statusActions}>
              <Button variant="primary" onClick={() => router.push('/pricing')}>Try again</Button>
              <a className="text-[var(--brand-accent)] underline" href="mailto:support@aitutor.example">Contact support</a>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}