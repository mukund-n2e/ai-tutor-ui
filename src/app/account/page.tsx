'use client';

import { useState } from 'react';
import Header from '../../components/Header';
import Card from '../../components/Card';
import '../../styles/tokens.css';
import styles from '../../styles/system.module.css';

export default function AccountPage() {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isLinkSent, setIsLinkSent] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;

    setIsLoading(true);
    
    // Simulate API call - replace with actual magic link implementation
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    setIsLoading(false);
    setIsLinkSent(true);
  };

  const handleTryAgain = () => {
    setIsLinkSent(false);
    setEmail('');
  };

  return (
    <div className={styles.page}>
      <Header />
      <main className={styles.main}>
        <div className={styles.container}>
          <Card className={styles.formCard}>
            {!isLinkSent ? (
              <>
                <h1 className={styles.formTitle}>Sign in</h1>
                <p className={styles.formSubtitle}>
                  Enter your email and we&apos;ll send you a secure link to sign in.
                </p>
                
                <form onSubmit={handleSubmit}>
                  <div className={styles.formField}>
                    <label htmlFor="email" className={styles.formLabel}>
                      Email address
                    </label>
                    <input
                      id="email"
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className={styles.formInput}
                      placeholder="you@example.com"
                      required
                      disabled={isLoading}
                      data-testid="acct-email"
                    />
                  </div>
                  
                  <button
                    type="submit"
                    className={styles.formButton}
                    disabled={isLoading || !email.trim()}
                    data-testid="acct-send"
                  >
                    {isLoading ? 'Sending...' : 'Send sign-in link'}
                  </button>
                </form>
              </>
            ) : (
              <>
                <div className={styles.statusHeaderRow}>
                  <span aria-hidden="true" className={styles.iconSuccess}>✓</span>
                  <h1 className={styles.formTitle}>Link sent</h1>
                </div>
                
                <p className={styles.formSubtitle} data-testid="acct-sent">
                  Check your email for a secure sign-in link. It may take a few minutes to arrive.
                </p>
                
                <div className={styles.statusActions}>
                  <button
                    onClick={handleTryAgain}
                    className="inline-flex items-center justify-center font-medium min-touch h-11 px-8 rounded-[var(--radius-button)]
                               bg-[var(--surface)] border border-[var(--border)] text-[var(--text-high)] hover:bg-[var(--surface-hover)]
                               focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[var(--brand-accent)]"
                  >
                    Try different email
                  </button>
                </div>
                
                <p className={styles.statusNote}>
                  Didn&apos;t receive it? Check your spam folder or try again.
                </p>
              </>
            )}
          </Card>
        </div>
      </main>
    </div>
  );
}
