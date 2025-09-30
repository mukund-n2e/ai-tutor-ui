# One-Shot Runbook (UI → Live without Stripe)

1) Push clean UI repo to GitHub; enable Actions
2) Run `npm ci && npm run verify:ui || true && npm run build`
3) Create Vercel project, pull env, build and deploy preview
4) Confirm routes: `/`, `/onboarding`, `/wall`, `/lesson/L1-05/outline`, `/pricing`, `/account`, `/legal/*`
5) Add video provider abstraction; wire landing demo
6) Seed course data JSON; render wall from JSON
7) When Stripe keys ready, add to env; test /api/checkout

Stop on any failure. Do not “retry until green” without a code fix or config fix + note.
