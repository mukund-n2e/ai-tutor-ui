'use client';
import { useEffect, useState } from 'react';
import { getSessions, deleteSession, exportMarkdown, download, type SavedSession } from '../../lib/sessions';
import Link from 'next/link';

export default function SessionsPage() {
  const [items, setItems] = useState<SavedSession[]>([]);
  const refresh = () => setItems(getSessions());
  useEffect(() => { refresh(); }, []);
  const onDelete = (id: string) => { deleteSession(id); refresh(); };
  const onExport = (s: SavedSession) => { const md = exportMarkdown(s); const name = `${s.title.replace(/\s+/g,'-').toLowerCase()}.md`; download(name, md); };
  const onImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]; if (!file) return;
    const text = await file.text();
    try {
      const data = JSON.parse(text);
      const existing = getSessions();
      if (Array.isArray(data)) localStorage.setItem('n2e_sessions_v1', JSON.stringify([...data, ...existing]));
      else if (data && typeof data === 'object') localStorage.setItem('n2e_sessions_v1', JSON.stringify([data, ...existing]));
      refresh();
    } catch { alert('Invalid JSON'); }
    e.currentTarget.value = '';
  };
  return (
    <main style={{maxWidth:960, margin:'40px auto', padding:'0 16px'}}>
      <h1 style={{marginBottom:12}}>Sessions</h1>
      <div style={{display:'flex', gap:12, alignItems:'center', marginBottom:16}}>
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
          <thead><tr style={{textAlign:'left'}}>
            <th style={{borderBottom:'1px solid #e5e7eb', padding:'8px'}}>Title</th>
            <th style={{borderBottom:'1px solid #e5e7eb', padding:'8px'}}>Created</th>
            <th style={{borderBottom:'1px solid #e5e7eb', padding:'8px'}}>Actions</th>
          </tr></thead>
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
