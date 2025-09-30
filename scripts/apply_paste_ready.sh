#!/usr/bin/env bash
set -euo pipefail
REPO="/Users/mt/n2e-AI-tutor"
cd "$REPO"

mkdir -p web/src/app/api/health web/scripts web/src/lib/golden .github/workflows

# A) Health route
cat > web/src/app/api/health/route.ts <<'TS'
export async function GET() {
  return new Response(JSON.stringify({ ok: true, ts: new Date().toISOString() }), {
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'x-robots-tag': 'noindex'
    }
  });
}
TS

# B) Smoke script
cat > web/scripts/smoke.mjs <<'JS'
const base = process.env.SMOKE_URL || 'http://localhost:3000';
const fetchJson = async (p) => (await fetch(base + p)).json();
const fetchHead = async (p) => {
  const res = await fetch(base + p, { method: 'GET' });
  return { ok: res.ok, headers: res.headers, status: res.status };
};

(async () => {
  const health = await fetchJson('/api/health');
  if (!health?.ok) throw new Error('Health failed');

  const { headers: h1, ok: ok1 } = await fetchHead('/');
  if (!ok1) throw new Error('Landing failed');
  const csp = h1.get('content-security-policy') || '';
  if (!csp.includes("frame-ancestors 'none'")) throw new Error('CSP missing frame-ancestors none');

  const { headers: hs, status } = await fetchHead('/api/tutor/stream?courseTitle=probe&scope=probe&message=hello');
  if (status !== 200) throw new Error('Stream route not reachable');
  const ct = hs.get('content-type') || '';
  const cc = hs.get('cache-control') || '';
  if (!ct.includes('text/event-stream')) throw new Error('SSE content-type missing');
  if (!cc.includes('no-transform')) throw new Error('SSE cache-control missing no-transform');

  console.log('SMOKE OK');
})().catch((e) => { console.error('SMOKE FAIL:', e.message); process.exit(1); });
JS

# C) Golden examples
cat > web/src/lib/golden/creator_yt_short.md <<'MD'
# Title: 3 Excel Tricks You’ll Use Today
## Hook
[Pattern: Before/After] This one shortcut doubled my spreadsheet speed.
## Beat Sheet
1. Problem: slow, manual edits
2. Trick 1: flash fill demo
3. Trick 2: alt+enter for clean lines
4. Trick 3: ctrl+; for today’s date
5. Payoff: save 10 min per sheet
6. CTA: try on your tracker now
## Shot List
- Hands close-up — 4s — “Flash Fill”
- Screen crop — 8s — “Alt+Enter”
- Keys overlay — 8s — “Ctrl+;”
- Before/After split — 10s — “Time saved”
- Face/desk — 6s — “Your turn”
## CTA
Try this on your tracker now
MD

cat > web/src/lib/golden/proposal_one_pager.md <<'MD'
# Proposal: ACME Demo Lift
## KPI
Increase qualified demos from 22→35/week by Dec 15.
## Options (A/B/C)
- Option A — Audit + quick wins (USD $3k–$5k) — Trade-off: limited depth
- Option B — Funnel rebuild (USD $7k–$10k) — Trade-off: longer timeline
- Option C — Rebuild + SDR playbook (USD $12k–$15k) — Trade-off: higher lift
## Scope
- Map current funnel and data sources
- Draft new demo request form & routing
- Implement lead scoring v1
- Train SDR on new playbook
## Timeline
Start: Week 1 • Milestone: Week 2 handoff • End: Week 3 go-live
## Investment & Next Step
USD $7k–$10k (Option B). Next: Book a 30-min kickoff this week.
Similarity gate: Jaccard tri-gram ≥ 0.35 (soft; allow one auto-regen if lower).
MD

# D) Makefile target (idempotent)
if ! grep -qE '^\s*smoke:\s*$' Makefile; then
  printf '\nsmoke:\n\tcd web && node scripts/smoke.mjs\n' >> Makefile
fi

# E) CI workflow (backup then write)
[ -f .github/workflows/ci.yml ] && cp .github/workflows/ci.yml .github/workflows/ci.yml.bak || true
cat > .github/workflows/ci.yml <<'YML'
name: ci
on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]
jobs:
  web:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: web
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: 'web/package-lock.json'
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test -- --coverage
      - run: npm run build
  smoke:
    needs: web
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: 'web/package-lock.json'
      - run: npm ci
        working-directory: web
      - run: npm run build
        working-directory: web
      - run: npm run start &
        working-directory: web
      - name: Wait for server
        run: |
          for i in {1..30}; do curl -sSf http://localhost:3000/api/health && break; sleep 2; done
      - name: Smoke
        run: SMOKE_URL=http://localhost:3000 make smoke
        working-directory: .
YML

# F) OUTPUT POLICY line in charter (idempotent)
CHARTER="Project_Kickoff/cursor_execution_charter_web_mvp_v_4.md"
if ! grep -q "OUTPUT POLICY — No inner monologue" "$CHARTER"; then
  tmp="$(mktemp)"
  awk '{
    print;
    if ($0 == "# Cursor Execution Charter — Web MVP v4") {
      print "OUTPUT POLICY — No inner monologue. Only plans/commands/diffs/tests/commits. Ask questions ONLY for missing credentials.";
    }
  }' "$CHARTER" > "$tmp" && mv "$tmp" "$CHARTER"
fi

# G) Log entry
printf -- "- %s — Added health route, smoke script/job, goldens, OUTPUT POLICY — @cursor\n" "$(date -u +"%Y-%m-%d %H:%M UTC")" >> docs/LOG.md

git add -A
git commit -m "feat(smoke): add health route, smoke script/job, golden examples, and OUTPUT POLICY" || true

echo "Done. Next: make setup && make dev  |  make smoke"

