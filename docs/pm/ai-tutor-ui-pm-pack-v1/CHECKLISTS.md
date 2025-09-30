# Checklists

## Microstep sign-off
- [ ] Branch created (`feat/<module>-<step-id>`)
- [ ] Verifier passed (`npm run verify:ui`)
- [ ] Build passed (`npm run build`)
- [ ] Routes reachable (list)
- [ ] A11y basics (focus, labels) checked
- [ ] Docs updated (this pack + repo README/CHANGELOG)
- [ ] PR summary contains: Changes, Verify, Artifacts, Risk, Rollback

## Pre-release
- [ ] All acceptance criteria in PRD met
- [ ] Stripe env configured (if enabled)
- [ ] Error logging producing events
- [ ] Smoke E2E runs in CI
