#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# --- Settings ---
APP_DIR="."
if [ -d "web" ] && [ -f "web/package.json" ]; then APP_DIR="web"; fi
APP_APP_DIR="$APP_DIR/src/app"
TN="$APP_DIR/src/components/TopNav.tsx"
NEW_BRANCH="wp008-courses-clean"
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }

need git || die "git not found"

ROOT="$(pwd)"
LOG_DIR="$ROOT/.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/courses_build_${TS}.log"
PROBE_LOG="$LOG_DIR/courses_prod_probe_${TS}.log"

echo "Using app dir: $APP_DIR (app root: $APP_APP_DIR)"

# --- Safety backup of current state ---
BACKUP="backup_pre_clean_${TS}"
git switch -c "$BACKUP" >/dev/null 2>&1 || git checkout -b "$BACKUP"
echo "Backup branch: $BACKUP"

# --- Fix ambiguous 'origin/main' (delete accidental local ref or tag) ---
if git show-ref --verify --quiet refs/heads/origin/main; then
  git branch -D origin/main
  echo "Removed stray local branch refs/heads/origin/main"
fi
if git show-ref --verify --quiet refs/tags/origin/main; then
  git tag -d origin/main
  echo "Removed stray tag refs/tags/origin/main"
fi
git fetch origin --prune --quiet

# --- Reset working copy to clean main ---
git switch -C main >/dev/null 2>&1 || git checkout -B main
git reset --hard origin/main
# Drop untracked junk so we don't accidentally add it
git clean -fdX  # respects .gitignore; we’ll hard-ignore .cto_logs below

# --- Ensure ignores so artifacts never get added ---
if [ -f .gitignore ]; then
  if ! grep -q "^.cto_logs/" .gitignore; then echo ".cto_logs/" >> .gitignore; fi
  if ! grep -q "^*.bak$" .gitignore; then echo "*.bak" >> .gitignore; fi
  if ! grep -q "^cto_.*\\.sh$" .gitignore; then echo "cto_*.sh" >> .gitignore; fi
else
  printf ".cto_logs/\n*.bak\ncto_*.sh\n" > .gitignore
fi

# --- New clean feature branch ---
git switch -C "$NEW_BRANCH"

# --- Create Courses scaffold (minimal) ---
mkdir -p "$APP_DIR/src/courses/samples" "$APP_APP_DIR/courses/[slug]"

cat > "$APP_DIR/src/courses/types.ts" <<'TS'
import type { ReactNode } from 'react';
export type Lesson = { slug: string; title: string; durationMin?: number; summary?: string; content: ReactNode; };
export type Course = { slug: string; title: string; level?: 'Beginner'|'Intermediate'|'Advanced'; estMinutes?: number; description?: string; lessons: Lesson[]; };
TS

cat > "$APP_DIR/src/courses/samples/getting-started.tsx" <<'TSX'
import type { Course } from '../types';
import { Fragment } from 'react';
const GettingStarted: Course = {
  slug: 'getting-started',
  title: 'Getting Started with the AI Tutor',
  level: 'Beginner',
  estMinutes: 25,
  description: 'From first prompt to first shipped result, with near‑zero cost.',
  lessons: [
    { slug: 'setup', title: 'Setup & First Run', durationMin: 10, summary: 'Local dev, health check, and your first prompt.',
      content: (
        <Fragment>
          <p><strong>Goal:</strong> have the app running and streaming.</p>
          <ol>
            <li>Open the app and confirm <code>/api/health</code> returns 200.</li>
            <li>Send a short prompt and watch SSE tokens arrive.</li>
            <li>Export the session to markdown.</li>
          </ol>
        </Fragment>
      )
    },
    { slug: 'ship', title: 'From Draft to Ship', durationMin: 15, summary: 'Short loop: draft → review → ship, with token caps.',
      content: (
        <Fragment>
          <p>Keep replies short. Prefer structured prompts. Use export to capture final output.</p>
          <ul>
            <li>Ask for bullets and headings.</li>
            <li>Ship small slices; avoid long rambles.</li>
          </ul>
        </Fragment>
      )
    }
  ],
};
export default GettingStarted;
TSX

cat > "$APP_DIR/src/courses/registry.tsx" <<'TSX'
import type { Course } from './types';
import GettingStarted from './samples/getting-started';
export const courses: Course[] = [GettingStarted];
export function listCourses() {
  return courses.map(c => ({ slug: c.slug, title: c.title, level: c.level, estMinutes: c.estMinutes, description: c.description, lessonsCount: c.lessons.length }));
}
export function getCourse(slug: string): Course | null {
  return courses.find(c => c.slug === slug) ?? null;
}
TSX

