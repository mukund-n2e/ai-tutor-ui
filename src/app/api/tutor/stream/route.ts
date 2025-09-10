import { NextRequest } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const message = searchParams.get('message') || '';
  const scope = searchParams.get('scope') || '';
  const courseTitle = searchParams.get('courseTitle') || '';

  const sys = `You are the course tutor for ${courseTitle}.\nStay strictly within this scope: ${scope}.\nIf asked outside scope, say what's out of scope and suggest the next micro-course.`;

  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      const resp = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          stream: true,
          temperature: 0.3,
          messages: [ { role: 'system', content: sys }, { role: 'user', content: message } ]
        })
      });

      if (!resp.ok || !resp.body) {
        controller.enqueue(encoder.encode(`event: error\ndata: {"error":"upstream"}\n\n`));
        controller.close();
        return;
      }

      const reader = resp.body.getReader();
      let buf = '';
      controller.enqueue(encoder.encode(`event: open\ndata: {}\n\n`));

      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        buf += new TextDecoder().decode(value, { stream: true });
        const parts = buf.split('\n\n');
        buf = parts.pop() || '';
        for (const p of parts) {
          if (!p.startsWith('data:')) continue;
          const json = p.replace(/^data:\s*/, '').trim();
          if (json === '[DONE]') { controller.enqueue(encoder.encode(`event: done\ndata: {}\n\n`)); break; }
          try {
            const obj = JSON.parse(json);
            const delta = obj.choices?.[0]?.delta?.content || '';
            if (delta) controller.enqueue(encoder.encode(`data: ${JSON.stringify({ delta })}\n\n`));
          } catch {}
        }
      }
      controller.enqueue(encoder.encode(`event: done\ndata: {}\n\n`));
      controller.close();
    }
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-transform',
      Connection: 'keep-alive'
    }
  });
}


