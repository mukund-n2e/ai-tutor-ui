import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

const CREATOR = {
  title: 'YouTube Short — Script + Shot List',
  outcome: 'Ship a 45–60s script + shot list in 40–60 min',
  scope: 'hooks, beats, b‑roll, captions; no editing tips',
  heroMoves: [
    { id:'hm1', name:'Hooks + Spine', tapPrompt:'Give 12 hooks for [topic] to [audience]. Format: HOOK → 3‑beat outline → CTA. Avoid [taboos].' },
    { id:'hm2', name:'Voice + B‑roll', tapPrompt:'Rewrite Hook #[n] in [voice]. Add B‑roll ideas + on‑screen text + per‑beat seconds.' },
    { id:'hm3', name:'Shot List', tapPrompt:'Turn final script into a shot list (Scene|Shot|Action|Line|OSD|secs) + 3 alt hooks + description + tags.' }
  ],
  validator: { checks: [
    { id:'hook_pattern_tag', label:'Hook has pattern tag', pass:false },
    { id:'beats_count', label:'5–7 beats, ≤12 words each', pass:false }
  ]}
};
const CONSULTANT = {
  title: 'Discovery → 1‑page Proposal (+ 3‑slide summary)',
  outcome: 'Draft a concise proposal + 3‑slide exec summary in 60–90 min',
  scope: 'compress notes → outcomes, scope, options; pricing options; follow‑ups',
  heroMoves: [
    { id:'hm1', name:'Clarify & Compress', tapPrompt:'From these notes, extract: pain, current state, desired outcomes, constraints, success metrics. Output 3 lines: Problem, Why now, What “good” looks like.' },
    { id:'hm2', name:'Draft Proposal', tapPrompt:'Draft a 1‑page proposal. Sections: Outcomes, Scope (bullets), Timeline, Assumptions, Client inputs, Risks. Tone: [voice].' },
    { id:'hm3', name:'Price & Package', tapPrompt:'Create 3 options (Good/Better/Best) with deliverables, time, price, acceptance criteria. Add a 3‑slide exec summary.' }
  ],
  validator: { checks: [
    { id:'kpi_present', label:'Exactly one KPI line', pass:false },
    { id:'options_mece', label:'2–3 options A/B/C with trade‑offs', pass:false }
  ]}
};

export async function POST(req: NextRequest) {
  const body = await req.json();
  const text = String(body?.roleOrProblem || '').toLowerCase();
  const track = body?.track || (/(proposal|client|retainer|sow)/.test(text) ? 'consultant' : 'creator');
  const tpl = track === 'consultant' ? CONSULTANT : CREATOR;
  return NextResponse.json({ sessionId: crypto.randomUUID(), ...tpl });
}


