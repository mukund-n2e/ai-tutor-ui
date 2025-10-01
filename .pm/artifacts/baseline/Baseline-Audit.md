# Baseline Audit — AI Tutor UI

- src/app: present
- src/styles: present
- design/frames: present
- design/specs|spec: present

Breakpoints required: 360, 768, 1200

## Coverage Table (key → route → css → spec → goldens → breakpoints)

| key | routes | css | spec | goldens | breakpoints |
|---|---|---|:---:|:---:|---|
| account | /account | system.module.css | NO | NO | - |
| account_link_sent | - | system.module.css | yes | NO | - |
| account_signin | - | system.module.css | yes | NO | - |
| account_verify | - | system.module.css | yes | NO | - |
| checkout | - | - | yes | NO | - |
| checkout-error | /checkout/error | system.module.css | yes | NO | - |
| checkout-success | /checkout/success | system.module.css | yes | NO | - |
| error-500 | /error | system.module.css | NO | NO | - |
| landing | /landing | landing.module.css | yes | NO | - |
| legal-privacy | /legal/privacy | system.module.css | NO | NO | - |
| legal-terms | /legal/terms | system.module.css | yes | NO | - |
| lesson | /lesson/L1-05 | lesson.module.css | yes | NO | - |
| lesson-outline-L1-05 | - | - | yes | NO | - |
| lesson-runner-L1-05 | - | - | yes | NO | - |
| not-found-404 | /not-found | system.module.css | NO | NO | - |
| onboarding | /onboarding | - | yes | NO | - |
| outline | /lesson/L1-05/outline | outline.module.css | yes | NO | - |
| pricing | /pricing | pricing.module.css | yes | NO | - |
| pricing-checkout | - | - | yes | NO | - |
| system | - | system.module.css | NO | NO | - |
| tokens | - | tokens.module.css | NO | NO | - |
| wall | /wall | wall.module.css | yes | NO | - |

## Gaps (22)
- **wall** → route: /wall, css: wall.module.css, spec: yes, goldens: NO, breakpoints: -
- **pricing** → route: /pricing, css: pricing.module.css, spec: yes, goldens: NO, breakpoints: -
- **onboarding** → route: /onboarding, css: -, spec: yes, goldens: NO, breakpoints: -
- **lesson** → route: /lesson/L1-05, css: lesson.module.css, spec: yes, goldens: NO, breakpoints: -
- **outline** → route: /lesson/L1-05/outline, css: outline.module.css, spec: yes, goldens: NO, breakpoints: -
- **legal-terms** → route: /legal/terms, css: system.module.css, spec: yes, goldens: NO, breakpoints: -
- **legal-privacy** → route: /legal/privacy, css: system.module.css, spec: NO, goldens: NO, breakpoints: -
- **landing** → route: /landing, css: landing.module.css, spec: yes, goldens: NO, breakpoints: -
- **checkout-success** → route: /checkout/success, css: system.module.css, spec: yes, goldens: NO, breakpoints: -
- **checkout-error** → route: /checkout/error, css: system.module.css, spec: yes, goldens: NO, breakpoints: -
- **account** → route: /account, css: system.module.css, spec: NO, goldens: NO, breakpoints: -
- **not-found-404** → route: /not-found, css: system.module.css, spec: NO, goldens: NO, breakpoints: -
- **error-500** → route: /error, css: system.module.css, spec: NO, goldens: NO, breakpoints: -
- **system** → route: -, css: system.module.css, spec: NO, goldens: NO, breakpoints: -
- **tokens** → route: -, css: tokens.module.css, spec: NO, goldens: NO, breakpoints: -
- **account_link_sent** → route: -, css: system.module.css, spec: yes, goldens: NO, breakpoints: -
- **account_signin** → route: -, css: system.module.css, spec: yes, goldens: NO, breakpoints: -
- **account_verify** → route: -, css: system.module.css, spec: yes, goldens: NO, breakpoints: -
- **checkout** → route: -, css: -, spec: yes, goldens: NO, breakpoints: -
- **lesson-outline-L1-05** → route: -, css: -, spec: yes, goldens: NO, breakpoints: -
- **lesson-runner-L1-05** → route: -, css: -, spec: yes, goldens: NO, breakpoints: -
- **pricing-checkout** → route: -, css: -, spec: yes, goldens: NO, breakpoints: -

## Hygiene checks
- Inline styles in app/components: FOUND (see list below)
- Raw hex colors outside tokens.css: FOUND
- rgb/rgba outside tokens.css: FOUND

### Inline style hits
- src/app/onboarding/page.tsx
- src/components/BetaBadge.tsx
- src/components/ChatSSE.tsx
- src/components/SaveSessionButton.tsx
- src/components/TopNav.tsx.bak.20250917_052403
- src/components/TutorShell.tsx

### Raw hex color hits
- src/styles/system.module.css
- src/components/BetaBadge.tsx
- src/components/ChatSSE.tsx
- src/components/SaveSessionButton.tsx
- src/components/TopNav.tsx.bak.20250917_052403
- src/components/TutorShell.tsx
- src/app/onboarding/page.tsx

### rgb/rgba hits
- src/styles/lesson.module.css
- src/components/BetaBadge.tsx
