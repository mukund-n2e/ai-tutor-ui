import Link from 'next/link';
import { screens } from '../../design/screens.manifest';

export const metadata = { title: 'Screens' };

export default function ScreensIndex() {
  return (
    <main style={{maxWidth: 1100, margin: '40px auto', padding: '0 16px'}}>
      <h1 style={{marginBottom: 8}}>Design Screens</h1>
      <p style={{opacity: 0.8, marginBottom: 20}}>Static previews imported from the design pack. Use this to verify visual parity.</p>
      <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 16}}>
        {screens.map(s => (
          <article key={s.slug} style={{border: '1px solid #e5e7eb', borderRadius: 8, padding: 12}}>
            <div style={{height: 160, display:'flex', alignItems:'center', justifyContent:'center', overflow:'hidden', background:'#fafafa', border:'1px solid #eee', borderRadius:6}}>
              <img src={`/design/screens/${s.file}`} alt={s.title} style={{maxWidth:'100%', maxHeight:'100%', objectFit:'contain'}} />
            </div>
            <h3 style={{margin: '12px 0 6px'}}>{s.title}</h3>
            <div style={{fontSize: 12, opacity: 0.85, marginBottom: 10}}>Slug: <code>{s.slug}</code></div>
            <div style={{display:'flex', gap:12, fontSize:14}}>
              <Link href={`/__screens/${s.slug}`}>Open →</Link>
              <span style={{opacity:0.7}}>|</span>
              <Link href={s.route}>{s.exists ? 'Go to page' : 'Suggested route'} →</Link>
            </div>
            {!s.exists && <div style={{fontSize:12, color:'#b45309', marginTop:8}}>Route not implemented yet</div>}
          </article>
        ))}
      </div>
    </main>
  );
}
