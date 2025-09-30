# Program Manager Handover — AI Tutor

You own **planning, auditing, and gating**. Do **not** write code. Drive the build through agents using the JSON microsteps and runbooks in this pack.

## North Star
Ship the **web app** (desktop + mobile web) for AU + IN markets, with USD fallback for rest-of-world. Keep the design system frozen; ship fully tokenized UI, no inline styles, and pass the verifiers.

## What to do first (single-threaded)
1. **Create the clean UI repo on GitHub** and push the current working copy (or confirm it’s already there). Enable Actions.
2. **Add GitHub secrets** for Stripe when available (non‑blocking for build). Run the UI verifiers + build.
3. **Run the `Agent-Orchestrator.json`** in your agent runner. It executes the whole sequence step‑by‑step with verification gates.
4. **Work the microsteps** from `SprintPlan.json` in order. Only move when each step is green.
5. **Log everything** in the PR description + checklists. No “celebration” messages without proof: verifiers, build, tests, and routes.

## Guardrails (operational)
- **One branch per microstep**, named `feat/<module>-<step-id>`.
- **Pre-commit guard must pass**; verifiers run in CI.
- **No design drift**: only `tokens.css`, no hex/rgba in modules; no inline styles in core components.
- **Sign-off requires**: verifier green, build green, routes reachable, acceptance checks ticked, and updated docs.
- **Rollback policy**: if verifier fails on main, revert the PR within 30 minutes.

## Communication
- Standard message format from agents: *What changed → How verified → Where to find artifacts → Any risk/next step*.
- You maintain the single source of truth: this pack + repo docs.
