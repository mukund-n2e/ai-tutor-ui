# Process Guardrails

- One-branch-per-microstep, squash merge to `main`.
- CI must run `npm run verify:ui` and `npm run build` at minimum.
- Any agent success message must be verified by running scripts and posting artifacts.
- Keep repo tidy; archive or delete duplicates via PRs only.
