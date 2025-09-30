# PRD — Executive Summary (Delivery Lens)

## Audience & Positioning
- **Audience:** non‑technical, non‑engineering learners in AU and IN (ROW supported via USD)
- **Promise:** “One skill. One small win. ~15 minutes.” Human, applied, simple.

## Levels (Access model)
1. **L1 — Learn AI, build confidence** (free) — no account required; capture email/mobile optionally
2. **L2 — Broad use-case skills** (paid)
3. **L3 — Profile-specific skills** (paid)
4. **L4 — Applying AI expertise** (paid; revisit pricing later)

### Pricing (annual, no monthly)
- L1: free
- L2: AU A$39 / IN ₹199 / ROW US$39
- L3: AU A$89 / IN ₹399 / ROW US$89
- L4: AU A$199 / IN ₹899 / ROW US$199 (placeholder; not in v1 scope)
- **Stripe** for both AU and IN; USD fallback for others.

## Product Scope (v1)
- **Marketing/Onboarding** → **Course Wall** → **Outline** → **Lesson Runner (0‑Form)** → **Checkout** → **Account** → **System pages**
- **Video playback** infra for demos/lessons (HLS streaming; abstracted provider)
- **Email** for magic‑link sign-in + refresher (opt‑in)
- **Analytics/observability**: page + CTA events, error logging

## Non‑Goals (v1)
- Native mobile apps
- Enterprise features (SSO, admin dashboards)

## Key Decisions / Constraints
- Web app only; responsive (360/768/1200). No app store payments.
- Tokenized design system; **no inline styles** in core components.
- Run on Vercel; CI with GitHub Actions; pre-commit + verify scripts enforce quality.
- AU/IN/ROW currency handling at checkout, with Stripe environment flags.

## Acceptance Criteria (v1)
- **UI routes present** and match frames/spec; a11y basics pass; tokens-only styling.
- **Checkout flow** creates Stripe session for L2/L3 (env present), friendly success/error pages.
- **Onboarding → Lesson** path works; **Recommended** courses on wall when `via=onboarding`.
- **Geo pricing** applied at UI + checkout param level; USD fallback for ROW.
- **Video** demo renders on landing and plays smoothly on mobile.
- **Observability**: console errors < 0.1% sessions; route timings captured.
