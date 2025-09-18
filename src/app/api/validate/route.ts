import type { NextRequest } from 'next/server';

type Verdict = 'pass' | 'soft' | 'fix';
type Result = { status: Verdict; score: number; suggestions: string[] };

function validateText(text: string): Result {
  const t = (text || '').trim();
  if (!t) return { status: 'fix', score: 0, suggestions: ['Add your draft before validating.'] };

  const len = t.length;
  const bullets = (t.match(/^\s*[-*•]/gm) || []).length;
  const headings = (t.match(/^#{1,3}\s+/gm) || []).length;
  const fillerHits = (t.match(/\b(very|just|really|nice|basically|literally)\b/gi) || []).length;

  let score = 0;
  if (len >= 400) score += 2;
  if (bullets >= 3) score += 2;
  if (headings >= 1) score += 1;
  if (fillerHits > 5) score -= 2;

  let status: Verdict = 'soft';
  if (score >= 3) status = 'pass';
  else if (score <= 0) status = 'fix';

  const suggestions: string[] = [];
  if (len < 300) suggestions.push('Add 2–3 concrete details or examples.');
  if (bullets < 3) suggestions.push('Use 3–6 bullets to front‑load actions.');
  if (fillerHits > 5) suggestions.push('Trim filler words (very/just/really).');
  if (headings === 0) suggestions.push('Add one short heading for scannability.');

  return { status, score, suggestions };
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const text: string = String(body?.text ?? '');
    const format: string | undefined = body?.format ? String(body.format) : undefined;
    const base = validateText(text);
    // Format-specific hooks (placeholder)
    if (format === 'proposal' && !/budget|timeline/i.test(text)) {
      base.status = base.status === 'pass' ? 'soft' : base.status;
      base.suggestions.push('For proposals, mention budget and timeline.');
    }
    return Response.json(base);
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: msg }), { status: 400, headers: { 'Content-Type': 'application/json' } });
  }
}

export function GET() {
  return new Response('Method Not Allowed', { status: 405 });
}
