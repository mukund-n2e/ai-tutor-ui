#!/usr/bin/env bash
set -Eeuo pipefail
APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"

# Find the newest vercel build log
LOG="$(ls -t ./.cto_logs/vercel_build_*.log 2>/dev/null | head -n1 || true)"
[ -z "$LOG" ] && { echo "No vercel_build_*.log found in ./.cto_logs"; exit 2; }

echo "=== DIAG — Vercel Build Log Tail ($LOG) ==="
echo "---- first 40 lines ----"; head -n 40 "$LOG" || true
echo "---- last 200 lines ----"; tail -n 200 "$LOG" || true
echo

# Quick environment checks
echo "=== DIAG — Local environment ==="
( cd "$APP_DIR" && node -v && npm -v && npx --yes next --version ) 2>/dev/null || true
echo

# Vercel link/auth status
echo "=== DIAG — Vercel CLI status ==="
if command -v vercel >/dev/null 2>&1; then
  vercel --version || true
  if vercel whoami >/dev/null 2>&1; then
    echo "whoami: OK ($(vercel whoami 2>/dev/null))"
  else
    echo "whoami: NOT LOGGED IN"
  fi
  if [ -f "$APP_DIR/.vercel/project.json" ]; then
    echo ".vercel/project.json:"
    cat "$APP_DIR/.vercel/project.json"
  else
    echo "No .vercel/project.json (not linked in $APP_DIR)"
  fi
else
  echo "vercel CLI not installed"
fi
echo

# Heuristic diagnosis
echo "=== DIAG — Heuristics ==="
tail -n 200 "$LOG" | awk '
  BEGIN{node=0; nextjs=0; link=0; auth=0; cmd=0}
  /Error:.*node|Node\.js|engines/ {node=1}
  /Next\.js|next build/ {nextjs=1}
  /link this directory|vercel link/i {link=1}
  /not authenticated|login/i {auth=1}
  /Command.*exited with|Build failed|Failed to compile/ {cmd=1}
  END{
    if (auth) print "- Looks like Vercel CLI is not logged in.";
    if (link) print "- Looks like this directory is not linked to a Vercel project.";
    if (node) print "- Node/engines mismatch may be involved.";
    if (cmd && !auth && !link) print "- Build command failed; check the error lines above.";
    if (!auth && !link && !node && !cmd) print "- No obvious pattern detected; will need the exact error text above.";
  }'
echo
echo "=== DIAG — Next steps hint ==="
echo "If auth/link issues: run 'vercel login' then 'cd web && vercel link'."
echo "If Node/engines: set \"engines\": { \"node\": \"^18.17 || >=20\" } in web/package.json."
echo "If build-only error: we will patch the specific file per the error above."
echo "=== END DIAG ==="