cat > "$APP_APP_DIR/courses/page.tsx" <<'TSX'
import Link from 'next/link';
import { listCourses } from '../../courses/registry';
export const metadata = { title: 'Courses' };
export default function CoursesPage() {
  const items = listCourses();
  return (
    <main style={{maxWidth: 960, margin: '40px auto', padding: '0 16px'}}>
      <h1 style={{marginBottom: 16}}>Courses</h1>
      <p style={{opacity: 0.8, marginBottom: 24}}>Structured paths to ship faster. Zero LLM spend on these pages.</p>
      <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 16}}>
        {items.map(c => (
          <article key={c.slug} style={{border: '1px solid #e5e7eb', borderRadius: 8, padding: 16}}>
            <h2 style={{marginTop: 0, marginBottom: 8}}>{c.title}</h2>
            <p style={{marginTop: 0, marginBottom: 8, opacity: 0.9}}>{c.description}</p>
            <div style={{fontSize: 14, opacity: 0.8, marginBottom: 12}}>
              {c.level ?? 'Unrated'} • ~{c.estMinutes ?? 20} min • {c.lessonsCount} lessons
            </div>
            <Link href={`/courses/${c.slug}`}>Open course →</Link>
          </article>
        ))}
      </div>
    </main>
  );
}
TSX

cat > "$APP_APP_DIR/courses/[slug]/page.tsx" <<'TSX'
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getCourse, listCourses } from '../../../courses/registry';
type Params = { params: { slug: string } };
export async function generateStaticParams() { return listCourses().map(c => ({ slug: c.slug })); }
export function generateMetadata({ params }: Params): Metadata {
  const c = getCourse(params.slug); return c ? { title: `Course • ${c.title}` } : { title: 'Course' };
}
export default function CoursePage({ params }: Params) {
  const course = getCourse(params.slug);
  if (!course) return notFound();
  return (
    <main style={{maxWidth: 960, margin: '40px auto', padding: '0 16px'}}>
      <header style={{marginBottom: 24}}>
        <h1 style={{margin: 0}}>{course.title}</h1>
        <div style={{fontSize: 14, opacity: 0.8}}>
          {course.level ?? 'Unrated'} • ~{course.estMinutes ?? 20} min • {course.lessons.length} lessons
        </div>
        {course.description && <p style={{marginTop: 12}}>{course.description}</p>}
      </header>
      <ol style={{paddingLeft: 20}}>
        {course.lessons.map((l, i) => (
          <li key={l.slug} style={{marginBottom: 16}}>
            <h3 style={{marginBottom: 6}}>{i + 1}. {l.title}</h3>
            {l.summary && <p style={{marginTop: 0, opacity: 0.9}}>{l.summary}</p>}
            <section style={{borderLeft: '3px solid #e5e7eb', paddingLeft: 12}}>
              {l.content}
            </section>
            {l.durationMin && <div style={{fontSize: 12, opacity: 0.8, marginTop: 6}}>~{l.durationMin} min</div>}
          </li>
        ))}
      </ol>
    </main>
  );
}
TSX

# --- Add Courses to TopNav via links[] (idempotent) ---
if [ -f "$TN" ]; then
  # Keep 'use client' at top and ensure Link import
  if ! grep -q "from 'next/link'" "$TN"; then
    if head -n1 "$TN" | grep -qE "^(\"use client\"|'use client');?$"; then
      awk 'NR==1{print; print "import Link from '\''next/link'\'';"; next}1' "$TN" > "$TN.tmp" && mv "$TN.tmp" "$TN"
    else
      awk 'BEGIN{done=0} {if(!done){print "import Link from '\''next/link'\'';"; done=1} print}' "$TN" > "$TN.tmp" && mv "$TN.tmp" "$TN"
    fi
  fi
  # If links[] exists, add Courses entry once
  if grep -q "const[[:space:]]\+links[[:space:]]*=" "$TN"; then
    if ! grep -q "href:[[:space:]]*'/courses'" "$TN"; then
      awk -v added=0 '
        /const[[:space:]]+links[[:space:]]*=[[:space:]]*\[/ { inlinks=1 }
        inlinks && /^\][[:space:]]*;/ {
          print "  { href: \x27/courses\x27, label: \x27Courses\x27 },"
          inlinks=0; added=1
        }
        { print }
      ' "$TN" > "$TN.tmp" && mv "$TN.tmp" "$TN"
    fi
  else
    # Fallback: inject a simple link before </nav>
    if grep -q "</nav>" "$TN"; then
      awk '{if($0 ~ /<\/nav>/){print "      <Link href=\"/courses\">Courses</Link>"} print}' "$TN" > "$TN.tmp" && mv "$TN.tmp" "$TN"
    fi
  fi
fi

