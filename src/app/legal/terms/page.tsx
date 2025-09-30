import Header from '../../../components/Header';
import '../../../styles/tokens.css';
import styles from '../../../styles/system.module.css';

export default function TermsPage() {
  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.wideContainer}>
          <header className={styles.legalHeader}>
            <h1 className={styles.legalTitle}>Terms of Use</h1>
            <p className={styles.legalIntro}>Plain-language terms. Use the product as intended, be kind, and respect privacy.</p>
          </header>
          <div className={styles.legalGrid}>
            <section className={styles.legalSection}>
              <h2>License</h2>
              <p>You get a personal license to use lessons and artifacts you produce.</p>
            </section>
            <section className={styles.legalSection}>
              <h2>Payments</h2>
              <p>Level access is annual. Refunds if something goes clearly wrong—just reach out.</p>
            </section>
            <section className={styles.legalSection}>
              <h2>Limits</h2>
              <p>No misuse, no scraping, no reverse engineering. We may rate-limit for stability.</p>
            </section>
          </div>
        </div>
      </main>
    </div>
  );
}