import Image from 'next/image';
import Button from '../../components/Button';
import Card from '../../components/Card';
import Chip from '../../components/Chip';
import Header from '../../components/Header';
import '../../styles/tokens.css';
import styles from '../../styles/landing.module.css';

export default function LandingPage() {
  return (
    <div className={styles.page}>
      <Header />
      
      <main className={styles.main}>
        <div className={styles.container}>
          <section className={styles.hero}>
            <div className={styles.heroGrid}>
              {/* Hero Content */}
              <div className={styles.heroContent}>
                <h1 className={styles.heroTitle} data-testid="hero-h1">
                  One skill. One small win. In 15 minutes.
                </h1>
                
                <p className={styles.heroSubtitle}>
                  Learn AI the human way—simple lessons that finish with something you can actually use.
                </p>
                
                <div className={styles.ctaRow}>
                  <Button 
                    variant="primary" 
                    size="lg" 
                    className={styles.ctaPrimary}
                    data-testid="cta-try-sample"
                  >
                    Try a sample
                  </Button>
                  <Button 
                    variant="secondary" 
                    size="lg"
                    data-testid="cta-start-free"
                  >
                    Start free
                  </Button>
                </div>
                
                <div className={styles.badges}>
                  <Chip icon={
                    <Image 
                      src="/assets/check-circle-icon.svg" 
                      alt="" 
                      width={16} 
                      height={16}
                    />
                  }>
                    No fluff
                  </Chip>
                  <Chip icon={
                    <Image 
                      src="/assets/check-circle-icon.svg" 
                      alt="" 
                      width={16} 
                      height={16}
                    />
                  }>
                    Real outcomes
                  </Chip>
                  <Chip 
                    icon={
                      <Image 
                        src="/assets/clock-icon.svg" 
                        alt="" 
                        width={16} 
                        height={16}
                      />
                    }
                    title="Grade 8 or below reading level"
                  >
                    Up to Grade 8 reading
                  </Chip>
                </div>
              </div>
              
              {/* Demo Card */}
              <div className={styles.demoSection}>
                <Card className={styles.demoCard} hover>
                  <div className={styles.demoContent}>
                    <div className={styles.playButton}>
                      <button 
                        className={styles.playIcon}
                        aria-label="Preview demo"
                        data-testid="btn-preview-demo"
                      >
                        <Image 
                          src="/assets/play-icon.svg" 
                          alt="" 
                          width={24} 
                          height={24}
                        />
                      </button>
                    </div>
                    
                    <h3 className={styles.demoTitle}>Interactive Demo</h3>
                    
                    <div className={styles.demoBullets}>
                      <div className={styles.demoBullet}>
                        <Image 
                          src="/assets/clock-icon.svg" 
                          alt="" 
                          width={16} 
                          height={16}
                        />
                        <span>About 15 minutes to complete</span>
                      </div>
                      <div className={styles.demoBullet}>
                        <Image 
                          src="/assets/check-circle-icon.svg" 
                          alt="" 
                          width={16} 
                          height={16}
                        />
                        <span>Real deliverable at the end</span>
                      </div>
                    </div>
                    
                    <Button variant="secondary" size="sm" className={styles.previewButton}>
                      <Image 
                        src="/assets/play-icon.svg" 
                        alt="" 
                        width={16} 
                        height={16}
                      />
                      Preview Demo
                    </Button>
                  </div>
                </Card>
              </div>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}
