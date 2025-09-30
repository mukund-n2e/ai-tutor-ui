# AI Tutor — Program Manager Pack (v1)

**Date:** 2025-09-30

This pack is your single source of truth for running the program to **Go Live**. It includes:
- PM handover message
- PRD exec summary + acceptance criteria
- Guardrails (coding, process, repo hygiene)
- Runbooks (one‑shot + per‑module)
- Agent orchestration JSON (single prompt)
- Sprint plan + microstep backlog
- CI/CD + Env setup notes
- Checklists for verification and sign‑off

**Principle:** one outcome at a time, no spinning, merge only when verifiers pass, ship quality.

---

## Folder map
- `PM-Handover.md` — what to do first, how to run the show
- `PRD-Exec-Summary.md` — scope, decisions, constraints, acceptance criteria
- `SprintPlan.json` — module-by-module microsteps (deliverable-first)
- `Agent-Orchestrator.json` — single prompt the PM can hand to the agent
- `Guardrails/` — coding + process guardrails (pre-commit, PR rules, tokenization rules)
- `Runbooks/` — one-shot and per-module runbooks (copy/paste safe)
- `CI-CD.md` — GitHub Actions, required secrets, branch strategy
- `ENV-SETUP.md` — environment vars (.env.example), Stripe, market flags
- `CHECKLISTS.md` — verification and sign-off checklists
- `Backlog.md` — all parked items captured, linked to modules

---

## Known good UI baselines referenced in this plan
- Landing uses tokenized styles and shared components
- Onboarding implements chip groups, consent, and routing to L1-05
- Lesson Runner implements 0‑Form: **Learn → Apply → Check‑it → Ship**
- Course Wall frames/spec mirror the filtering and recommended section
- Shared design tokens (`tokens.css`) provide a single source of truth

These are cited in the handover for traceability.
