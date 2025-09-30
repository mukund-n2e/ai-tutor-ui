#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
ROUTE_DIR="$APP_DIR/src/app/api/tutor/stream"
ROUTE_TS="$ROUTE_DIR/route.ts"
BASE_TS="$ROUTE_DIR/route.base.ts"
ENV_EX="$APP_DIR/.env.example"

LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/wp003b_cap_build_${TS}.log"
BR="wp003b-sse-cap-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"
need npm || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"

mkdir -p "$ROUTE_DIR"

# 0) Ensure env example has caps
touch "$ENV_EX"
grep -q "^SESSION_TOKEN_CAP=" "$ENV_EX" 2>/dev/null || echo "SESSION_TOKEN_CAP=1200" >> "$ENV_EX"
grep -q "^CHARS_PER_TOKEN=" "$ENV_EX" 2>/dev/null || echo "CHARS_PER_TOKEN=4" >> "$ENV_EX"

# 1) Move existing route to route.base.ts (idempotent)
if [ -f "$ROUTE_TS" ] && [ ! -f "$BASE_TS" ]; then
  cp "$ROUTE_TS" "$BASE_TS"
fi

# 2) Write wrapper route.ts that calls the base handler and caps the SSE stream
cat > "$ROUTE_TS" <<'TS'
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

type Handler = (req: Request) => Promise<Response> | Response;

export async function GET(req: NextRequest) {
  const h = (base as any).GET as Handler | undefined;
  if (!h) return new Response('Not Found', { status: 404 });
  const res = await h(req as any);
  return wrapResponse(res);
}

export async function POST(req: NextRequest) {
  const h = (base as any).POST as Handler | undefined;
  if (!h) return new Response('Method Not Allowed', { status: 405 });
  const res = await h(req as any);
  return wrapResponse(res);
}
TS

# 3) Build to validate
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 160 "$BUILD_LOG" || true; exit 2; }

# 4) Commit + PR
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$ROUTE_TS" "$BASE_TS" "$ENV_EX"
git commit -m "guard(sse): cap streamed response (~SESSION_TOKEN_CAP tokens) with final 'cap' event (WP‑003b)" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac

PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr list --head "$BR" --json url -q .[0].url 2>/dev/null || true)"
  [ -z "$PR_URL" ] && PR_URL="$(gh pr create --head "$BR" --title "guard(sse): output cap for /api/tutor/stream (WP‑003b)" --body "Wraps base SSE handler and terminates stream once ~SESSION_TOKEN_CAP tokens are sent. Emits an SSE 'cap' event before closing.\n\nDefaults: SESSION_TOKEN_CAP=1200, CHARS_PER_TOKEN=4.")"
fi

echo "=== CTO WP003b CAP SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "Files: $ROUTE_TS (wrapper), $BASE_TS (original), $ENV_EX"
echo "=== CTO WP003b CAP SUMMARY END ==="
