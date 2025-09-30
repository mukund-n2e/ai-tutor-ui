'use client';
import { useSearchParams, useRouter } from 'next/navigation';
import Header from '../../../components/Header';
import Button from '../../../components/Button';
import '../../../styles/tokens.css';
import styles from '../../../styles/system.module.css';

export default function CheckoutSuccessPage() {
  const params = useSearchParams();
  const router = useRouter();
  const level = params.get('level') || 'L2';
  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.container}>
          <section className={styles.statusCard} role="status" aria-live="polite">
            <div className={`${styles.statusIcon} ${styles.ok}`}>✓</div>
            <h1 className={styles.statusTitle}>Payment confirmed</h1>
            <p className={styles.statusBody}>You now have access to <strong>Level {level}</strong> for 12 months.</p>
            <div className={styles.statusActions}>
              <Button variant="primary" size="lg" onClick={() => router.push(`/wall?via=success&level=${level}`)}>Start Level {level}</Button>
              <Button variant="secondary" onClick={() => router.push('/wall')}>Explore courses</Button>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}