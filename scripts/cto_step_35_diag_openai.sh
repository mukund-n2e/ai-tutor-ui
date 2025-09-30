#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="https://tutorweb-cyan.vercel.app"

# Create a tiny diag route that calls OpenAI with the same model & headers
mkdir -p web/src/app/api/diag/openai
cat > web/src/app/api/diag/openai/route.ts <<'TS'
export async function GET() {
  const key = process.env.OPENAI_API_KEY || '';
  const org = process.env.OPENAI_ORG_ID;
  const proj = process.env.OPENAI_PROJECT;
  try {
    const r = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${key}`,
        ...(org ? { 'OpenAI-Organization': org } : {}),
        ...(proj ? { 'OpenAI-Project': proj } : {}),
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [{ role: 'user', content: 'ping' }]
      })
    });
    const text = await r.text();
    return new Response(JSON.stringify({ ok: r.ok, status: r.status, body: text.slice(0, 2000) }), {
      status: 200, headers: { 'Content-Type': 'application/json' }
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 200, headers: { 'Content-Type': 'application/json' }
    });
  }
}
TS

# Deploy and probe
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null
vercel deploy --prod --scope "$TEAM" >/dev/null
curl -sS "$ALIAS/api/diag/openai" | sed -n '1,120p'
echo
