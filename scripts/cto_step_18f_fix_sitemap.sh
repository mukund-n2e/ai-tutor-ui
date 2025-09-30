#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
APP_APP_DIR="$APP_DIR/src/app"
SITEMAP="$APP_APP_DIR/sitemap.ts"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/sitemap_build_${TS}.log"
BR="wp012-sitemap-widen-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"; need npm || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"

mkdir -p "$APP_APP_DIR"

# Write robust sitemap (canonical base + explicit routes + course slugs)
cat > "$SITEMAP" <<'TS'
import type { MetadataRoute } from 'next';
import { listCourses } from '../courses/registry';

export const dynamic = 'force-static';

function canonBase() {
  // Prefer env if set; otherwise fall back to prod domain
  const base = process.env.NEXT_PUBLIC_BASE_URL || 'https://tutorweb-cyan.vercel.app';
  return base.replace(/\/+$/, ''); // no trailing slash
}
const u = (p: string) => `${canonBase()}${p}`;

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const items: MetadataRoute.Sitemap = [
    { url: u('/'), changeFrequency: 'weekly', priority: 0.7 },
    { url: u('/courses'), changeFrequency: 'weekly', priority: 0.7 },
    { url: u('/tutor'), changeFrequency: 'weekly', priority: 0.5 },
  ];

  try {
    const courses = listCourses();
    for (const c of courses) {
      items.push({ url: u(`/courses/${c.slug}`), changeFrequency: 'monthly', priority: 0.5 });
    }
  } catch {
    // If registry fails at build time, we still return the static entries above.
  }

  return items;
}
TS

# Build check
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 120 "$BUILD_LOG" || true; exit 2; }

# Commit + PR
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$SITEMAP"
git commit -m "seo(sitemap): normalize base + include /courses,/tutor and course slugs (force-static)" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac

PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr create --head "$BR" --title "seo(sitemap): normalize + widen entries" --body "Ensure sitemap contains canonical entries for /, /courses, /tutor, and all course slugs. Uses NEXT_PUBLIC_BASE_URL if set; force-static.")" || true
fi

echo "=== CTO 18f SITEMAP SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "File: $SITEMAP"
echo "Next: merge PR, then run the probe below to confirm."
echo "=== CTO 18f SITEMAP SUMMARY END ==="
