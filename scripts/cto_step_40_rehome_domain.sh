#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
DOMAIN="tutorweb-cyan.vercel.app"

# Ensure we're operating on the right project + team
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null

# Detach the domain/alias wherever it currently lives in this team (ignore if not present)
(vercel alias rm    "$DOMAIN" -y --scope "$TEAM" >/dev/null 2>&1 || true)
(vercel domains remove "$DOMAIN" -y --scope "$TEAM" >/dev/null 2>&1 || true)

# Attach domain to the current project
vercel domains add "$DOMAIN" --scope "$TEAM"

echo "domain-attached"
