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
