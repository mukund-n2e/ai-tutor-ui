import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { screens } from '../../../design/screens.manifest';

export async function generateStaticParams() {
  return screens.map(s => ({ slug: s.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const s = screens.find(x => x.slug === slug);
  return { title: s ? `Screen • ${s.title}` : 'Screen' };
}

export default async function ScreenPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const s = screens.find(x => x.slug === slug);
  if (!s) return notFound();
  return (
    <main style={{maxWidth: 1100, margin: '40px auto', padding: '0 16px'}}>
      <p style={{marginBottom: 10}}><Link href="/screens">← All screens</Link></p>
      <h1 style={{margin: '0 0 12px'}}>{s.title}</h1>
      <div style={{fontSize: 14, opacity: 0.8, marginBottom: 12}}>
        slug: <code>{s.slug}</code> • {s.exists ? 'Implemented route' : 'Suggested'}: <Link href={s.route}>{s.route}</Link>
      </div>
      <div style={{border:'1px solid #e5e7eb', borderRadius: 8, overflow:'hidden', background:'#fafafa'}}>
        <img src={`/design/screens/${s.file}`} alt={s.title} style={{display:'block', width:'100%', height:'auto'}} />
      </div>
    </main>
  );
}
