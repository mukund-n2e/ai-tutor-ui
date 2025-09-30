# AI Tutor — UI (clean cut)

This repo contains only the UI (Next.js App Router) extracted from the release candidate tag.
- Design tokens at `src/styles/tokens.css`
- App routes under `src/app`
- Components under `src/components`
- Public assets under `public/`

Stripe env vars are **not required** for local build. `/api/checkout` will 400 without keys, which is fine for UI work.
