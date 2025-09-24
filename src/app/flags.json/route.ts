export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET() {
  return Response.json(
    {
      beta: true,
      moves: ['Understand', 'Draft', 'Polish'],
      ts: new Date().toISOString(),
    },
    { headers: { 'Cache-Control': 'no-store' } }
  );
}


