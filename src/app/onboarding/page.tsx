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
