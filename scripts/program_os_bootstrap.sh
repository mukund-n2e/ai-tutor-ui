#!/usr/bin/env bash
set -euo pipefail
REPO="/Users/mt/n2e-AI-tutor"
cd "$REPO"

mkdir -p docs/workpackets .github

# Status.md
cat > docs/Status.md <<'MD'
# Status

## Done
- Repo bootstrapped (Next.js, SSE proxy, validators).
- CI split into web + smoke; health + smoke wired; golden examples added.

## Next (3)
1. WP-001 — Repo audit + CI + security headers
2. WP-002 — Validators + tests (+ similarity gate)
3. WP-003 — SSE probe + WS fallback readiness

## Risks
- See docs/Risks.md
MD

# Risks.md
cat > docs/Risks.md <<'MD'
# Top Risks

- SSE buffering on CDN → flip tutor to WS; verify with sse-probe (owner: PM; next: probe UAT).
- Token cost overrun → enforce 4000 cap; UX clamps at 75% (owner: PM).
- Input/markdown safety regressions → server/client sanitize, unit tests (owner: PM).
- Missing secrets in CI → scope tests to avoid tutor calls; doc OPENAI_API_KEY usage (owner: PM).
- Branch protection misconfigured → require “ci / web” + “ci / smoke” (owner: PM).
MD

# Workpackets
mkdir -p docs/workpackets

# WP-001
cat > docs/workpackets/WP-001.md <<'MD'
# WP-001 — Repo audit + CI + security headers (≤90 min)

## Objective
Ensure CI + smoke are green and security headers are enforced end-to-end.

## Files
- Makefile (ensure `smoke` target)
- .github/workflows/ci.yml (jobs: `web`, `smoke`)
- web/next.config.ts (CSP + SSE headers)
- web/src/app/api/health/route.ts
- web/scripts/smoke.mjs
- docs/Status.md, docs/LOG.md (append entry)
- .github/pull_request_template.md

## Steps (edits)
1) Verify CSP and SSE headers exist in `web/next.config.ts` (present).
2) Ensure health route exists at `web/src/app/api/health/route.ts` (present).
3) Ensure smoke script at `web/scripts/smoke.mjs` (present).
4) Ensure Makefile has:
   - `smoke:` target → `cd web && node scripts/smoke.mjs`
5) Ensure CI (`.github/workflows/ci.yml`) has:
   - Job `web`: lint, typecheck, tests, build.
   - Job `smoke`: start server locally and run smoke; waits on `web`.
6) Add `.github/pull_request_template.md` with tests/checklists.
7) Update `docs/LOG.md` with action + commit SHA.

## Acceptance tests
- `npm ci && npm run build && npm run start &` (in `web/`), then `make smoke` returns `SMOKE OK`.
- `curl -sI http://localhost:3000/ | grep -i "content-security-policy"` shows `frame-ancestors 'none'`.
- `curl -sI "http://localhost:3000/api/tutor/stream?courseTitle=probe&scope=probe&message=hello"` shows:
  - `Content-Type: text/event-stream`
  - `Cache-Control: no-cache, no-transform`

## CI checks (required)
- “ci / web” (lint, typecheck, test, build) passes.
- “ci / smoke” passes.

## Rollback
Revert CI and Makefile changes; remove health/smoke only if needed.
MD

# WP-002
cat > docs/workpackets/WP-002.md <<'MD'
# WP-002 — Validators + tests (+ similarity gate) (≤90 min)

## Objective
Lock validator behavior with unit tests; add filename and markdown safety tests; implement tri‑gram Jaccard soft gate with goldens.

## Files
- web/src/lib/validators.ts (no behavior change; export types already present)
- web/src/lib/strings.ts (already has `sanitizeFilename`, `words`)
- web/src/lib/renderMarkdown.ts (already sanitizes)
- web/src/lib/similarity.ts (NEW)
- web/src/lib/golden/creator_yt_short.md (present)
- web/src/lib/golden/proposal_one_pager.md (present)
- web/tests/validators.test.ts (present)
- web/tests/strings.test.ts (NEW)
- web/tests/markdown.test.ts (NEW)
- web/tests/similarity.test.ts (NEW)

## Steps (edits)
1) Add `web/src/lib/similarity.ts`:
```ts
export const triGrams = (s: string) => {
  const t = s.toLowerCase().split(/\s+/).filter(Boolean);
  const out = new Set<string>();
  for (let i = 0; i < t.length - 2; i++) out.add(t.slice(i, i + 3).join(' '));
  return out;
};
export const jaccardTriGram = (a: string, b: string) => {
  const A = triGrams(a), B = triGrams(b);
  if (!A.size && !B.size) return 1;
  let inter = 0; for (const x of A) if (B.has(x)) inter++;
  const union = A.size + B.size - inter;
  return union ? inter / union : 0;
};
```
2) Add tests:
- `web/tests/strings.test.ts`
```ts
import { sanitizeFilename } from '@/lib/strings';
test('sanitizeFilename strips unsafe chars', () => {
  expect(sanitizeFilename('A/b? c.md')).toBe('A_b_c_md');
});
```
- `web/tests/markdown.test.ts`
```ts
import { safeMarkdown } from '@/lib/renderMarkdown';
test('safeMarkdown removes script tags', async () => {
  const html = await safeMarkdown('<script>alert(1)</script>**ok**');
  expect(html.toLowerCase()).not.toContain('<script');
  expect(html).toContain('<strong>ok</strong>');
});
```
- `web/tests/similarity.test.ts`
```ts
import { jaccardTriGram } from '@/lib/similarity';
test('tri-gram Jaccard threshold behaves', () => {
  const a = 'one two three four five six';
  const b = 'one two three seven eight nine';
  const sim = jaccardTriGram(a, b);
  expect(sim).toBeGreaterThan(0);
  expect(sim).toBeLessThan(1);
});
```

