import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  return NextResponse.json({ ok: true }, {
    headers: {
      'Cache-Control': 'no-store'
    }
  });
}

export async function GET() {
  return new Response(JSON.stringify({ ok: true, ts: new Date().toISOString() }), {
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'x-robots-tag': 'noindex'
    }
  });
}
