#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

BR="wp023-export-docx-$(date -u +%Y%m%d_%H%M%S)"

# 1) Add docx dependency
npm --prefix web i docx@8

# 2) API: /api/export/docx  → returns a .docx attachment
mkdir -p web/src/app/api/export/docx
cat > web/src/app/api/export/docx/route.ts <<'TS'
import type { NextRequest } from 'next/server';
import { Document, HeadingLevel, Packer, Paragraph } from 'docx';

export const runtime = 'nodejs';

export async function POST(req: NextRequest) {
  try {
    const { title = 'Session', content = '' } = await req.json();
    const lines = String(content).split(/\r?\n/);

    const paras: Paragraph[] = [
      new Paragraph({ text: String(title), heading: HeadingLevel.HEADING_1 }),
      new Paragraph({ text: '' })
    ];
    for (const line of lines) {
      paras.push(new Paragraph({ text: line || ' ' }));
    }

    const doc = new Document({ sections: [{ properties: {}, children: paras }] });
    const buf = await Packer.toBuffer(doc);

    const safe = String(title).replace(/[^a-z0-9-_]+/gi, '_') || 'session';
    return new Response(buf, {
      status: 200,
      headers: {
        'Content-Type': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'Content-Disposition': `attachment; filename="${safe}.docx"`
      }
    });
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: msg }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export function GET() {
  return new Response('Method Not Allowed', { status: 405 });
}
TS

# 3) Update Session page: add "Export .docx" button that calls the API
cat > web/src/app/session/page.tsx <<'TS'
'use client';
import { useSearchParams } from 'next/navigation';
import { Suspense, useEffect, useMemo, useRef, useState } from 'react';
import { MOVES, type SessionCtx } from '@/lib/moves';

type RunState = 'idle'|'running'|'done'|'error';
type Verdict = 'pass' | 'soft' | 'fix';
type ValResult = { status: Verdict; score: number; suggestions: string[] };

function SessionInner() {
  const sp = useSearchParams();
  const verb = sp.get('verb') ?? 'Create';
  const persona = sp.get('persona') ?? 'Creator';
  const minutes = sp.get('minutes') ?? '20';
  const task = sp.get('task') ?? '';

  const [m1, setM1] = useState(''); const [m2, setM2] = useState(''); const [m3, setM3] = useState('');
  const [state, setState] = useState<RunState>('idle');
  const [err, setErr] = useState<string | null>(null);
  const [active, setActive] = useState<0|1|2|null>(null);

  const [vBusy, setVBusy] = useState(false);
  const [vRes, setVRes] = useState<ValResult | null>(null);

  const ctx: SessionCtx = useMemo(()=>({ verb, persona, minutes, task, prev: { m1, m2 } }), [verb, persona, minutes, task, m1, m2]);

  const boxRef = useRef<HTMLDivElement>(null);
  useEffect(()=>{ boxRef.current?.scrollTo({top: 1e9, behavior: 'smooth'}); }, [m1, m2, m3]);

  const charsPerToken = Number(process.env.NEXT_PUBLIC_CHARS_PER_TOKEN ?? process.env.CHARS_PER_TOKEN ?? '4') || 4;
  const tokensCap = Number(process.env.NEXT_PUBLIC_SESSION_TOKEN_CAP ?? process.env.SESSION_TOKEN_CAP ?? '12000') || 12000;
  const charCap = charsPerToken * tokensCap;
  const charCount = (m1 + m2 + m3).length;
  const overCap = charCount >= charCap;

  async function runMove(idx: 0|1|2) {
    setActive(idx); setState('running'); setErr(null);
    const move = MOVES[idx];
    const message = move.build(ctx);
    const scope = [
      `Persona: ${persona}. Verb: ${verb}. Time box: ${minutes} minutes.`,
      'Three-move loop: Understand -> Draft -> Polish.'
    ].join(' ');
    try {
      const resp = await fetch('/api/tutor/stream', {
        method: 'POST',
        headers: { 'Accept': 'text/event-stream', 'Content-Type': 'application/json' },
        body: JSON.stringify({ courseTitle: `${verb} — ${persona}`, scope, message })
      });
      if (!resp.ok || !resp.body) throw new Error(`upstream ${resp.status}`);
      const reader = resp.body.getReader();
      const dec = new TextDecoder();
      let buf = '';
      let acc = '';
      for (;;) {
        const { value, done } = await reader.read();
        if (done) break;
        buf += dec.decode(value, { stream: true });
        const frames = buf.split('\n\n'); buf = frames.pop() ?? '';
        for (const f of frames) {
          if (!f.trim() || !f.startsWith('data:')) continue;
          const payload = f.replace(/^data:\s*/, '');
          if (payload === '[DONE]') continue;
          try {
            const j = JSON.parse(payload);
            const chunk: string = j?.choices?.[0]?.delta?.content ?? '';
            if (chunk) {
              acc += chunk;
              if (idx === 0) setM1(prev => prev + chunk);
              if (idx === 1) setM2(prev => prev + chunk);
              if (idx === 2) setM3(prev => prev + chunk);
            }
          } catch {}
        }
      }
      const key = `session:${Date.now()}:${verb}:${persona}`;
      localStorage.setItem(key, JSON.stringify({ verb, persona, minutes, task, m1: idx===0?acc:m1, m2: idx===1?acc:m2, m3: idx===2?acc:m3, ts: Date.now() }));
      setState('done');
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setErr(msg || 'stream error'); setState('error');
    } finally {
      setActive(null);
    }
  }

  async function validate() {
    setVBusy(true); setErr(null); setVRes(null);
    try {
      const text = [m1, m2, m3].filter(Boolean).join('\n\n');
      const resp = await fetch('/api/validate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, format: 'generic' })
      });
      const j = (await resp.json()) as ValResult;
      setVRes(j);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setErr(msg || 'validate error');
    } finally { setVBusy(false); }
  }

  async function exportDocx() {
    const content = [m1, m2, m3].filter(Boolean).join('\n\n');
    const title = `${verb} — ${persona}`;
    const resp = await fetch('/api/export/docx', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title, content })
    });
    if (!resp.ok) {
      const msg = await resp.text().catch(()=> '');
      setErr(msg || 'export error'); return;
    }
    const blob = await resp.blob();
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `${verb.toLowerCase()}-${Date.now()}.docx`;
    a.click();
  }

  return (
    <main style={{padding:24,maxWidth:980,margin:'0 auto'}}>
      <h1 style={{marginBottom:4}}>{verb} — {persona}</h1>
      <p style={{color:'#667085',marginBottom:16}}>Time box: {minutes} min</p>
      <section style={{marginBottom:16}}>
        <label style={{display:'block',fontWeight:600,marginBottom:8}}>Task</label>
        <p style={{margin:0,whiteSpace:'pre-wrap'}}>{task}</p>
      </section>

      {overCap && (
        <div style={{marginBottom:12,padding:12,border:'1px solid #fee4e2',background:'#fff4f3',borderRadius:8,color:'#b42318'}}>
          You’re at the session budget. Results may truncate. Consider copying/downloading now.
        </div>
      )}

      <div style={{display:'grid',gap:12,marginBottom:16}}>
        <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
          {MOVES.map((m, i) => (
            <button key={m.key} onClick={()=>runMove(i as 0|1|2)} disabled={active!==null}
              style={{padding:'10px 14px',borderRadius:8,border:'1px solid #d0d5dd',background: active===i ? '#f2f4f7' : 'white'}}>
              {active===i ? `Running… ${m.title}` : m.title}
            </button>
          ))}
          <button onClick={validate} disabled={vBusy || !(m1||m2||m3)}
            style={{padding:'10px 14px',borderRadius:8,border:'1px solid #d0d5dd',background: vBusy ? '#f2f4f7' : 'white'}}>
            {vBusy ? 'Validating…' : 'Validate'}
          </button>
        </div>

        {err && <p style={{color:'#b42318'}}>Error: {err}</p>}

        <div ref={boxRef} style={{border:'1px solid #e5e7eb',borderRadius:8,padding:16,height:460,overflow:'auto',whiteSpace:'pre-wrap'}}>
          <h3 style={{marginTop:0}}>Move 1 — Understand</h3>
          <div>{m1 || <span style={{color:'#98a2b3'}}>—</span>}</div>
          <hr/>
          <h3>Move 2 — Draft</h3>
          <div>{m2 || <span style={{color:'#98a2b3'}}>—</span>}</div>
          <hr/>
          <h3>Move 3 — Polish</h3>
          <div>{m3 || <span style={{color:'#98a2b3'}}>—</span>}</div>
        </div>

        <div style={{display:'flex',gap:8,marginTop:12,alignItems:'center',flexWrap:'wrap'}}>
          <button onClick={()=>navigator.clipboard.writeText([m1,m2,m3].filter(Boolean).join('\n\n'))}
            disabled={!(m1||m2||m3)} style={{padding:'8px 12px',border:'1px solid #d0d5dd',borderRadius:8,background:'white'}}>Copy</button>
          <button onClick={()=>{
            const blob = new Blob([`# ${verb} — ${persona}\n\n${[m1,m2,m3].filter(Boolean).join('\n\n')}\n`], { type: 'text/markdown' });
            const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = `${verb.toLowerCase()}-${Date.now()}.md`; a.click();
          }} disabled={!(m1||m2||m3)} style={{padding:'8px 12px',border:'1px solid #d0d5dd',borderRadius:8,background:'white'}}>Download .md</button>
          <button onClick={exportDocx} disabled={!(m1||m2||m3)}
            style={{padding:'8px 12px',border:'1px solid #d0d5dd',borderRadius:8,background:'white'}}>Export .docx</button>

          {vRes && (
            <span style={{
              padding:'6px 10px', borderRadius:999, border:'1px solid #d0d5dd',
              background: vRes.status==='pass' ? '#ecfdf3' : vRes.status==='soft' ? '#fff7ed' : '#fef3f2',
              color: vRes.status==='pass' ? '#027a48' : vRes.status==='soft' ? '#9a3412' : '#b42318'
            }}>
              Validation: {vRes.status.toUpperCase()} (score {vRes.score})
            </span>
          )}
        </div>

        {vRes?.suggestions?.length ? (
          <div style={{marginTop:8,border:'1px dashed #e5e7eb',borderRadius:8,padding:12}}>
            <strong>Suggestions</strong>
            <ul style={{margin:'8px 0 0 16px'}}>
              {vRes.suggestions.map((s, i) => <li key={i}>{s}</li>)}
            </ul>
          </div>
        ) : null}
      </div>
    </main>
  );
}

export const dynamic = 'force-dynamic';

export default function SessionPage() {
  return (
    <Suspense fallback={<main style={{padding:24,maxWidth:960,margin:'0 auto'}}><p>Loading…</p></main>}>
      <SessionInner />
    </Suspense>
  );
}
TS

# 4) Commit, push, open PR
git checkout -b "$BR"
git add web/package.json web/package-lock.json \
        web/src/app/api/export/docx/route.ts \
        web/src/app/session/page.tsx
git commit -m "feat(PRD): add .docx export API and button on Session"
git push -u origin "$BR"

gh pr create --fill --base main --head "$BR"


