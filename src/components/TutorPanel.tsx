'use client';
import { useState } from 'react';
import { askSSE, askWS } from '@/lib/tutorTransport';

export function TutorPanel({ scope, courseTitle }: { scope: string; courseTitle: string }){
  const [text, setText] = useState('');
  const [stream, setStream] = useState('');
  const [busy, setBusy] = useState(false);
  const transport = (process.env.NEXT_PUBLIC_TUTOR_TRANSPORT || 'sse').toLowerCase();

  const ask = async () => {
    setBusy(true); setStream('');
    const onDelta = (t: string) => setStream((s) => s + t);
    if (transport === 'ws') await askWS({ scope, courseTitle, message: text }, onDelta);
    else await askSSE({ scope, courseTitle, message: text }, onDelta);
    setBusy(false);
  };

  return (
    <div className="border rounded p-3">
      <textarea value={text} onChange={e=>setText(e.target.value)} placeholder={`Ask within scope… (${transport.toUpperCase()})`} className="w-full border p-2 rounded" />
      <button disabled={busy} onClick={ask} className="mt-2 px-3 py-1 border rounded">{busy ? 'Thinking…' : 'Ask'}</button>
      <pre className="mt-3 whitespace-pre-wrap">{stream}</pre>
    </div>
  );
}


