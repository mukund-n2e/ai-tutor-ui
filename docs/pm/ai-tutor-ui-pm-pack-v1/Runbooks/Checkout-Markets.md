# Module Runbook — Checkout & Markets

**Goal:** Market-aware pricing with Stripe checkout.

## Steps
- Map AU/IN/ROW → currency symbol + Stripe price IDs (env)
- Toggle INR with `STRIPE_ENABLE_INR`
- Server route creates Checkout Session
- Success/Error pages display plan, CTA to start

## Verify
- UI: symbol switches A$/₹/US$
- API: missing env → friendly 400; with env → session URL returned
- E2E: play through success (mock) and error
