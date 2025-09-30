#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

note(){ printf "%s\n" "$*" ; }
need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"

# 0) Check vercel binary in THIS shell
if ! need vercel; then
  die "Vercel CLI not found in PATH for this shell. Install: npm i -g vercel  (then re-run)"
fi
note "vercel binary: $(command -v vercel)"
vercel --version || true

# 1) Confirm login in THIS shell
if ! vercel whoami >/dev/null 2>&1; then
  note "You’re not logged in in this shell. Running: vercel login"
  vercel login || die "Login failed. Complete login then re-run this script."
fi
note "Logged in as: $(vercel whoami 2>/dev/null)"

# 2) Ensure engines.node in web/package.json (Vercel Node 20 OK)
PKG="$APP_DIR/package.json"
if [ -f "$PKG" ]; then
  node -e "const fs=require('fs');const p='$PKG';const j=JSON.parse(fs.readFileSync(p,'utf8'));j.engines=j.engines||{};j.engines.node='^18.17 || >=20';fs.writeFileSync(p,JSON.stringify(j,null,2)+'\n')" || true
  git add "$PKG" 2>/dev/null || true
  git commit -m "chore(vercel): ensure engines.node (^18.17 || >=20)" >/dev/null 2>&1 || true
  note "Ensured engines.node in $PKG"
fi

# 3) Link the Vercel project inside web/
cd "$APP_DIR"

# If you know the exact team/project, set env before running:
#   TEAM='ai_tutor' PROJECT='tutorweb-cyan' bash cto_step_17n_vercel_link_and_engines.sh
TEAM="${TEAM:-}"
PROJECT="${PROJECT:-}"

if [ -n "$TEAM" ] && [ -n "$PROJECT" ]; then
  note "Linking with --scope $TEAM --project $PROJECT ..."
  vercel link --yes --scope "$TEAM" --project "$PROJECT" || die "vercel link failed with scope/project"
else
  note "Linking interactively (choose your team and the existing project for prod, likely 'tutorweb-cyan')..."
  vercel link || die "vercel link failed interactively"
fi

# 4) Show link status and pull prod env (best-effort)
if [ -f ".vercel/project.json" ]; then
  note ".vercel/project.json:"
  cat ".vercel/project.json"
else
  die "Link appears incomplete: .vercel/project.json not found"
fi

vercel pull --yes --environment=production >/dev/null 2>&1 || true
note "Pulled prod env (best-effort)."

# Summary
echo "=== CTO VERCEL LINK SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "vercel: $(command -v vercel)"
echo "whoami: $(vercel whoami 2>/dev/null)"
echo "project.json present: yes"
echo "Engines ensured in: $PKG"
echo "Tip: If the wrong team/project was linked, re-run with TEAM='your-team-slug' PROJECT='your-project-name'."
echo "=== CTO VERCEL LINK SUMMARY END ==="
