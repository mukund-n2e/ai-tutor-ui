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
      const first = text.split('\n').find(l => l.trim().length > 0)?.trim() || 'AI Tutor Session';
      const title = first.slice(0,80);
      const sess = addSession({ title, content: text });
      setStatus('saved');
      const md = exportMarkdown(sess);
      download(`${title.replace(/\s+/g,'-').toLowerCase()}.md`, md);
      setTimeout(() => setStatus('idle'), 1500);
    } catch { setStatus('error'); }
  };
  return (
    <button onClick={handleSave}
      style={{border:'1px solid #e5e7eb', borderRadius:6, padding:'6px 10px', background:'#fff', cursor:'pointer'}}>
      {status==='idle' && 'Save Session'}
      {status==='saved' && 'Saved ✓'}
      {status==='error' && 'Try again'}
    </button>
  );
}
