import { NextRequest, NextResponse } from 'next/server';
import { sanitizeFilename } from '@/lib/strings';

export async function POST(req: NextRequest) {
  const { artifact, context = 'Draft', markdown = '# Draft' } = await req.json();
  const date = new Date().toISOString().slice(0,10);
  const filename = `${sanitizeFilename(artifact)}_${sanitizeFilename(context)}_${date}.md`;
  return new NextResponse(markdown, {
    headers: {
      'Content-Type': 'text/markdown; charset=utf-8',
      'Content-Disposition': `attachment; filename="${filename}"`
    }
  });
}


