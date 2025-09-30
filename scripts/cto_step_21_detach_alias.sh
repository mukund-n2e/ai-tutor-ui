#!/usr/bin/env bash
set -euo pipefail
DOMAIN="tutorweb-cyan.vercel.app"

have_domain () {
  vercel domains ls 2>/dev/null | grep -q "^${DOMAIN}\b" && return 0
  vercel alias ls 2>/dev/null   | grep -q "^${DOMAIN}\b" && return 0
  return 1
}

echo "Checking current team for ${DOMAIN}…"
if ! have_domain; then
  echo "Not in this team. Listing teams; select the one that has project 'tutor_web'."
  vercel teams ls || true
  vercel switch
fi

echo "Re-checking…"
if have_domain; then
  (vercel domains remove "${DOMAIN}" -y || vercel alias rm "${DOMAIN}" -y) \
    && echo "alias detached" && exit 0
fi

echo "Alias still not found in selected team. Remove via UI (tutor_web → Settings → Domains), then rerun." >&2
exit 1
