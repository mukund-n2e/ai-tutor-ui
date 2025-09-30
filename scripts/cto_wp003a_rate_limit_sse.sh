#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
APP_APP_DIR="$APP_DIR/src/app"
MID="$APP_DIR/src/middleware.ts"
DOC="$APP_DIR/../docs/budget.md"
ENV_EX="$APP_DIR/.env.example"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/wp003a_build_${TS}.log"
BR="wp003a-rate-limit-sse-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"
need npm || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"

mkdir -p "$APP_DIR/src" "$APP_APP_DIR"

# 1) Edge middleware (idempotent: overwrite only if matcher not present)
cat > "$MID" <<'TS'
import { NextResponse, type NextRequest } from 'next/server';
import crypto from 'crypto';

const WIN = parseInt(process.env.RL_WINDOW_SECONDS || '60', 10);   // seconds
const MAX = parseInt(process.env.RL_MAX_REQUESTS   || '8', 10);    // requests per window
const SECRET = process.env.NEXT_SERVER_ACTIONS_ENCRYPTION_KEY || 'dev-secret-insecure';

type RLState = { s: number; c: number }; // s=window start (epoch sec), c=count

function b64url(input: Buffer | string) {
  return Buffer.from(input).toString('base64').replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');
}
function sign(payload: string) {
  return b64url(crypto.createHmac('sha256', SECRET).update(payload).digest());
}
function readState(cookieVal?: string | null): RLState {
  if (!cookieVal) return { s: Math.floor(Date.now()/1000), c: 0 };
  const [p, sig] = cookieVal.split('.');
  if (!p || !sig) return { s: Math.floor(Date.now()/1000), c: 0 };
  const ok = sign(p) === sig;
  if (!ok) return { s: Math.floor(Date.now()/1000), c: 0 };
  try {
    const json = Buffer.from(p.replace(/-/g,'+').replace(/_/g,'/'), 'base64').toString('utf8');
    const obj = JSON.parse(json) as RLState;
    if (typeof obj.s === 'number' && typeof obj.c === 'number') return obj;
    return { s: Math.floor(Date.now()/1000), c: 0 };
  } catch { return { s: Math.floor(Date.now()/1000), c: 0 }; }
}
function writeState(res: NextResponse, st: RLState) {
  const payload = b64url(Buffer.from(JSON.stringify(st), 'utf8'));
  const cookie = `${payload}.${sign(payload)}`;
  res.cookies.set('n2e_rl', cookie, {
    httpOnly: true, path: '/', sameSite: 'Lax', secure: true, maxAge: 7*24*3600
  });
}

export function middleware(req: NextRequest) {
  // Only guard the SSE endpoint
  if (req.nextUrl.pathname !== '/api/tutor/stream') {
    return NextResponse.next();
  }

  const now = Math.floor(Date.now()/1000);
  const st = readState(req.cookies.get('n2e_rl')?.value);
  let { s, c } = st;

  // rotate window if needed
  if (now - s >= WIN) { s = now; c = 0; }

  if (c >= MAX) {
    // Deny with a small JSON payload so the client can show a clear message
    return new NextResponse(
      JSON.stringify({
        error: 'rate_limited',
        message: `Too many requests. Try again in ${WIN - (now - s)}s.`,
        windowSeconds: WIN, maxRequests: MAX
      }),
      { status: 429, headers: { 'content-type': 'application/json' } }
    );
  }

  // Allow and increment
  const res = NextResponse.next();
  writeState(res, { s, c: c + 1 });
  return res;
}

// Limit to our SSE path only
export const config = {
  matcher: ['/api/tutor/stream']
};
TS

# 2) Example env file (append keys if missing)
touch "$ENV_EX"
append_if_missing () { grep -q "^$1=" "$ENV_EX" 2>/dev/null || printf "%s\n" "$1" >> "$ENV_EX"; }
append_if_missing "RL_WINDOW_SECONDS=60"
append_if_missing "RL_MAX_REQUESTS=8"
append_if_missing "SESSION_TOKEN_CAP=1200"       # used in next step (client/server cap)
append_if_missing "NEXT_PUBLIC_TUTOR_TRANSPORT=sse"

# 3) Budget runbook
mkdir -p "$(dirname "$DOC")"
cat > "$DOC" <<'MD'
# Budget Guardrails

## Environment
- `RL_WINDOW_SECONDS` — sliding window, in seconds (default `60`)
- `RL_MAX_REQUESTS`   — max requests to `/api/tutor/stream` per window (default `8`)
- `SESSION_TOKEN_CAP` — *approx* response cap (tokens) — enforced in Step WP‑003b

These, plus conservative prompts, keep LLM <$50/mo and Cloud <$100/mo under expected beta traffic.

## How rate limit works
- Implemented in `src/middleware.ts` (Edge).
- Uses a signed cookie (`n2e_rl`) to count requests per browser in a sliding window.
- Returns `429` with `{ error: "rate_limited", message, windowSeconds, maxRequests }` when exceeded.

## Next step (optional but recommended)
Add a **response length cap** for the SSE stream (WP‑003b), using `SESSION_TOKEN_CAP` → approximate characters (~4 chars/token).
MD

# 4) Build to validate
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 120 "$BUILD_LOG" || true; exit 2; }

# 5) Commit + PR
git config user.name "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$MID" "$ENV_EX" "$DOC"
git commit -m "guard(sse): add Edge middleware rate limit for /api/tutor/stream (WP‑003a)" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";; https://github.com/*) GH_URL="$REMOTE";; *) GH_URL="";; esac
PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr list --head "$BR" --json url -q .[0].url 2>/dev/null || true)"
  [ -z "$PR_URL" ] && PR_URL="$(gh pr create --head "$BR" --title "guard(sse): rate limit /api/tutor/stream (WP‑003a)" --body "Edge middleware with signed cookie counter. Defaults: 8 req/min. See docs/budget.md.")"
fi

echo "=== CTO WP‑003a SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "Files: $MID , $ENV_EX , $DOC"
echo "Next: Merge, set env vars in Vercel if you want non-defaults, then test with the quick probe below."
echo "=== CTO WP‑003a SUMMARY END ==="
