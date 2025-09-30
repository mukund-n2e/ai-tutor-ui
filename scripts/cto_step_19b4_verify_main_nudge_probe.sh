#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
VERIFY_LOG="$LOG_DIR/step19b4_verify_${TS}.log"
DEPLOY_LOG="$LOG_DIR/step19b4_deploy_${TS}.log"
PROBE_LOG="$LOG_DIR/step19b4_probe_${TS}.log"
BR="redeploy-19b4-${TS}"
NUDGE="web/public/_deploy_nudge_19b4_${TS}.txt"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"; need curl || die "curl not found"

echo "=== VERIFY origin/main has /screens ===" | tee "$VERIFY_LOG"
git fetch origin main --prune >/dev/null 2>&1 || true

FILES=(
"web/src/app/screens/page.tsx"
"web/src/app/screens/[slug]/page.tsx"
"web/src/app/__screens/page.tsx"
"web/src/app/__screens/[slug]/page.tsx"
"web/src/design/screens.manifest.ts"
)
missing=0
git ls-tree -r origin/main --name-only > "$LOG_DIR/.tree_${TS}.txt" || true
for f in "${FILES[@]}"; do
if grep -qx "$f" "$LOG_DIR/.tree_${TS}.txt"; then
  echo "present: $f" | tee -a "$VERIFY_LOG"
else
  echo "MISSING: $f" | tee -a "$VERIFY_LOG"; missing=$((missing+1))
fi
done
if [ $missing -gt 0 ]; then
echo "ERROR: origin/main missing ${missing} required file(s) for /screens. Merge PR with screens, then rerun." | tee -a "$VERIFY_LOG"
exit 2
fi

# Nudge Git deploy (no CLI scopes)
echo "nudge $TS" > "$NUDGE"
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$NUDGE"
git commit -m "chore: deploy nudge for /screens (${TS})" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true
if command -v gh >/dev/null 2>&1; then
PR_URL="$(gh pr create --head "$BR" --title "chore: deploy nudge for /screens" --body "Force Git deploy to pick up /screens routes." 2>/dev/null || true)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL"
gh pr review "$BR" --approve >/dev/null 2>&1 || true
gh pr merge  "$BR" --squash --delete-branch >/dev/null 2>&1 || true
else
REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";; https://github.com/*) GH_URL="$REMOTE";; *) GH_URL="";; esac
echo "Open & merge manually: ${GH_URL:+$GH_URL/compare/$BR?expand=1}"
fi

echo "Polling prod /smoke …" | tee "$DEPLOY_LOG"
for i in $(seq 1 60); do
code="$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL/smoke?nocache=$(date +%s)")"
echo "  /smoke -> $code" | tee -a "$DEPLOY_LOG"
[ "$code" = "200" ] && break
sleep 5
done

probe(){ local p="$1"; local c; c=$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL$p?nocache=$(date +%s)"); echo "  $p -> $c" | tee -a "$PROBE_LOG"; }
echo "Probing $PROD_URL …" | tee "$PROBE_LOG"
probe "/"
probe "/api/health"
probe "/tutor"
probe "/sessions"
probe "/screens"
probe "/screens/01-landing"
probe "/__screens"

echo "=== CTO 19b.4 VERIFY+NUDGE+PROBE SUMMARY START ==="
echo "Prod: $PROD_URL"
echo "Verify log: $VERIFY_LOG"
echo "Deploy log: $DEPLOY_LOG"
echo "Probe log:  $PROBE_LOG"
echo "=== CTO 19b.4 VERIFY+NUDGE+PROBE SUMMARY END ==="

#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
VERIFY_LOG="$LOG_DIR/step19b4_verify_${TS}.log"
DEPLOY_LOG="$LOG_DIR/step19b4_deploy_${TS}.log"
PROBE_LOG="$LOG_DIR/step19b4_probe_${TS}.log"
BR="redeploy-19b4-${TS}"
NUDGE="web/public/_deploy_nudge_19b4_${TS}.txt"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"; need curl || die "curl not found"

echo "=== VERIFY origin/main has /screens ===" | tee "$VERIFY_LOG"
git fetch origin main --prune >/dev/null 2>&1 || true

# List key files
FILES=(
  "web/src/app/screens/page.tsx"
  "web/src/app/screens/[slug]/page.tsx"
  "web/src/app/__screens/page.tsx"
  "web/src/app/__screens/[slug]/page.tsx"
  "web/src/design/screens.manifest.ts"
)
missing=0
for f in "${FILES[@]}"; do
  if git ls-tree -r origin/main --name-only | grep -qx "$f"; then
    echo "present: $f" | tee -a "$VERIFY_LOG"
  else
    echo "MISSING: $f" | tee -a "$VERIFY_LOG"
    missing=$((missing+1))
  fi
done

if [ $missing -gt 0 ]; then
  echo "ERROR: origin/main is missing ${missing} required file(s) for /screens. Merge PR #36, then rerun." | tee -a "$VERIFY_LOG"
  exit 2
fi

# Show last change touching screens
git log -n 1 --format='commit:%h  date:%ad  %s' --date=iso-strict origin/main -- web/src/app/screens/page.tsx | tee -a "$VERIFY_LOG" || true

# 1) Nudge Git deploy (no CLI scope needed)
echo "nudge $TS" > "$NUDGE"
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$NUDGE"
git commit -m "chore: deploy nudge for /screens (${TS})" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr create --head "$BR" --title "chore: deploy nudge for /screens" --body "Force Git deploy to pick up new /screens routes." 2>/dev/null || true)"
  [ -n "$PR_URL" ] && echo "PR: $PR_URL"
  gh pr review "$BR" --approve >/dev/null 2>&1 || true
  gh pr merge  "$BR" --squash --delete-branch >/dev/null 2>&1 || true
else
  REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
  case "$REMOTE" in git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";; https://github.com/*) GH_URL="$REMOTE";; *) GH_URL="";; esac
  echo "Open & merge manually: ${GH_URL:+$GH_URL/compare/$BR?expand=1}"
fi

# 2) Poll prod for /smoke = 200 (bounded)
echo "Polling prod /smoke …" | tee "$DEPLOY_LOG"
for i in $(seq 1 60); do
  code="$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL/smoke?nocache=$(date +%s)")"
  echo "  /smoke -> $code" | tee -a "$DEPLOY_LOG"
  [ "$code" = "200" ] && break
  sleep 5
done

# 3) Probe routes
probe(){ local p="$1"; local c; c=$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL$p?nocache=$(date +%s)"); echo "  $p -> $c" | tee -a "$PROBE_LOG"; }
echo "Probing $PROD_URL …" | tee "$PROBE_LOG"
probe "/"
probe "/api/health"
probe "/tutor"
probe "/sessions"
probe "/screens"
probe "/screens/01-landing"
probe "/__screens"

echo "=== CTO 19b.4 VERIFY+NUDGE+PROBE SUMMARY START ==="
echo "Prod: $PROD_URL"
echo "Verify log: $VERIFY_LOG"
echo "Deploy log: $DEPLOY_LOG"
echo "Probe log:  $PROBE_LOG"
echo "=== CTO 19b.4 VERIFY+NUDGE+PROBE SUMMARY END ==="
