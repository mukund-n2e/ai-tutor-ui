#!/usr/bin/env bash
set -euo pipefail
APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"

WHOAMI="$(vercel whoami 2>/dev/null || echo '<not logged in>')"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat <<'TXT'
================= OWNER ACTION REQUEST — Vercel =================
Context:
- We need to deploy from CLI to the Vercel project that serves production:
  - Team: ai_tutor
  - Project: tutor_web
  - Prod URL: https://tutorweb-cyan.vercel.app

Invite request:
- Please invite the following Vercel user to the **ai_tutor** team with **Developer** (or higher) role:
    Handle: __HANDLE__
    Email:  <the email I use to log in to Vercel>

Project settings (please confirm):
1) Project → Settings → General
   - Root Directory: `web`
   - Framework Preset: Next.js
   - Production Branch: `main`
   - Build Command: `npm run build`
   - Output Directory: `.next`
   - Node.js: 20.x (or “Latest 20”)

2) Project → Settings → Environment Variables (Production)
   - OPENAI_API_KEY               (set)
   - NEXT_PUBLIC_TUTOR_TRANSPORT  = sse
   - (optional) NEXT_PUBLIC_WS_URL (leave empty for same-origin)
   - (optional) SESSION_TOKEN_CAP  (e.g., 120000)

3) Domains
   - Ensure `tutorweb-cyan.vercel.app` is attached to this **tutor_web** project.

Once done:
- Reply “added + settings confirmed”.
- We’ll run the deploy and verify `/courses` + `/courses/getting-started` are live.

Thanks!
===============================================================
TXT

echo
echo "Filled details:"
echo "  Generated at: ${NOW}"
echo "  Vercel whoami: ${WHOAMI}"
echo "  Team: ai_tutor"
echo "  Project: tutor_web"
echo "  Repo app dir: ${APP_DIR}"
echo
echo "Copy the block above, replace __HANDLE__ with your Vercel handle and your email, and send to the team owner."
