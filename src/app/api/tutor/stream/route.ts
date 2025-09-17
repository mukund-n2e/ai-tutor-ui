import type { NextRequest } from 'next/server';
import * as base from './route.base';

// --- Config (env-driven) ---
const TOKENS = Math.max(200, parseInt(process.env.SESSION_TOKEN_CAP ?? '1200', 10));
const CHARS_PER_TOKEN = Math.max(1, parseInt(process.env.CHARS_PER_TOKEN ?? '4', 10));
const CHAR_LIMIT = TOKENS * CHARS_PER_TOKEN;

// Make a TransformStream that counts approximate payload characters and ends the stream when cap is reached.
// It also emits a final SSE "cap" event so the client can show a friendly notice.
function makeCapTransform(limitChars: number) {
  const enc = new TextEncoder();
  const dec = new TextDecoder();
  let sent = 0;
  let announced = false;

  return new TransformStream<Uint8Array, Uint8Array>({
    transform(chunk, controller) {
      // Count payload-ish chars (ignore event/id/retry lines to avoid over-counting control frames)
      const text = dec.decode(chunk);
      const payloadish = text
        .replace(/^event:.*$/gm, '')
        .replace(/^id:.*$/gm, '')
        .replace(/^retry:.*$/gm, '');
      sent += payloadish.length;

      // Pass through what we have
      controller.enqueue(chunk);

      if (!announced && sent >= limitChars) {
        announced = true;
        const footer =
          `\n\nevent: cap\ndata: {"reason":"session_cap","capTokens":${TOKENS},"capChars":${limitChars}}\n\n`;
        controller.enqueue(enc.encode(footer));
        controller.terminate();
      }
    }
  });
}

async function wrapResponse(resp: Response): Promise<Response> {
  // Only wrap SSE responses with a body
  const ct = resp.headers.get('content-type') || '';
  if (!resp.body || !ct.includes('text/event-stream')) return resp;
  const capped = resp.body.pipeThrough(makeCapTransform(CHAR_LIMIT));
  // Preserve headers & status
  const headers = new Headers(resp.headers);
  return new Response(capped, { status: resp.status, statusText: resp.statusText, headers });
}

type Handler = (req: NextRequest) => Promise<Response> | Response;
type BaseHandlers = {
  GET?: Handler;
  POST?: Handler;
};

export async function GET(req: NextRequest) {
  const h: Handler | undefined = (base as BaseHandlers).GET;
  if (!h) return new Response('Not Found', { status: 404 });
  const res = await h(req);
  return wrapResponse(res);
}

export async function POST(req: NextRequest) {
  const h: Handler | undefined = (base as BaseHandlers).POST;
  if (!h) return new Response('Method Not Allowed', { status: 405 });
  const res = await h(req);
  return wrapResponse(res);
}
