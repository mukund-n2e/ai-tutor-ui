'use client';
import { useSearchParams } from 'next/navigation';
import { useEffect, useRef, useState } from 'react';

export default function SessionPage() {
  const sp = useSearchParams();
  const verb = sp.get('verb') ?? 'Create';
  const persona = sp.get('persona') ?? 'Creator';
  const minutes = sp.get('minutes') ?? '20';
  const task = sp.get('task') ?? '';

  const [out, setOut] = useState('');
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string|null>(null);
  const boxRef = useRef<HTMLDivElement>(null);
  useEffect(()=>{ boxRef.current?.scrollTo({top:1e9,behavior:'smooth'}); }, [out]);

  const scope = [
    `Persona: ${persona}. Verb: ${verb}. Time box: ${minutes} minutes.`,
    `Run a 3‑move tutoring loop: 1) Understand, 2) Draft, 3) Polish.`,
    `Stay focused on the user's task and produce concise, actionable output.`,
  ].join(' ');

  async function run() {
    setBusy(true); setErr(null); setOut('');
    try {
      const resp = await fetch('/api/tutor/stream', {
        method: 'POST',
        headers: { 'Accept': 'text/event-stream', 'Content-Type': 'application/json' },
        body: JSON.stringify({ courseTitle: `${verb} – ${persona}`, scope, message: task })
      });
      if (!resp.ok || !resp.body) throw new Error(`upstream ${resp.status}`);
      const reader = resp.body.getReader();
      const dec = new TextDecoder();
      let buf = '';
      for (;;) {
        const { value, done } = await reader.read();
        if (done) break;
        buf += dec.decode(value, { stream: true });
        const frames = buf.split('\n\n'); buf = frames.pop() ?? '';
        for (const f of frames) {
          if (!f.trim()) continue;
          if (f.startsWith('data:')) {
            const payload = f.replace(/^data:\s*/, '');
            if (payload === '[DONE]') continue;
            try {
              const j = JSON.parse(payload);
              const chunk = j?.choices?.[0]?.delta?.content ?? '';
              if (chunk) setOut(prev => prev + chunk);
            } catch {}
          }
        }
      }
      // local save (simple library)
      const key = `session:${Date.now()}:${verb}:${persona}`;
      localStorage.setItem(key, JSON.stringify({ verb, persona, minutes, task, out, ts: Date.now() }));
    } catch (e:any) {
      setErr(e?.message || 'stream error');
    } finally { setBusy(false); }
  }

  return (
    <main style={{padding:24,maxWidth:960,margin:'0 auto'}}>
      <h1 style={{marginBottom:4}}>{verb} — {persona}</h1>
      <p style={{color:'#667085',marginBottom:12}}>{task}</p>
      <div style={{display:'flex',gap:8,marginBottom:12}}>
        <button onClick={run} disabled={busy}
          style={{padding:'10px 14px',borderRadius:8,border:'1px solid #d0d5dd',background:busy?'#f2f4f7':'white'}}>
          {busy ? 'Streaming…' : 'Run'}
        </button>
        <button onClick={()=>navigator.clipboard.writeText(out)} disabled={!out}
          style={{padding:'10px 14px',borderRadius:8,border:'1px solid #d0d5dd',background:'white'}}>
          Copy
        </button>
        <button onClick={()=>{
          const blob = new Blob([`# ${verb} — ${persona}\n\n${out}\n`], { type: 'text/markdown' });
          const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = `${verb.toLowerCase()}-${Date.now()}.md`; a.click();
        }} disabled={!out}
          style={{padding:'10px 14px',borderRadius:8,border:'1px solid #d0d5dd',background:'white'}}>
          Download .md
        </button>
      </div>
      {err && <p style={{color:'#b42318',marginBottom:12}}>Error: {err}</p>}
      <div ref={boxRef} style={{border:'1px solid #e5e7eb',borderRadius:8,padding:16,height:460,overflow:'auto',whiteSpace:'pre-wrap'}}>
        {out || <span style={{color:'#98a2b3'}}>Output will stream here…</span>}
      </div>
    </main>
  );
}
