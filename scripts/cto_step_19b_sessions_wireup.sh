#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP_DIR="."
[ -d "web" ] && [ -f "web/package.json" ] && APP_DIR="web"
APP_APP_DIR="$APP_DIR/src/app"
COMP_DIR="$APP_DIR/src/components"
LIB_DIR="$APP_DIR/src/lib"
LOG_DIR="./.cto_logs"; mkdir -p "$LOG_DIR"
TS="$(date -u +%Y%m%d_%H%M%S)"
BUILD_LOG="$LOG_DIR/step19b_build_${TS}.log"
BR="wp019b-sessions-wireup-${TS}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need git || die "git not found"; need npm || die "npm not found"
[ -f "$APP_DIR/package.json" ] || die "Run from repo root (missing $APP_DIR/package.json)"

mkdir -p "$LIB_DIR" "$COMP_DIR" "$APP_APP_DIR/tutor" "$APP_APP_DIR/sessions" "$APP_APP_DIR/screens/[slug]"

# 1) Local sessions lib (localStorage)
cat > "$LIB_DIR/sessions.ts" <<'TS'
export type SavedSession = {
  id: string;
  title: string;
  createdAt: string; // ISO
  content: string;   // plain text / markdown-ish
};

const KEY = 'n2e_sessions_v1';

export function getSessions(): SavedSession[] {
  if (typeof window === 'undefined') return [];
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return [];
    const arr = JSON.parse(raw);
    if (!Array.isArray(arr)) return [];
    return arr as SavedSession[];
  } catch {
    return [];
  }
}

export function setSessions(list: SavedSession[]) {
  if (typeof window === 'undefined') return;
  localStorage.setItem(KEY, JSON.stringify(list));
}

export function addSession(partial: { title: string; content: string }): SavedSession {
  const now = new Date();
  const sess: SavedSession = {
    id: `${Date.now()}_${Math.random().toString(36).slice(2,8)}`,
    title: partial.title || `Session ${now.toISOString().slice(0,16).replace('T',' ')}`,
    createdAt: now.toISOString(),
    content: partial.content || ''
  };
  const list = getSessions();
  list.unshift(sess);
  setSessions(list);
  return sess;
}

export function deleteSession(id: string) {
  setSessions(getSessions().filter(s => s.id !== id));
}

export function exportMarkdown(sess: SavedSession): string {
  const dt = new Date(sess.createdAt).toLocaleString();
  return `# ${sess.title}\n\n_Date:_ ${dt}\n\n---\n\n${sess.content}\n`;
}

export function download(filename: string, text: string, mime = 'text/markdown') {
  const blob = new Blob([text], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename; a.style.display = 'none';
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
TS

# 2) SaveSession button (client)
cat > "$COMP_DIR/SaveSessionButton.tsx" <<'TSX'
'use client';
import { useState } from 'react';
import { addSession, exportMarkdown, download } from '../lib/sessions';

export default function SaveSessionButton() {
  const [status, setStatus] = useState<'idle'|'saved'|'error'>('idle');

  const handleSave = () => {
    try {
      const host = document.getElementById('tutor-output') || document.body;
      const text = (host?.textContent || '').trim();
      if (!text) { setStatus('error'); alert('Nothing to save yet. Try after the assistant replies.'); return; }
      const firstLine = text.split('\n').find(l => l.trim().length > 0)?.trim() || 'AI Tutor Session';
      const title = firstLine.slice(0, 80);
      const sess = addSession({ title, content: text });
      setStatus('saved');
      // Offer instant download too (non-blocking)
      const md = exportMarkdown(sess);
      download(`${title.replace(/\s+/g,'-').toLowerCase()}.md`, md);
      setTimeout(() => setStatus('idle'), 2000);
    } catch {
      setStatus('error');
    }
  };

  return (
    <button onClick={handleSave} style={{
      border: '1px solid #e5e7eb', borderRadius: 6, padding: '6px 10px', background: '#fff', cursor: 'pointer'
    }}>
      {status === 'idle' && 'Save Session'}
      {status === 'saved' && 'Saved ✓'}
      {status === 'error' && 'Try again'}
    </button>
  );
}
TSX

# 3) TutorShell client wrapper to host ChatSSE + Save button (and give ChatSSE a stable container)
cat > "$COMP_DIR/TutorShell.tsx" <<'TSX'
'use client';
import SaveSessionButton from './SaveSessionButton';
import ChatSSE from './ChatSSE';

export default function TutorShell() {
  return (
    <main style={{maxWidth: 960, margin: '24px auto', padding: '0 16px'}}>
      <header style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom: 12}}>
        <h1 style={{margin: 0, fontSize: 18}}>AI Tutor</h1>
        <SaveSessionButton />
      </header>
      <div id="tutor-output" style={{border:'1px solid #e5e7eb', borderRadius: 8, padding: 12}}>
        <ChatSSE />
      </div>
    </main>
  );
}
TSX

# 4) Patch Tutor page to render TutorShell (server page keeps metadata)
if [ -f "$APP_APP_DIR/tutor/page.tsx" ]; then
  mv "$APP_APP_DIR/tutor/page.tsx" "$APP_APP_DIR/tutor/page.tsx.bak.$TS"
fi
cat > "$APP_APP_DIR/tutor/page.tsx" <<'TSX'
import type { Metadata } from 'next';
import dynamic from 'next/dynamic';

export const metadata: Metadata = { title: 'AI Tutor' };

// Load client shell dynamically (SSR ok; it is a client component)
const TutorShell = dynamic(() => import('../../components/TutorShell'), { ssr: true });

export default function Page() {
  return <TutorShell />;
}
TSX

