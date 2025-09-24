export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET() {
  return Response.json(
    {
      beta: true,
      moves: ['Understand', 'Draft', 'Polish'],
      version: process.env.VERCEL_GIT_COMMIT_SHA ?? null,
      ts: new Date().toISOString(),
    },
    { headers: { 'Cache-Control': 'no-store' } }
  );
}

// bump: 2025-09-24T12:34:56.000Z
