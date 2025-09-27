import { NextResponse, type NextRequest } from 'next/server';

// Env knobs (defaults are conservative)
const WIN = parseInt(process.env.RL_WINDOW_SECONDS ?? '60', 10); // seconds
const MAX = parseInt(process.env.RL_MAX_REQUESTS   ?? '8', 10);  // req per window
const SECRET = process.env.NEXT_SERVER_ACTIONS_ENCRYPTION_KEY ?? 'dev-secret-insecure';

type RLState = { s: number; c: number }; // s=window start (epoch sec), c=count

const enc = new TextEncoder();
const dec = new TextDecoder();
let keyPromise: Promise<CryptoKey> | null = null;

function hmacKey() {
  if (!keyPromise) {
    keyPromise = crypto.subtle.importKey(
      'raw',
      enc.encode(SECRET),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );
  }
  return keyPromise;
}

function toB64Url(bytes: ArrayBuffer | Uint8Array) {
  const arr = bytes instanceof ArrayBuffer ? new Uint8Array(bytes) : bytes;
  let s = '';
  for (let i = 0; i < arr.length; i++) s += String.fromCharCode(arr[i]);
  return btoa(s).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');
}
function fromB64Url(b64u: string) {
  const b64 = b64u.replace(/-/g,'+').replace(/_/g,'/');
  const pad = b64.length % 4 === 2 ? '==' : b64.length % 4 === 3 ? '=' : '';
  const bin = atob(b64 + pad);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

async function signPayload(json: string) {
  const key = await hmacKey();
  const bytes = enc.encode(json);
  const sig = await crypto.subtle.sign('HMAC', key, bytes);
  return { payload: toB64Url(bytes), sig: toB64Url(sig) };
}

async function verify(payloadB64u: string, sigB64u: string) {
  const key = await hmacKey();
  const bytes = fromB64Url(payloadB64u);
  const expSig = await crypto.subtle.sign('HMAC', key, bytes);
  const a = fromB64Url(sigB64u);
  const b = new Uint8Array(expSig);
  if (a.length !== b.length) return false;
  let ok = 1;
  for (let i = 0; i < a.length; i++) ok &= (a[i] === b[i]) ? 1 : 0;
  return !!ok;
}

function nowSec() { return Math.floor(Date.now() / 1000); }

async function readState(cookieVal?: string | null): Promise<RLState> {
  if (!cookieVal) return { s: nowSec(), c: 0 };
  const [p, sig] = cookieVal.split('.');
  if (!p || !sig) return { s: nowSec(), c: 0 };
  const ok = await verify(p, sig);
  if (!ok) return { s: nowSec(), c: 0 };
  try {
    const obj = JSON.parse(dec.decode(fromB64Url(p))) as RLState;
    if (typeof obj.s === 'number' && typeof obj.c === 'number') return obj;
    return { s: nowSec(), c: 0 };
  } catch {
    return { s: nowSec(), c: 0 };
  }
}

async function writeState(res: NextResponse, st: RLState) {
  const json = JSON.stringify(st);
  const { payload, sig } = await signPayload(json);
  res.cookies.set({
    name: 'n2e_rl',
    value: `${payload}.${sig}`,
    httpOnly: true,
    path: '/',
    sameSite: 'lax',
    secure: true,
    maxAge: 7 * 24 * 3600
  });
}

export default async function middleware(req: NextRequest) {
  const pathname = req.nextUrl.pathname;

  // Guard /screens in production unless debug flag is on
  if (pathname.startsWith('/screens')) {
    const isProd = process.env.NODE_ENV === 'production';
    const debugOn = process.env.NEXT_PUBLIC_UI_DEBUG === '1';
    if (isProd && !debugOn) {
      return NextResponse.redirect(new URL('/', req.url));
    }
    return NextResponse.next();
  }

  // Rate-limit the SSE tutor stream endpoint
  if (pathname !== '/api/tutor/stream') {
    return NextResponse.next();
  }

  let st = await readState(req.cookies.get('n2e_rl')?.value);
  const now = nowSec();
  if (now - st.s >= WIN) st = { s: now, c: 0 };
  if (st.c >= MAX) {
    return new NextResponse(
      JSON.stringify({
        error: 'rate_limited',
        message: `Too many requests. Try again in ${Math.max(0, WIN - (now - st.s))}s.`,
        windowSeconds: WIN,
        maxRequests: MAX
      }),
      { status: 429, headers: { 'content-type': 'application/json' } }
    );
  }
  const res = NextResponse.next();
  await writeState(res, { s: st.s, c: st.c + 1 });
  return res;
}

export const config = { matcher: ['/api/tutor/stream', '/screens'] };