## Acceptance tests
- `npm test` passes; coverage includes validators, strings, markdown, similarity.
- Similarity function present and exported; threshold to be used by UI/Ship gate later (soft gate ≥ 0.35).

## CI checks
- Included in “ci / web” tests.
MD

# WP-003
cat > docs/workpackets/WP-003.md <<'MD'
# WP-003 — SSE probe + WS fallback readiness (≤90 min)

## Objective
Verify streaming cadence locally and document WS fallback switch.

## Files
- docs/sse-probe.sh, docs/sse-probe.md (present)
- web/src/lib/tutorTransport.ts (supports SSE/WS)
- web/src/components/TutorPanel.tsx (minor hardening)
- docs/RUNBOOK.md (update toggle steps)
- docs/Status.md, docs/LOG.md (update)

## Steps (edits)
1) Hardening (no-op on SSE, safe on missing WS URL):
- In `TutorPanel.tsx`, wrap `ask()` body with try/catch to avoid unhandled rejections in WS mode without URL:
```tsx
const ask = async () => {
  setBusy(true); setStream('');
  const onDelta = (t: string) => setStream((s) => s + t);
  try {
    if ((process.env.NEXT_PUBLIC_TUTOR_TRANSPORT || 'sse').toLowerCase() === 'ws') {
      await askWS({ scope, courseTitle, message: text }, onDelta);
    } else {
      await askSSE({ scope, courseTitle, message: text }, onDelta);
    }
  } catch (e) {
    console.debug('tutor transport failed', e);
  } finally {
    setBusy(false);
  }
};
```
2) Probe:
- Run: `bash docs/sse-probe.sh "http://localhost:3000/api/tutor/stream?courseTitle=probe&scope=probe&message=hello"`
- Observe inter-chunk cadence; target median ≤ 250ms (cold path).
3) RUNBOOK.md:
- Add: To flip to WS, set `NEXT_PUBLIC_TUTOR_TRANSPORT=ws` and `NEXT_PUBLIC_WS_URL=wss://<api-id>.execute-api.us-east-1.amazonaws.com/prod` then rebuild.
4) Log results in `docs/LOG.md` with timestamp + “SSE probe OK” and attach snippet in PR.

## Acceptance tests
- SSE probe output shows regular chunking (no big bursts).
- App continues to function with SSE; enabling WS without URL does not crash UI and logs a debug line.

## CI checks
- “ci / smoke” remains green.
MD

# PR template (idempotent write)
cat > .github/pull_request_template.md <<'MD'
## What
-

## Why
-

## Tests
- [ ] Unit tests updated/added
- [ ] Manual SSE probe run (attach output if tutor touched)

## Checklists
- [ ] Lint/typecheck pass
- [ ] Docs updated (README/RUNBOOK/ADR/LOG/Status)
- [ ] No secrets in code or logs
MD

# Append to LOG.md
printf -- "- %s — Program OS bootstrapped (Status, Risks, WPs, PR template) — @cursor\n" "$(date -u +"%Y-%m-%d %H:%M UTC")" >> docs/LOG.md

echo "WPs and Program OS docs created."

# Optional: branch protection (requires GH CLI + token)
if command -v gh >/dev/null 2>&1; then
  GH_REPO="${GH_REPO:-mukund-n2e/ai-tutor-web}"
  echo "Configuring branch protection on ${GH_REPO} (requires authenticated gh)..."
  gh api \
    -X PUT "repos/${GH_REPO}/branches/main/protection" \
    -H "Accept: application/vnd.github+json" \
    -F required_status_checks.strict=true \
    -F required_status_checks.contexts[]="ci / web" \
    -F required_status_checks.contexts[]="ci / smoke" \
    -F enforce_admins=true \
    -F required_pull_request_reviews.required_approving_review_count=1 \
    -F required_pull_request_reviews.dismiss_stale_reviews=true \
    -F restrictions= \
    -F required_linear_history=true || true
else
  echo "gh CLI not found — skipping branch protection config."
  echo "To set later: export GH_REPO=mukund-n2e/ai-tutor-web && gh auth login && re-run this script."
fi

git add -A
git commit -m "chore(program-os): add Status/Risks, WPs 001–003, PR template" || true
echo "Done."


