'use client';
import { useEffect, useMemo, useState } from 'react';
import { sanitizeFilenameFriendly } from '@/lib/strings';

export default function ShipPage() {
  const [title, setTitle] = useState('Quick‑win draft');
  const [body, setBody] = useState('# Paste or type your content here…');
  const [busy, setBusy] = useState(false);
  // Prepopulate from localStorage if Quick‑win saved a draft previously
  useEffect(() => {
    try {
      const t = localStorage.getItem('ai_ship_title');
      const b = localStorage.getItem('ai_ship_body');
      if (t) setTitle(t);
      if (b) setBody(b);
    } catch {}
  }, []);
  useEffect(() => {
    try { localStorage.setItem('ai_ship_title', title); } catch {}
  }, [title]);
  useEffect(() => {
    try { localStorage.setItem('ai_ship_body', body); } catch {}
  }, [body]);
  const computedFilename = useMemo(() => `${sanitizeFilenameFriendly(title)}.md`, [title]);
  async function ship() {
    setBusy(true);
    try {
      const res = await fetch('/api/export', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, body }),
      });
      if (!res.ok) throw new Error('export failed');
      const blob = await res.blob();
      const disp = res.headers.get('Content-Disposition') || '';
      const m = /filename="([^"]+)"/.exec(disp);
      const filename = (m && m[1]) || computedFilename;
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url; a.download = filename;
      document.body.appendChild(a); a.click(); a.remove();
      URL.revokeObjectURL(url);
    } finally {
      setBusy(false);
    }
  }
  return (
    <main className="p-6 space-y-4">
      <h1 className="text-2xl font-semibold">Ship (.md) — minimal</h1>
      <input data-testid="ship-title" className="border p-2 w-full" value={title} onChange={e=>setTitle(e.target.value)} />
      <textarea data-testid="ship-body" className="border p-2 w-full h-64" value={body} onChange={e=>setBody(e.target.value)} />
      <div className="text-xs text-gray-600">Filename: {computedFilename}</div>
      <button data-testid="ship-md" onClick={ship} disabled={busy} className="px-4 py-2 border">
        {busy ? 'Preparing…' : 'Download .md'}
      </button>
      <p className="text-sm text-gray-500">We’ll wire this to your live draft in /quick-win next.</p>
    </main>
  );
}


