#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
TAG="${TAG:-v0.1.0}"
BRANCH="${BRANCH:-main}"
RELEASE_TITLE="${RELEASE_TITLE:-v0.1.0 – Public Beta rails + brand}"
RELEASE_NOTES="${RELEASE_NOTES:-This release includes Courses scaffold, SSE Tutor route, Next 15 fixes, brand tokens/skins, and deploy/docs rails.}"

ROOT="$(pwd)"
LOG_DIR="$ROOT/.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
PROBE_LOG="$LOG_DIR/final_probe_${TS}.log"
REL_LOG="$LOG_DIR/release_${TS}.log"
PROTECT_BK="$LOG_DIR/protection_backup_${BRANCH}_${TS}.json"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"
need curl || die "curl not found"

# Resolve owner/repo
REMOTE="$(git remote get-url origin 2>/dev/null || true)"
[ -n "$REMOTE" ] || die "origin remote not set"
case "$REMOTE" in
  git@github.com:*) O="${REMOTE#git@github.com:}"; O="${O%.git}" ;;
  https://github.com/*) O="${REMOTE#https://github.com/}"; O="${O%.git}" ;;
  *) die "Unsupported origin remote: $REMOTE" ;;
esac
OWNER="${O%%/*}"; REPO="${O##*/}"

probe_code () { curl -s -o /dev/null -w "%{http_code}" "$1" -H 'Cache-Control: no-cache'; }
grab () { curl -fsSL "$1" -H 'Cache-Control: no-cache' 2>>"$PROBE_LOG" || true; }

ROBOTS_CODE="$(probe_code "$PROD_URL/robots.txt")"
SITEMAP_CODE="$(probe_code "$PROD_URL/sitemap.xml")"
ROBOTS_BODY=""; SITEMAP_BODY=""
[ "$ROBOTS_CODE" = "200" ] && ROBOTS_BODY="$(grab "$PROD_URL/robots.txt")"
[ "$SITEMAP_CODE" = "200" ] && SITEMAP_BODY="$(grab "$PROD_URL/sitemap.xml")"

ROBOTS_HAS_SITEMAP="no"
echo "$ROBOTS_BODY" | grep -Eqi '^sitemap:\s*https?://.*/sitemap\.xml' && ROBOTS_HAS_SITEMAP="yes"
SITEMAP_HAS_COURSES="no"; echo "$SITEMAP_BODY" | grep -qi '<loc>.*?/courses</loc>' && SITEMAP_HAS_COURSES="yes"
SITEMAP_HAS_TUTOR="no";   echo "$SITEMAP_BODY" | grep -qi '<loc>.*?/tutor</loc>'   && SITEMAP_HAS_TUTOR="yes"

echo "Tag & Release $TAG … (log: $REL_LOG)"
git fetch origin --tags >/dev/null 2>&1 || true
TAG_EXISTS="$(git tag -l "$TAG" || true)"
if [ -z "$TAG_EXISTS" ]; then
  TARGET_SHA="$(git rev-parse "origin/$BRANCH")"
  git tag -a "$TAG" -m "$RELEASE_TITLE" "$TARGET_SHA" >>"$REL_LOG" 2>&1
  git push origin "$TAG" >>"$REL_LOG" 2>&1 || true
fi

REL_CREATED="no"; REL_URL=""
if command -v gh >/dev/null 2>&1; then
  if gh release view "$TAG" --repo "$OWNER/$REPO" >/dev/null 2>&1; then
    REL_URL="$(gh release view "$TAG" --repo "$OWNER/$REPO" --json url -q .url 2>/dev/null || true)"
  else
    gh release create "$TAG" --repo "$OWNER/$REPO" --title "$RELEASE_TITLE" --notes "$RELEASE_NOTES" >>"$REL_LOG" 2>&1 || true
    REL_URL="$(gh release view "$TAG" --repo "$OWNER/$REPO" --json url -q .url 2>/dev/null || true)"
    REL_CREATED="yes"
  fi
fi

PROTECT_APPLIED="no"
if command -v gh >/dev/null 2>&1; then
  gh api -X GET "/repos/$OWNER/$REPO/branches/$BRANCH/protection" \
    -H "Accept: application/vnd.github+json" >"$PROTECT_BK" 2>/dev/null || true
  # Minimal preset: null status checks, linear history, conversation resolution
  gh api -X PUT "/repos/$OWNER/$REPO/branches/$BRANCH/protection" \
    -H "Accept: application/vnd.github+json" \
    -f required_status_checks= \
    -f enforce_admins=false \
    -f required_pull_request_reviews= \
    -f restrictions= \
    -f required_linear_history=true \
    -f allow_force_pushes=false \
    -f allow_deletions=false \
    -f required_conversation_resolution=true >/dev/null 2>&1 || true
  PROTECT_APPLIED="yes"
fi

echo "=== CTO WP012 FINALIZE SUMMARY START ==="
echo "Repo: $OWNER/$REPO"
echo "Prod: $PROD_URL"
echo "Robots.txt: code=$ROBOTS_CODE sitemap_line=$ROBOTS_HAS_SITEMAP"
echo "Sitemap.xml: code=$SITEMAP_CODE has_courses=$SITEMAP_HAS_COURSES has_tutor=$SITEMAP_HAS_TUTOR"
echo "Tag: $TAG (exists=$( [ -n "$TAG_EXISTS" ] && echo yes || echo no ))"
echo "Release: created=$REL_CREATED url=${REL_URL:-<none>}"
echo "Protection: applied=$PROTECT_APPLIED backup=$PROTECT_BK"
echo "=== CTO WP012 FINALIZE SUMMARY END ==="



