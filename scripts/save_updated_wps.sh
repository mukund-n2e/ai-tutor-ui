#!/usr/bin/env bash
set -euo pipefail
REPO="/Users/mt/n2e-AI-tutor"
cd "$REPO"

mkdir -p docs/workpackets

# WP-001
cat > docs/workpackets/WP-001.md <<'MD'
# WP-001 — Foundation boots (Repo audit + CI + security headers + health route) — ≤90 min

## Objective
Make the repo shippable: CI green, CSP correct, health and smoke in place. Produce evidence for Checkpoint 1.

## Good looks like (Checkpoint 1)
- Next.js app in `web/`; CSP includes `frame-ancestors 'none'`.
- `/api/health` returns `{ ok: true }`.
- CI (Node 20) runs lint + typecheck + test + build and passes.
- Smoke test runs locally and in CI; verifies CSP + SSE headers.
- `docs/Status.md` updated; `docs/LOG.md` shows PR + commit SHAs.

## Files to touch
- `web/next.config.ts` (verify CSP + SSE headers present)
- `web/src/app/api/health/route.ts` (present)
- `web/scripts/smoke.mjs` (present)
- `Makefile` (`smoke` target present)
- `.github/workflows/ci.yml` (jobs: `web`, `smoke`)
- `web/.env.local.example` (NEW template)
- `docs/Status.md`, `docs/LOG.md` (append)
- `.github/pull_request_template.md` (present)

## Steps
1) Add `web/.env.local.example` with:
   - `OPENAI_API_KEY=`
   - `SESSION_TOKEN_CAP=4000`
   - `NEXT_PUBLIC_TUTOR_TRANSPORT=sse`
2) Verify CSP/SSE headers in `web/next.config.ts`:
   - Must include `frame-ancestors 'none'`.
   - `/api/tutor/stream` adds `text/event-stream`, `no-cache, no-transform`, `keep-alive`.
3) Local smoke (prod build):
   - `(cd web && npm run build && npm run start &) && sleep 5`
   - `make smoke` → must print `SMOKE OK`
4) CI: confirm “ci / web” and “ci / smoke” are green on the PR.
5) Docs: update `docs/Status.md`; append `docs/LOG.md` with commit SHA.
6) PR evidence: paste `make smoke` output; link CI run; paste `curl -sI / | grep content-security-policy`.

## Acceptance tests
- `make smoke` returns `SMOKE OK` locally.
- CI “ci / web” and “ci / smoke” green.
- `/api/health` returns `{ ok: true }`.

## Out of scope
- Validators or WS fallback; defer to WP‑002/003.
MD

# WP-002
cat > docs/workpackets/WP-002.md <<'MD'
# WP-002 — Quality teeth in (Validators + one-tap fixes + tests + goldens) — ≤90 min

## Objective
Lock validator behavior with unit tests and goldens. Produce evidence for Checkpoint 2.

## Good looks like (Checkpoint 2)
- YT checks: `hook_pattern_tag`, `beats_count` (5–7, ≤12 words), `cta_words` (2–8), `duration_total ≤60s`, `payoff_present`, soft “>12s shot”.
- Proposal checks: `kpi_present`, `options_mece (2–3 A/B/C + trade-off)`, `scope_verbs (3–5)`, `timeline_present` (future, Week‑N resolved), `price_valid`.
- One‑tap fix helpers for both tracks.
- Vitest tests pass with coverage; goldens in `web/src/lib/golden/`.
- Markdown sanitizer used in export/preview.

## Files to touch
- `web/src/lib/validators.ts` (confirm rules + fix helpers)
- `web/src/lib/strings.ts` (already has helpers)
- `web/src/lib/renderMarkdown.ts` (sanitizer present)
- `web/src/lib/similarity.ts` (NEW: tri‑gram Jaccard)
- `web/tests/validators.test.ts` (extend if needed)
- `web/tests/strings.test.ts` (NEW)
- `web/tests/markdown.test.ts` (NEW)
- `web/tests/similarity.test.ts` (NEW)
- `web/src/lib/golden/creator_yt_short.md`, `.../proposal_one_pager.md` (present)

## Steps
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
3) Verify `validators.ts` matches the spec; extend tests if needed.
4) Docs: update `docs/Status.md`; append `docs/LOG.md` with commit SHA.

## Acceptance tests
- `npm test` green; coverage includes validators, strings, markdown, similarity.
- Goldens present under `web/src/lib/golden/`.

