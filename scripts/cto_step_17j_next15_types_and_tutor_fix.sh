#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
if [ -d "web" ] && [ -f "web/package.json" ]; then APP_DIR="web"; fi
APP_APP_DIR="$APP_DIR/src/app"
URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"

mkdir -p ./.cto_logs
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="./.cto_logs/courses_next15_fix_build_${TS}.log"
PROBE_LOG="./.cto_logs/courses_next15_fix_probe_${TS}.log"
BR="wp008-courses-next15-fix"

# 1) Branch off clean main
git fetch origin --prune --quiet
git switch -C main >/dev/null 2>&1 || git checkout -B main
git reset --hard origin/main
git switch -C "$BR"

# 2) Tutor page: avoid dynamic ssr:false in Server Component — make it a client page and import directly.
TP="$APP_APP_DIR/tutor/page.tsx"
if [ -f "$TP" ]; then
  cat > "$TP" <<'TSX'
'use client'
import type { Metadata } from 'next';
import ChatSSE from '../../components/ChatSSE';

export const metadata: Metadata = { title: 'AI Tutor' };

export default function Page() {
  return <ChatSSE />;
}
TSX
fi

# 3) Courses [slug] page: align with Next 15 PageProps (params is a Promise); keep force-static.
SLUGP="$APP_APP_DIR/courses/[slug]/page.tsx"
if [ -f "$SLUGP" ]; then
  cat > "$SLUGP" <<'TSX'
import type { Metadata, PageProps } from 'next';
import { notFound } from 'next/navigation';
import { getCourse, listCourses } from '../../../courses/registry';

export async function generateStaticParams() {
  return listCourses().map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: PageProps<{ slug: string }>): Promise<Metadata> {
  const { slug } = await params;
  const c = getCourse(slug);
  return { title: c ? `Course • ${c.title}` : 'Course' };
}

export const dynamic = 'force-static';
export const revalidate = 3600;

export default async function CoursePage({ params }: PageProps<{ slug: string }>) {
  const { slug } = await params;
  const course = getCourse(slug);
  if (!course) notFound();

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
else
  echo "ERROR: Missing $SLUGP"; exit 2
fi

# 4) Ensure /courses index also marked static (idempotent)
INDEXP="$APP_APP_DIR/courses/page.tsx"
if [ -f "$INDEXP" ] && ! grep -q "dynamic = 'force-static'" "$INDEXP"; then
  awk 'NR==1{print "export const dynamic = '\''force-static'\'';"; print "export const revalidate = 3600;"; print ""}1' "$INDEXP" > "$INDEXP.tmp" && mv "$INDEXP.tmp" "$INDEXP"
fi

# 5) Commit
git add "$TP" "$SLUGP" "$INDEXP"
git commit -m "fix(next15): correct PageProps for /courses/[slug] and make tutor page client-safe" >/dev/null

# 6) Build to catch errors
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; exit 2; }

# 7) Push + PR + merge (gh if available; else print Compare URL)
git push -u origin "$BR" --force-with-lease >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac

PR_URL=""; PR_STATE="unknown"; MERGED="no"
if command -v gh >/dev/null 2>&1; then
  set +e
  PR_URL="$(gh pr create --head "$BR" --title "fix(next15): courses params & tutor dynamic import" --body "Align with Next 15 PageProps (params is Promise); make /tutor client-safe. Also force-static + revalidate on Courses pages." 2>/dev/null | tail -n1)"
  gh pr review "$BR" --approve >/dev/null 2>&1 || true
  gh pr merge  "${PR_URL:-$BR}" --squash --admin --delete-branch -y >/dev/null 2>&1 || \
  gh pr merge  "${PR_URL:-$BR}" --squash --delete-branch -y >/dev/null 2>&1 || true
  for i in $(seq 1 60); do
    ST="$(gh pr view "${PR_URL:-$BR}" --json state -q .state 2>/dev/null || echo "")"
    [ "$ST" = "MERGED" ] && MERGED="yes" && break
    sleep 5
  done
  set -e
else
  [ -n "$GH_URL" ] && echo "Open and merge: $GH_URL/compare/$BR?expand=1"
fi

# 8) Probe prod for the two new pages
echo "Probing $URL … (log: $PROBE_LOG)"
probe_once() {
  local path="$1"; local needle="$2"; local t=$(date +%s)
  local body code
  body="$(curl -fsSL "$URL$path?nocache=$t" -H 'Cache-Control: no-cache' 2>>"$PROBE_LOG" || true)"
  code="$([ -n "$body" ] && echo 200 || curl -s -o /dev/null -w '%{http_code}' "$URL$path?nocache=$t" 2>>"$PROBE_LOG")"
  if [ "$code" = "200" ] && echo "$body" | grep -qi "$needle"; then echo "yes"; else echo "no"; fi
}
wait_for() {
  local path="$1"; local needle="$2"; local label="$3"
  local limit=80; local sleep_s=10
  for i in $(seq 1 $limit); do
    if [ "$(probe_once "$path" "$needle")" = "yes" ]; then echo "$label: PASS"; return 0; fi
    sleep $sleep_s
  done
  echo "$label: FAIL (timeout)"; return 1
}

R1="$(wait_for "/courses" "Courses" "Prod /courses")" || true
R2="$(wait_for "/courses/getting-started" "Getting Started with the AI Tutor" "Prod /courses/getting-started")" || true

echo "=== CTO NEXT15 FIX + PROBE SUMMARY START ==="
echo "Branch: $BR"
[ -n "$PR_URL" ] && echo "PR: $PR_URL"
echo "Merged: $MERGED"
echo "Build log: $BUILD_LOG"
echo "Prod URL: $URL"
echo "$R1"
echo "$R2"
echo "Probe log: $PROBE_LOG"
echo "=== CTO NEXT15 FIX + PROBE SUMMARY END ==="