# 5) Sessions page (client) — list/export/delete/import
cat > "$APP_APP_DIR/sessions/page.tsx" <<'TSX'
'use client';
import { useEffect, useState } from 'react';
import { getSessions, deleteSession, exportMarkdown, download, type SavedSession } from '../../lib/sessions';
import Link from 'next/link';

export default function SessionsPage() {
  const [items, setItems] = useState<SavedSession[]>([]);

  const refresh = () => setItems(getSessions());
  useEffect(() => { refresh(); }, []);

  const onDelete = (id: string) => { deleteSession(id); refresh(); };
  const onExport = (s: SavedSession) => {
    const md = exportMarkdown(s);
    const name = `${s.title.replace(/\s+/g,'-').toLowerCase()}.md`;
    download(name, md);
  };
  const onImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]; if (!file) return;
    const text = await file.text();
    try {
      const data = JSON.parse(text);
      if (Array.isArray(data)) {
        // import list
        const existing = getSessions();
        localStorage.setItem('n2e_sessions_v1', JSON.stringify([...data, ...existing]));
      } else if (data && typeof data === 'object') {
        const existing = getSessions();
        localStorage.setItem('n2e_sessions_v1', JSON.stringify([data, ...existing]));
      }
      refresh();
    } catch {
      alert('Invalid JSON file');
    }
    e.currentTarget.value = '';
  };

  return (
    <main style={{maxWidth: 960, margin: '40px auto', padding: '0 16px'}}>
      <h1 style={{marginBottom: 12}}>Sessions</h1>
      <div style={{display:'flex', gap:12, alignItems:'center', marginBottom: 16}}>
        <label style={{fontSize:14, opacity:0.8, border:'1px solid #e5e7eb', padding:'6px 10px', borderRadius:6, cursor:'pointer'}}>
          Import JSON
          <input type="file" accept="application/json" onChange={onImport} style={{display:'none'}} />
        </label>
        <Link href="/tutor">Open Tutor →</Link>
      </div>
      {items.length === 0 ? (
        <p style={{opacity:0.8}}>No saved sessions yet. Open <Link href="/tutor">Tutor</Link>, get a reply, then use “Save Session”.</p>
      ) : (
        <table style={{width:'100%', borderCollapse:'collapse'}}>
          <thead>
            <tr style={{textAlign:'left'}}>
              <th style={{borderBottom:'1px solid #e5e7eb', padding:'8px'}}>Title</th>
              <th style={{borderBottom:'1px solid #e5e7eb', padding:'8px'}}>Created</th>
              <th style={{borderBottom:'1px solid #e5e7eb', padding:'8px'}}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.map(s => (
              <tr key={s.id}>
                <td style={{borderBottom:'1px solid #f1f5f9', padding:'8px'}}>{s.title}</td>
                <td style={{borderBottom:'1px solid #f1f5f9', padding:'8px'}}>{new Date(s.createdAt).toLocaleString()}</td>
                <td style={{borderBottom:'1px solid #f1f5f9', padding:'8px', display:'flex', gap:10}}>
                  <button onClick={() => onExport(s)} style={{border:'1px solid #e5e7eb', borderRadius:6, padding:'4px 8px', background:'#fff', cursor:'pointer'}}>Export .md</button>
                  <button onClick={() => onDelete(s.id)} style={{border:'1px solid #e5e7eb', borderRadius:6, padding:'4px 8px', background:'#fff', cursor:'pointer'}}>Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </main>
  );
}
TSX

# 6) /screens alias that re-exports __screens (keeps both routes working)
mkdir -p "$APP_APP_DIR/screens/[slug]"
cat > "$APP_APP_DIR/screens/page.tsx" <<'TSX'
export { metadata } from '../__screens/page';
export { default } from '../__screens/page';
TSX
cat > "$APP_APP_DIR/screens/[slug]/page.tsx" <<'TSX'
export { generateStaticParams, generateMetadata } from '../../__screens/[slug]/page';
export { default } from '../../__screens/[slug]/page';
TSX

# 7) Build to validate
echo "Building… (log: $BUILD_LOG)"
( cd "$APP_DIR" && npm run build ) >"$BUILD_LOG" 2>&1 || { echo "Build FAILED (see $BUILD_LOG)"; tail -n 160 "$BUILD_LOG" || true; exit 2; }

# 8) Commit & PR
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add "$LIB_DIR/sessions.ts" "$COMP_DIR/SaveSessionButton.tsx" "$COMP_DIR/TutorShell.tsx" \
        "$APP_APP_DIR/tutor/page.tsx" "$APP_APP_DIR/sessions/page.tsx" \
        "$APP_APP_DIR/screens/page.tsx" "$APP_APP_DIR/screens/[slug]/page.tsx"
git commit -m "feat(sessions): save/list/export/import (local) + /screens alias (Step 19b)" >/dev/null 2>&1 || true
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
  [ -z "$PR_URL" ] && PR_URL="$(gh pr create --head "$BR" --title "feat(sessions): local sessions + export/import; /screens alias" --body "Adds Save Session on Tutor, sessions list with export/import, and a /screens alias re-exporting __screens. Zero backend changes.")"
fi

echo "=== CTO 19b SESSIONS WIRE-UP SUMMARY START ==="
echo "App dir: $APP_DIR"
echo "Build: PASS (log: $BUILD_LOG)"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "Files:"
echo "  - $LIB_DIR/sessions.ts"
echo "  - $COMP_DIR/SaveSessionButton.tsx"
echo "  - $COMP_DIR/TutorShell.tsx"
echo "  - $APP_APP_DIR/tutor/page.tsx"
echo "  - $APP_APP_DIR/sessions/page.tsx"
echo "  - $APP_APP_DIR/screens/** (alias)"
echo "=== CTO 19b SESSIONS WIRE-UP SUMMARY END ==="
