#!/usr/bin/env bash
set -euo pipefail

# 1) Overwrite the SSE route with a simple, explicit OpenAI passthrough.
cat > web/src/app/api/tutor/stream/route.ts <<'TS'
import type { NextRequest } from 'next/server';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const maxDuration = 60;

function sseError(msg: string) {
  const enc = new TextEncoder();
  return new Response(new ReadableStream({
    start(ctrl) {
      ctrl.enqueue(enc.encode(`event: error\n`));
      ctrl.enqueue(enc.encode(`data: ${JSON.stringify({ error: msg })}\n\n`));
      ctrl.close();
    }
  }), {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-transform',
      'Connection': 'keep-alive',
    }
  });
}

async function handler(req: NextRequest) {
  const url = new URL(req.url);
  let message = url.searchParams.get('message') || '';
  let courseTitle = url.searchParams.get('courseTitle') || '';
  let scope = url.searchParams.get('scope') || '';

  if (req.method === 'POST') {
    try {
      const j = await req.json();
      message = j?.message ?? message;
      courseTitle = j?.courseTitle ?? courseTitle;
      scope = j?.scope ?? scope;
    } catch {}
  }

  const key = process.env.OPENAI_API_KEY || '';
  if (!key) return sseError('missing OPENAI_API_KEY');

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${key}`,
  };
  if (process.env.OPENAI_ORG_ID) headers['OpenAI-Organization'] = String(process.env.OPENAI_ORG_ID);
  if (process.env.OPENAI_PROJECT) headers['OpenAI-Project'] = String(process.env.OPENAI_PROJECT);

  const sys = `You are the course tutor for ${courseTitle}.
Stay strictly within this scope: ${scope}.
If asked outside scope, say what's out of scope and suggest the next micro-course.`;

  const upstream = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers,
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      stream: true,
      temperature: 0.3,
      messages: [
        { role: 'system', content: sys },
        { role: 'user', content: message }
      ]
    })
  });

  // Try to capture any error body for visibility
  let errSnippet = '';
  try { if (!upstream.ok) errSnippet = (await upstream.clone().text()).slice(0, 500); } catch {}

  if (!upstream.ok || !upstream.body) {
    return sseError(`status=${upstream.status} ${errSnippet}`);
  }

  // Pass-through the provider's SSE stream as-is
  return new Response(upstream.body, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-transform',
      'Connection': 'keep-alive',
    }
  });
}

export async function GET(req: NextRequest)  { return handler(req); }
export async function POST(req: NextRequest) { return handler(req); }
TS

# 2) Commit and push (Vercel will auto-deploy via Git integration).
git add web/src/app/api/tutor/stream/route.ts
git commit -m "fix(sse): direct OpenAI passthrough + error detail; runtime=nodejs"
git push origin HEAD
