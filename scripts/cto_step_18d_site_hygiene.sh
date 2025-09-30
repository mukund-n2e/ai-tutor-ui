#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
APP_APP_DIR="$APP_DIR/src/app"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/site_hygiene_build_${TS}.log"
BR="wp012-site-hygiene-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"
need npm || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"

mkdir -p "$APP_APP_DIR"

# 1) robots.ts (only if missing)
if [ ! -f "$APP_APP_DIR/robots.ts" ]; then
  cat > "$APP_APP_DIR/robots.ts" <<'TS'
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  const base = process.env.NEXT_PUBLIC_BASE_URL || 'https://tutorweb-cyan.vercel.app';
  return {
    rules: [{ userAgent: '*', allow: '/' }],
    sitemap: `${base}/sitemap.xml`,
  };
}
TS
fi

# 2) sitemap.ts (only if missing)
if [ ! -f "$APP_APP_DIR/sitemap.ts" ]; then
  cat > "$APP_APP_DIR/sitemap.ts" <<'TS'
import type { MetadataRoute } from 'next';
import { listCourses } from '../courses/registry';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = process.env.NEXT_PUBLIC_BASE_URL || 'https://tutorweb-cyan.vercel.app';
  const items: MetadataRoute.Sitemap = [
    { url: `${base}/`, changeFrequency: 'weekly', priority: 0.7 },
    { url: `${base}/courses`, changeFrequency: 'weekly', priority: 0.7 },
    { url: `${base}/tutor`, changeFrequency: 'weekly', priority: 0.5 },
  ];
  try {
    const courses = listCourses();
    for (const c of courses) {
      items.push({ url: `${base}/courses/${c.slug}`, changeFrequency: 'monthly', priority: 0.5 });
    }
  } catch {}
  return items;
}
TS
fi

# 3) not-found.tsx (only if missing)
if [ ! -f "$APP_APP_DIR/not-found.tsx" ]; then
  cat > "$APP_APP_DIR/not-found.tsx" <<'TSX'
export const dynamic = 'force-static';

export default function NotFound() {
  return (
    <main className="page">
      <h1>Not found</h1>
      <p className="lead">That page may have moved or never existed.</p>
    </main>
  );
}
TSX
fi

# 4) error.tsx (only if missing)
if [ ! -f "$APP_APP_DIR/error.tsx" ]; then
  cat > "$APP_APP_DIR/error.tsx" <<'TSX'
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  console.error(error);
  return (
    <main className="page">
      <h1>Something went wrong</h1>
      <p className="lead">Try again, or head back home.</p>
      <button onClick={() => reset()}>Try again</button>
    </main>
  );
}
TSX
fi

# 5) Build, commit, push PR
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 120 "$BUILD_LOG" || true; exit 2; }

git config user.name "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$APP_APP_DIR/robots.ts" "$APP_APP_DIR/sitemap.ts" "$APP_APP_DIR/not-found.tsx" "$APP_APP_DIR/error.tsx" 2>/dev/null || true
git commit -m "chore(site): robots + sitemap + 404 + error (Step 18d)" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac
PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr list --head "$BR" --json url -q .[0].url 2>/dev/null || true)"
  [ -z "$PR_URL" ] && PR_URL="$(gh pr create --head "$BR" --title "chore(site): robots + sitemap + 404 + error" --body "Adds basic SEO files and brand-aware 404/error pages. Idempotent; safe.")"
fi

echo "=== CTO 18d SITE HYGIENE SUMMARY START ==="
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "Files: $APP_APP_DIR/robots.ts , $APP_APP_DIR/sitemap.ts , $APP_APP_DIR/not-found.tsx , $APP_APP_DIR/error.tsx"
echo "=== CTO 18d SITE HYGIENE SUMMARY END ==="
