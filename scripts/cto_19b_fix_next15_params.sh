#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
SLUG_PAGE="$APP_DIR/src/app/screens/[slug]/page.tsx"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/step19b_next15_params_fix_${TS}.log"
BR="wp019b-next15-params-fix-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"; need npm || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"
[ -f "$SLUG_PAGE" ] || die "Slug page not found at $SLUG_PAGE"

# Overwrite slug page with Promise-based params version
cat > "$SLUG_PAGE" <<'TSX'
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { screens } from '../../../design/screens.manifest';

export async function generateStaticParams() {
  return screens.map(s => ({ slug: s.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const s = screens.find(x => x.slug === slug);
  return { title: s ? `Screen • ${s.title}` : 'Screen' };
}

export default async function ScreenPage({ params }: { params: Promise<{ slug: string }>}) {
  const { slug } = await params;
  const s = screens.find(x => x.slug === slug);
  if (!s) return notFound();
  return (
    <main style={{maxWidth: 1100, margin: '40px auto', padding: '0 16px'}}>
      <p style={{marginBottom: 10}}><Link href="/screens">← All screens</Link></p>
      <h1 style={{margin: '0 0 12px'}}>{s.title}</h1>
      <div style={{fontSize: 14, opacity: 0.8, marginBottom: 12}}>
        slug: <code>{s.slug}</code> • {s.exists ? 'Implemented route' : 'Suggested'}: <Link href={s.route}>{s.route}</Link>
      </div>
      <div style={{border:'1px solid #e5e7eb', borderRadius: 8, overflow:'hidden', background:'#fafafa'}}>
        <img src={`/design/screens/${s.file}`} alt={s.title} style={{display:'block', width:'100%', height:'auto'}} />
      </div>
    </main>
  );
}
TSX

# Build check
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 160 "$BUILD_LOG" || true; exit 2; }

# Commit + PR
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$SLUG_PAGE"
git commit -m "fix(screens): Next15 PageProps params as Promise on slug page (await params)" >/dev/null 2>&1 || true
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
  [ -z "$PR_URL" ] && PR_URL="$(gh pr create --head "$BR" --title "fix(screens): await params (Next15)" --body "Align slug page with Next 15's PageProps typing by treating \`params\` as a Promise and awaiting it. No behavior change.")"
fi

echo "=== CTO 19b NEXT15 PARAMS FIX SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "File: $SLUG_PAGE"
echo "=== CTO 19b NEXT15 PARAMS FIX SUMMARY END ==="
