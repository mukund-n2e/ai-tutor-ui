#!/usr/bin/env bash
set -euo pipefail

BR="wp018-prd-onboarding-session-$(date -u +%Y%m%d_%H%M%S)"

# Onboarding page: verb + persona + timebox + task -> /session?...
mkdir -p web/src/app/onboarding
cat > web/src/app/onboarding/page.tsx <<'TS'
'use client';
import { useState } from 'react';

const VERBS = ['Create','Automate','Analyze','Decide','Personalize','Connect'] as const;
const PERSONAS = ['Creator','Consultant'] as const;
const TIMES = [20,40,60] as const;

export default function Onboarding() {
  const [verb, setVerb] = useState<typeof VERBS[number]>('Create');
  const [persona, setPersona] = useState<typeof PERSONAS[number]>('Creator');
  const [minutes, setMinutes] = useState<typeof TIMES[number]>(20);
  const [task, setTask] = useState('');

  function start() {
    const url = `/session?verb=${encodeURIComponent(verb)}&persona=${encodeURIComponent(persona)}&minutes=${minutes}&task=${encodeURIComponent(task)}`;
    window.location.href = url;
  }

  return (
    <main style={{padding:24,maxWidth:960,margin:'0 auto'}}>
      <h1 style={{marginBottom:8}}>Start a session</h1>
      <p style={{color:'#667085',marginBottom:16}}>Pick a verb, tell us the task, and set your time box. We’ll guide three decisive moves.</p>

      <section style={{display:'grid',gap:12,marginBottom:16}}>
        <label>Verb</label>
        <div style={{display:'flex',flexWrap:'wrap',gap:8}}>
          {VERBS.map(v => (
            <button key={v} onClick={()=>setVerb(v)}
              style={{padding:'8px 12px',borderRadius:8,border:'1px solid #d0d5dd',
                      background: v===verb ? '#f2f4f7' : 'white'}}>{v}</button>
          ))}
        </div>
      </section>

      <section style={{display:'grid',gap:12,marginBottom:16}}>
        <label>Task</label>
        <textarea value={task} onChange={e=>setTask(e.target.value)} rows={4}
          placeholder="Describe what you’re trying to do…"
          style={{padding:'10px 12px',border:'1px solid #d0d5dd',borderRadius:8}}/>
      </section>

      <section style={{display:'flex',gap:16,marginBottom:16}}>
        <div>
          <label>Persona</label>
          <div style={{display:'flex',gap:8,marginTop:8}}>
            {PERSONAS.map(p => (
              <button key={p} onClick={()=>setPersona(p)}
                style={{padding:'8px 12px',borderRadius:8,border:'1px solid #d0d5dd',
                        background: p===persona ? '#f2f4f7' : 'white'}}>{p}</button>
            ))}
          </div>
        </div>
        <div>
          <label>Time box</label>
          <div style={{display:'flex',gap:8,marginTop:8}}>
            {TIMES.map(t => (
              <button key={t} onClick={()=>setMinutes(t)}
                style={{padding:'8px 12px',borderRadius:8,border:'1px solid #d0d5dd',
                        background: t===minutes ? '#f2f4f7' : 'white'}}>{t} min</button>
            ))}
          </div>
        </div>
      </section>

      <button onClick={start} disabled={!task.trim()}
        style={{padding:'10px 14px',borderRadius:8,border:'1px solid #d0d5dd',background:'white'}}>
        Start session
      </button>
    </main>
  );
}
TS

# Session page: streams via POST /api/tutor/stream using PRD fields
mkdir -p web/src/app/session
cat > web/src/app/session/page.tsx <<'TS'
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
TS

git checkout -b "$BR"
git add web/src/app/onboarding/page.tsx web/src/app/session/page.tsx
git commit -m "feat(PRD): Onboarding (verb/persona/timebox/task) and Session wired to SSE"
git push -u origin "$BR" >/dev/null 2>&1 || git push -u origin "$BR"
echo "branch=$BR"
