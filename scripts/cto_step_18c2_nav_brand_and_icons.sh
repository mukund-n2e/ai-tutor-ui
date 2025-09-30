#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
APP_APP_DIR="$APP_DIR/src/app"
COMP_DIR="$APP_DIR/src/components"
LAYOUT="$APP_APP_DIR/layout.tsx"
TN="$COMP_DIR/TopNav.tsx"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/nav_brand_build_${TS}.log"
BR="wp010b-nav-brand-icons-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"; need npm || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"

# 1) Ensure layout exports icons (non-destructive)
if [ -f "$LAYOUT" ]; then
  if ! grep -q "export const metadata" "$LAYOUT"; then
    # add minimal metadata with icons at top
    awk 'NR==1{print "import type { Metadata } from '\''next'\'';"; print "export const metadata: Metadata = { icons: { icon: '\''/brand/favicon.svg'\'', apple: '\''/brand/apple-touch-icon.png'\'' } };"; print; next}1' "$LAYOUT" > "$LAYOUT.tmp" && mv "$LAYOUT.tmp" "$LAYOUT"
  else
    # has metadata; add icons if missing
    if ! grep -q "icons:" "$LAYOUT"; then
      # append icons into metadata object (simple heuristic: after first '{' of metadata init)
      perl -0777 -pe 's/export const metadata\s*:\s*Metadata\s*=\s*\{([^}]*)\}/"export const metadata: Metadata = { icons: { icon: \x27\/brand\/favicon.svg\x27, apple: \x27\/brand\/apple-touch-icon.png\x27 }, $1}"/s' "$LAYOUT" > "$LAYOUT.tmp" 2>/dev/null || true
      [ -s "$LAYOUT.tmp" ] && mv "$LAYOUT.tmp" "$LAYOUT" || true
    fi
  fi
else
  # create minimal layout with imports (Step 18a should have done this already)
  mkdir -p "$APP_APP_DIR"
  cat > "$LAYOUT" <<'TSX'
import type { Metadata } from 'next';
import '../styles/tokens.css';
import '../styles/components.css';
export const metadata: Metadata = {
  title: 'Nudge2Edge • AI Tutor',
  icons: { icon: '/brand/favicon.svg', apple: '/brand/apple-touch-icon.png' }
};
export default function RootLayout({children}:{children:React.ReactNode}) {
  return <html><body>{children}</body></html>;
}
TSX
fi

# 2) Patch TopNav with brand logo (idempotent)
if [ -f "$TN" ]; then
  # ensure Link import
  if ! grep -q "from 'next/link'" "$TN"; then
    sed -i.bak "1s|^|import Link from 'next/link';\n|" "$TN" && rm -f "$TN.bak"
  fi
  # add className="topnav" to <nav ...> if missing
  if grep -q "<nav" "$TN" && ! grep -q "className=.*topnav" "$TN"; then
    perl -0777 -pe "s/<nav(?![^>]*className)/<nav className=\"topnav\"/s" "$TN" > "$TN.tmp" && mv "$TN.tmp" "$TN"
  fi
  # insert brand link as first child of <nav> if not present
  if ! grep -q "/brand/logo.svg" "$TN"; then
    awk '
      BEGIN{added=0}
      /<nav[^>]*>/ && added==0 {
        print;
        print "  <Link href=\"/\" className=\"brand\"><img src=\"/brand/logo.svg\" alt=\"Nudge2Edge\" /><span>Nudge2Edge</span></Link>";
        added=1; next
      }1' "$TN" > "$TN.tmp" && mv "$TN.tmp" "$TN"
  fi
else
  # create a simple TopNav if it doesn't exist
  mkdir -p "$COMP_DIR"
  cat > "$TN" <<'TSX'
import Link from 'next/link';
export default function TopNav(){
  return (
    <nav className="topnav">
      <Link href="/" className="brand">
        <img src="/brand/logo.svg" alt="Nudge2Edge" /><span>Nudge2Edge</span>
      </Link>
      <Link href="/courses">Courses</Link>
      <Link href="/tutor">Tutor</Link>
    </nav>
  );
}
TSX
fi

# 3) Build to validate
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 120 "$BUILD_LOG" || true; exit 2; }

# 4) Commit + PR
git config user.name "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$LAYOUT" "$TN"
git commit -m "feat(ui): brand logo in TopNav + metadata icons" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac
PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr create --head "$BR" --title "feat(ui): brand logo in TopNav + metadata icons" --body "Adds logo to TopNav (class \`topnav\`) and sets \`icons\` in layout metadata. Safe + idempotent.")" || true
fi

echo "=== CTO 18c2 NAV+ICONS SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "Files: $TN , $LAYOUT"
echo "=== CTO 18c2 NAV+ICONS SUMMARY END ==="
