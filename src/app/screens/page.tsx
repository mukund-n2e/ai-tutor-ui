import Link from 'next/link';
import Image from 'next/image';
import data from '../../data/screens.json';

type Screen = {
  slug: string;
  title: string;
  file?: string;
  route?: string;
  exists?: boolean;
  order?: number;
};
export const metadata = { title: 'Screens' };
export default function ScreensIndex() {
  const screens = (data as unknown as Screen[])
    .slice()
    .sort((a, b) => (a.order ?? 999) - (b.order ?? 999));
  return (
    <main style={{maxWidth:1100, margin:'40px auto', padding:'0 16px'}}>
      <h1 style={{marginBottom:8}}>Design Screens</h1>
      <p style={{opacity:0.8, marginBottom:20}}>Static previews imported from the design pack.</p>
      <div style={{display:'grid', gridTemplateColumns:'repeat(auto-fit, minmax(260px, 1fr))', gap:16}}>
        {screens.map(s => (
          <article key={s.slug} style={{border:'1px solid #e5e7eb', borderRadius:8, padding:12}}>
            <div style={{height:160, display:'flex', alignItems:'center', justifyContent:'center', overflow:'hidden', background:'#fafafa', border:'1px solid #eee', borderRadius:6}}>
              {s.file ? (
                <Image src={`/design/screens/${s.file}`} alt={s.title} width={320} height={160} style={{height:'auto', width:'100%', objectFit:'contain'}} />
              ) : (
                <div style={{opacity:0.6, fontSize:12}}>TODO</div>
              )}
            </div>
            <h3 style={{margin:'12px 0 6px'}}>{s.title}</h3>
            <div style={{fontSize:12, opacity:0.85, marginBottom:10}}>Slug: <code>{s.slug}</code></div>
            <div style={{display:'flex', gap:12, fontSize:14}}>
              <Link href={`/screens/${s.slug}`}>Open →</Link>
              <span style={{opacity:0.7}}>|</span>
              <Link href={s.route ?? '/'}>{s.exists ? 'Go to page' : 'Suggested route'} →</Link>
            </div>
            {!s.exists && <div style={{fontSize:12, color:'#b45309', marginTop:8}}>Route not implemented yet</div>}
          </article>
        ))}
      </div>
    </main>
  );
}
