import { NextRequest, NextResponse } from 'next/server';
import { asMarkdown } from '@/lib/export';
import { sanitizeFilename } from '@/lib/strings';

export async function POST(req: NextRequest) {
  try {
    const data = await req.json();
    if (data && (typeof data.title === 'string' || typeof data.body === 'string')) {
      const { filename, md } = asMarkdown({ title: data?.title ?? 'Untitled', body: data?.body ?? '' });
      return new NextResponse(md, {
        headers: {
          'Content-Type': 'text/markdown; charset=utf-8',
          'Content-Disposition': `attachment; filename="${filename}"`,
          'Cache-Control': 'no-store',
        },
      });
    }
    const artifact = String(data?.artifact ?? 'Draft');
    const context = String(data?.context ?? 'Draft');
    const markdown = String(data?.markdown ?? '# Draft');
    const date = new Date().toISOString().slice(0,10);
    const filename = `${sanitizeFilename(artifact)}_${sanitizeFilename(context)}_${date}.md`;
    return new NextResponse(markdown, {
      headers: {
        'Content-Type': 'text/markdown; charset=utf-8',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Cache-Control': 'no-store',
      },
    });
  } catch {
    return NextResponse.json({ ok: false, error: 'Bad JSON' }, { status: 400, headers: { 'Cache-Control': 'no-store' } });
  }
}


