export default function Home() {
  return (
    <main style={{padding:24,maxWidth:980,margin:'0 auto'}}>
      <h1 style={{marginBottom:12}}>Learn and apply AI to your job. No fluff.</h1>
      <p style={{color:'#667085',marginBottom:20}}>Pick a job task. We&apos;ll guide three decisive moves, validate, and you&apos;re done.</p>

      <div style={{display:'flex',gap:12,marginBottom:24}}>
        <a href="/onboarding/role" style={{padding:'10px 14px',background:'#ff7a00',color:'#fff',borderRadius:8,textDecoration:'none'}}>Start from your work</a>
        <a href="/samples" style={{padding:'10px 14px',textDecoration:'none'}}>Try a sample</a>
      </div>

      <footer style={{marginTop:24,opacity:0.8}}>Incognito by default. Nothing saved unless you say so.</footer>
    </main>
  );
}
