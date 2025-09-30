#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
MID="$APP_DIR/src/middleware.ts"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/wp003a_edge_fix_build_${TS}.log"
BR="wp003a-edge-mw-fix-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"
need npm || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"

mkdir -p "$(dirname "$MID")"

cat > "$MID" <<'TS'
import { NextResponse, type NextRequest } from 'next/server';

// Env knobs (defaults are conservative)
const WIN = parseInt(process.env.RL_WINDOW_SECONDS ?? '60', 10); // seconds
const MAX = parseInt(process.env.RL_MAX_REQUESTS   ?? '8', 10);  // req per window
const SECRET = process.env.NEXT_SERVER_ACTIONS_ENCRYPTION_KEY ?? 'dev-secret-insecure';

type RLState = { s: number; c: number }; // s=window start (epoch sec), c=count

const enc = new TextEncoder();
const dec = new TextDecoder();
let keyPromise: Promise<CryptoKey> | null = null;

// Import an HMAC-SHA-256 key using Web Crypto (Edge runtime safe)
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
  // constant-time-ish compare on Uint8Array
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
    sameSite: 'lax',     // NOTE: lowercase per ResponseCookie type
    secure: true,
    maxAge: 7 * 24 * 3600
  });
}

export async function middleware(req: NextRequest) {
  // Guard only the SSE endpoint
  if (req.nextUrl.pathname !== '/api/tutor/stream') {
    return NextResponse.next();
  }

  let st = await readState(req.cookies.get('n2e_rl')?.value);
  const now = nowSec();

  // rotate window if expired
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

// Only match the SSE route
export const config = {
  matcher: ['/api/tutor/stream']
};
TS

# Build check
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 120 "$BUILD_LOG" || true; exit 2; }

# Commit & PR
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$MID"
git commit -m "guard(sse): Edge-safe rate limiter (Web Crypto) + cookie typing fix" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";; https://github.com/*) GH_URL="$REMOTE";; *) GH_URL="";; esac
PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr create --head "$BR" --title "guard(sse): Edge WebCrypto rate limiter + sameSite typing fix" --body "Replace Node crypto with Web Crypto (Edge-safe), fix cookie sameSite to 'lax'.")" || true
fi

echo "=== CTO WP003a FIX SUMMARY START ==="
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "File: $MID"
echo "=== CTO WP003a FIX SUMMARY END ==="
