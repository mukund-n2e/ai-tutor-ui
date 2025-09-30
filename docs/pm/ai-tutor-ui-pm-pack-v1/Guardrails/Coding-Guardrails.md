# Coding Guardrails

- **Design tokens only** in core components. No hex colors, no `rgba()` in CSS modules; no `bg-white/gray-50/gray-100` utilities.
- **No inline styles** in core components (`Header`, `Button`, `Card`, `Chip`, feature pages).
- Shared helpers live in `tokens.css` (e.g., `.h-header`, `.min-touch`, `.p-card`).

## Pre-commit
- Block staging outside allowlist while a feature is in progress.
- Block diffs that introduce banned patterns.
- Refuse commit when verifier fails.

## PR rules
- One microstep per PR.
- Include: What changed → How verified → Screenshots/URLs → Risks/rollbacks.
- Do not merge on red CI.