## Evidence in PR comment
- Coverage summary from `vitest`.
- Links to golden files.
- Short GIF/screenshot: failing validator → apply one‑tap fix → pass.

## Out of scope
- Enforcing the similarity gate in Ship flow (keep soft gate documented).
MD

# WP-003
cat > docs/workpackets/WP-003.md <<'MD'
# WP-003 — Fast loop proven (SSE probe + WS fallback + token cap + out-of-scope + Try sample) — ≤90–120 min

## Objective
Prove streaming cadence and UX readiness. Produce evidence for Checkpoint 3.

## Good looks like (Checkpoint 3)
- SSE probe median inter‑chunk ≤ 250ms (cold path) recorded in `docs/LOG.md`; else WS fallback deployed and working.
- Token cap: `SESSION_TOKEN_CAP=4000` with 75% banner → short replies → Ship now → block further turns.
- Out‑of‑scope switch offers the correct next micro‑course with carried intake.
- “Try sample” works end‑to‑end for Creator and Consultant; Copy‑All and `.md` export present.

## Files to touch
- `docs/sse-probe.sh`, `docs/sse-probe.md`
- `web/src/lib/tutorTransport.ts` (SSE/WS supported)
- `web/src/components/TutorPanel.tsx` (cap banner + out‑of‑scope UX)
- `web/src/lib/analytics.ts` (emit key events)
- `web/src/app/api/export/route.ts`
- `docs/RUNBOOK.md`, `docs/Status.md`, `docs/LOG.md`

## Steps
1) SSE probe locally:
   - `bash docs/sse-probe.sh "http://localhost:3000/api/tutor/stream?courseTitle=probe&scope=probe&message=hello"`
   - Capture timings; compute median.
2) Decide transport:
   - If median ≤ 250ms, keep SSE.
   - Else set `NEXT_PUBLIC_TUTOR_TRANSPORT=ws` and `NEXT_PUBLIC_WS_URL=wss://...`, rebuild.
3) Token cap UX:
   - Track approx tokens (chars/4). At 75%: banner; at cap: short replies + Ship now + block turns.
4) Out‑of‑scope flow:
   - Show: “That’s beyond this {{Artifact}}. Switch to {{NextCourse}} now? (Yes/No)”
   - Creator → “Repurpose to IG Reel/TikTok” or “Hook Rewrite Clinic”.
   - Consultant → “Follow‑up Email Pack” or “SOW Draft”.
   - On Yes: create new session with carried intake.
5) Try sample:
   - Provide sample intakes for both tracks; confirm export works.
6) Analytics (stub):
   - Emit: `course_started`, `first_token_received`, `validator_passed`, `artifact_shipped`, `validator_time_ms`, `time_to_ship_ms`, `ship_quality_thumb`.
7) Docs:
   - Append probe snippet + median to `docs/LOG.md`; update `docs/RUNBOOK.md` with WS toggle; update `docs/Status.md`.

## Acceptance tests
- Probe evidence shows SSE ≤ 250ms median or WS fallback working.
- Token‑cap banner at ~75%; cap behavior enforced.
- Out‑of‑scope switch flows correctly.
- “Try sample” completes for both tracks; export works.

## Evidence in PR comment
- Probe log (first lines) + median.
- Screenshots: token‑cap banner, blocked turn, out‑of‑scope switch.
- Two short videos: Creator + Consultant to Ship.
MD

# Commit on a separate docs branch and open PR
if git rev-parse --verify docs/update-wps >/dev/null 2>&1; then
  git checkout docs/update-wps
else
  git checkout -b docs/update-wps
fi

printf -- "- %s — Updated WPs 001–003 aligned to checkpoints — @cursor\n" "$(date -u +"%Y-%m-%d %H:%M UTC")" >> docs/LOG.md
git add docs/workpackets/WP-001.md docs/workpackets/WP-002.md docs/workpackets/WP-003.md docs/LOG.md
git commit -m "docs(wp): align WP-001..003 to checkpoints & evidence"
git push -u origin docs/update-wps || true

if command -v gh >/dev/null 2>&1; then
  gh pr create -B main -H docs/update-wps -t "docs(wp): align WP-001..003 to checkpoints & evidence" -b "Updates workpackets to match Checkpoints 1–3 with Good looks like, acceptance tests, and evidence requirements."
else
  echo "gh CLI not found — open PR manually from branch docs/update-wps."
fi

echo "Saved WPs and opened PR."


