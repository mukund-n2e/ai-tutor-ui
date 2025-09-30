import Header from '../../components/Header';
import '../../styles/tokens.css';
import styles from '../../styles/system.module.css';

export default function AccountSignInPage() {
  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.container}>
          <h1 className={styles.statusTitle}>Sign in</h1>
          <form className={styles.form} aria-label="Email sign-in">
            <label className={styles.label} htmlFor="email">Email</label>
            <input id="email" name="email" type="email" className={styles.input} placeholder="you@example.com" aria-describedby="email-hint" required />
            <div id="email-hint" className={styles.hint}>We&apos;ll email you a magic link to sign in.</div>
            <button className="btn-primary" type="submit" disabled>Send magic link (stub)</button>
          </form>
        </div>
      </main>
    </div>
  );
}