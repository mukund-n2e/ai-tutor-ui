# CI/CD

## GitHub Actions
- Workflow runs on push and PR
- Steps: install deps → verify_ui → build → (optional) e2e smoke

## Required secrets (later)
- STRIPE_SECRET_KEY
- STRIPE_PRICE_L2_AUD / STRIPE_PRICE_L2_INR / STRIPE_PRICE_L2_USD
- STRIPE_PRICE_L3_AUD / STRIPE_PRICE_L3_INR / STRIPE_PRICE_L3_USD
- STRIPE_ENABLE_INR=true|false

## Branching
- `main`: protected; squash merges only
- feature branches: `feat/<module>-<microstep>`
