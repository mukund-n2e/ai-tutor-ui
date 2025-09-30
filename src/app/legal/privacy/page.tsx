import Header from '../../../components/Header';
import '../../../styles/tokens.css';
import styles from '../../../styles/system.module.css';

export default function PrivacyPage() {
  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.wideContainer}>
          <header className={styles.legalHeader}>
            <h1 className={styles.legalTitle}>Privacy Policy</h1>
            <p className={styles.legalIntro}>We keep it simple: your learning is private by default. Nothing is saved unless you say so.</p>
          </header>
          <div className={styles.legalGrid}>
            <section className={styles.legalSection}>
              <h2>What we collect</h2>
              <p>Basic account info (email). Optional learning inputs if you opt in to save.</p>
            </section>
            <section className={styles.legalSection}>
              <h2>How we use it</h2>
              <p>To run the service, improve lessons, and send you the things you asked for.</p>
            </section>
            <section className={styles.legalSection}>
              <h2>Your choices</h2>
              <p>Use it without saving. Unsubscribe anytime. Request deletion anytime.</p>
            </section>
          </div>
        </div>
      </main>
    </div>
  );
}