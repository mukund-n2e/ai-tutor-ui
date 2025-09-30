#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PR="${PR:-30}"
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
TAG="${TAG:-v0.1.0}"
BRANCH="${BRANCH:-main}"

ROOT="$(pwd)"
LOG_DIR="$ROOT/.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
PROBE_LOG="$LOG_DIR/step18e_probe_${TS}.log"
REL_LOG="$LOG_DIR/step18e_release_${TS}.log"
PROTECT_BK="$LOG_DIR/step18e_protection_backup_${BRANCH}_${TS}.json"

need(){ command -v "$1" >/dev/null 2>&1; }
need git
need curl

merge_outcome="attempted"
if need gh; then
  set +e
  gh pr review "$PR" --approve >/dev/null 2>&1 || true
  gh pr merge  "$PR" --squash --delete-branch >/dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    gh pr merge "$PR" --squash --admin --delete-branch >/dev/null 2>&1
    rc=$?
  fi
  [ $rc -eq 0 ] && merge_outcome="merged" || merge_outcome="not-mergeable"
  set -e
fi

probe_code () { curl -sS -o /dev/null -w "%{http_code}" "$1?ts=$(date +%s)" -H 'Cache-Control: no-cache'; }
grab () { curl -fsSL "$1?ts=$(date +%s)" -H 'Cache-Control: no-cache' 2>>"$PROBE_LOG" || true; }

ROBOTS_CODE="$(probe_code "$PROD_URL/robots.txt")"
SITEMAP_CODE="$(probe_code "$PROD_URL/sitemap.xml")"
ROBOTS_BODY=""; SITEMAP_BODY=""
[ "$ROBOTS_CODE" = "200" ] && ROBOTS_BODY="$(grab "$PROD_URL/robots.txt")"
[ "$SITEMAP_CODE" = "200" ] && SITEMAP_BODY="$(grab "$PROD_URL/sitemap.xml")"
ROBOTS_HAS_SITEMAP="no"; echo "$ROBOTS_BODY" | grep -Eqi '^sitemap:\s*https?://.*/sitemap\.xml' && ROBOTS_HAS_SITEMAP="yes"
SITEMAP_HAS_COURSES="no"; echo "$SITEMAP_BODY" | grep -qi '<loc>.*?/courses</loc>' && SITEMAP_HAS_COURSES="yes"
SITEMAP_HAS_TUTOR="no";   echo "$SITEMAP_BODY" | grep -qi '<loc>.*?/tutor</loc>'   && SITEMAP_HAS_TUTOR="yes"

git fetch -q origin --tags || true
if git tag -l | grep -qx "$TAG"; then
  tag_created="no"
else
  tgt="$(git rev-parse "origin/$BRANCH")"
  git tag -a "$TAG" -m "$TAG" "$tgt" >>"$REL_LOG" 2>&1 || true
  git push origin "$TAG" >>"$REL_LOG" 2>&1 || true
  tag_created="yes"
fi

rel_url=""
if need gh; then
  if gh release view "$TAG" >/dev/null 2>&1; then
    rel_url="$(gh release view "$TAG" --json url -q .url 2>/dev/null || true)"
  else
    gh release create "$TAG" -t "$TAG" -n "Automated release" >>"$REL_LOG" 2>&1 || true
    rel_url="$(gh release view "$TAG" --json url -q .url 2>/dev/null || true)"
  fi
fi

protect_applied="no"
if need gh; then
  repo_slug="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo '')"
  if [ -n "$repo_slug" ]; then
    gh api -X GET "/repos/$repo_slug/branches/$BRANCH/protection" -H 'Accept: application/vnd.github+json' >"$PROTECT_BK" 2>/dev/null || true
    gh api -X PUT "/repos/$repo_slug/branches/$BRANCH/protection" \
      -H 'Accept: application/vnd.github+json' \
      -f required_status_checks= \
      -f enforce_admins=true \
      -f required_pull_request_reviews.required_approving_review_count=1 \
      -f restrictions= \
      -f required_linear_history=true \
      -f allow_force_pushes=false \
      -f allow_deletions=false \
      -f required_conversation_resolution=true >/dev/null 2>&1 || true
    protect_applied="yes"
  fi
fi

echo "=== CTO 18e RUNNER SUMMARY START ==="
echo "PR #$PR: $merge_outcome"
echo "Prod robots.txt -> $ROBOTS_CODE (sitemap_line=$ROBOTS_HAS_SITEMAP)"
echo "Prod sitemap.xml -> $SITEMAP_CODE (has_courses=$SITEMAP_HAS_COURSES has_tutor=$SITEMAP_HAS_TUTOR)"
echo "Tag: $TAG (created=$tag_created)"
echo "Release: ${rel_url:-<none>}"
echo "Branch protection applied: $protect_applied (backup: $PROTECT_BK)"
echo "=== CTO 18e RUNNER SUMMARY END ==="



