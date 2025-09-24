import type { NextRequest } from 'next/server';
import { Document, HeadingLevel, Packer, Paragraph } from 'docx';

export const runtime = 'nodejs';

export async function POST(req: NextRequest) {
  try {
    let title: string = 'Session';
    let content: string = '';

    // Robust body parsing to tolerate different content-types and clients
    const ctype = req.headers.get('content-type') || '';
    try {
      if (ctype.includes('application/json')) {
        const body = await req.json();
        title = String(body?.title ?? title);
        content = String(body?.content ?? content);
      } else if (ctype.includes('application/x-www-form-urlencoded')) {
        const text = await req.text();
        const params = new URLSearchParams(text);
        title = String(params.get('title') ?? title);
        content = String(params.get('content') ?? content);
      } else {
        const text = await req.text();
        try {
          const body: unknown = JSON.parse(text);
          if (body && typeof body === 'object') {
            const obj = body as Record<string, unknown>;
            const maybeTitle = obj.title;
            const maybeContent = obj.content;
            if (typeof maybeTitle === 'string') title = maybeTitle;
            if (typeof maybeContent === 'string') content = maybeContent;
          }
        } catch {
          // treat raw text as content
          content = text || content;
        }
      }
    } catch {
      // Fallback: best-effort text parse; keep defaults if empty
      try {
        const text = await req.text();
        content = text || content;
      } catch {}
    }

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
    const u8 = new Uint8Array(buf);
    return new Response(u8, {
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