# --- Normalize commit author to GitHub-recognized email (prefer noreply) ---
AUTHOR_NAME="$(git config user.name || true)"
AUTHOR_EMAIL="$(git config user.email || true)"
if need gh; then
  GH_LOGIN="$(gh api user -q .login 2>/dev/null || echo "")"
  GH_ID="$(gh api user -q .id 2>/dev/null || echo "")"
  GH_NAME="$(gh api user -q .name 2>/dev/null || echo "$GH_LOGIN")"
  if [ -n "$GH_LOGIN" ] && [ -n "$GH_ID" ]; then
    AUTHOR_NAME="${AUTHOR_NAME:-$GH_NAME}"
    AUTHOR_EMAIL="${AUTHOR_EMAIL:-${GH_ID}+${GH_LOGIN}@users.noreply.github.com}"
  fi
fi
[ -n "${COMMIT_NAME:-}" ] && AUTHOR_NAME="$COMMIT_NAME"
[ -n "${COMMIT_EMAIL:-}" ] && AUTHOR_EMAIL="$COMMIT_EMAIL"
[ -z "$AUTHOR_EMAIL" ] && die "Set COMMIT_EMAIL to your verified GitHub email or noreply (id+login@users.noreply.github.com)"

git config user.name "$AUTHOR_NAME"
git config user.email "$AUTHOR_EMAIL"
git config --global user.name "$AUTHOR_NAME" || true
git config --global user.email "$AUTHOR_EMAIL" || true

# --- Commit ONLY courses + nav + .gitignore ---
git add .gitignore "$APP_DIR/src/courses" "$APP_APP_DIR/courses" "$TN" 2>/dev/null || true
git commit -m "feat(courses): minimal scaffold + nav link (clean PR)"

# --- Build to catch type errors ---
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; exit 2; }

# --- Push branch and PR/merge ---
git push -u origin "$NEW_BRANCH" --force-with-lease

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac
COMPARE="${GH_URL:+$GH_URL/compare/$NEW_BRANCH?expand=1}"
PR_URL=""; PR_STATE="unknown"; MERGE_MODE="skipped"

if need gh; then
  set +e
  PR_URL="$(gh pr create --head "$NEW_BRANCH" --title "feat(courses): minimal scaffold + nav link (clean PR)" --body "Replaces prior bulky PR with minimal diff; author normalized; resolves ambiguous origin/main." --fill 2>/dev/null | tail -n1)"
  gh pr review "$NEW_BRANCH" --approve >/dev/null 2>&1 || true
  gh pr merge  "$NEW_BRANCH" --squash --admin --delete-branch >/dev/null 2>&1 || \
  gh pr merge  "$NEW_BRANCH" --squash --delete-branch >/dev/null 2>&1 || true
  MERGE_MODE="attempted"
  for i in $(seq 1 60); do
    ST="$(gh pr view "$NEW_BRANCH" --json state -q .state 2>/dev/null || echo "")"
    [ "$ST" = "MERGED" ] && PR_STATE="MERGED" && break
    sleep 5
  done
fi

# --- Probe production with cache-busting ---
echo "Probing production at $PROD_URL ..." | tee "$PROBE_LOG"
probe_once() {
  local path="$1"; local expect="$2"; local t="$(date +%s)"
  local url="${PROD_URL}${path}?nocache=${t}"
  local body code
  body="$(curl -fsSL "$url" -H 'Cache-Control: no-cache' 2>>"$PROBE_LOG" || true)"
  code="$([ -n "$body" ] && echo 200 || curl -s -o /dev/null -w '%{http_code}' "$url" 2>>"$PROBE_LOG")"
  if [ "$code" = "200" ] && echo "$body" | grep -qi "$expect"; then echo "yes"; else echo "no"; fi
}
wait_for() {
  local path="$1"; local expect="$2"; local label="$3"
  local limit=80; local sleep_s=10
  for i in $(seq 1 $limit); do
    if [ "$(probe_once "$path" "$expect")" = "yes" ]; then echo "$label: PASS"; return 0; fi
    sleep $sleep_s
  done
  echo "$label: FAIL (timeout)"; return 1
}
R1="$(wait_for "/courses" "Courses" "Prod /courses")" || true
R2="$(wait_for "/courses/getting-started" "Getting Started with the AI Tutor" "Prod /courses/getting-started")" || true

echo "=== CTO COURSES CLEAN REPR SUMMARY START ==="
echo "New branch: $NEW_BRANCH"
[ -n "$GH_URL" ] && echo "Repo: $GH_URL"
[ -n "$COMPARE" ] && echo "Compare: $COMPARE"
[ -n "$PR_URL" ] && echo "PR: $PR_URL"
echo "PR state: $PR_STATE"
echo "Merge: $MERGE_MODE"
echo "Prod URL: $PROD_URL"
echo "$R1"
echo "$R2"
echo "Build log: $BUILD_LOG"
echo "Probe log: $PROBE_LOG"
echo "Backup branch: $BACKUP"
echo "=== CTO COURSES CLEAN REPR SUMMARY END ==="


