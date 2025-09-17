export type SavedSession = {
  id: string;
  title: string;
  createdAt: string; // ISO
  content: string;   // plain text/markdown-ish
};
const KEY = 'n2e_sessions_v1';
export function getSessions(): SavedSession[] {
  if (typeof window === 'undefined') return [];
  try { const raw = localStorage.getItem(KEY); return raw ? JSON.parse(raw) : []; } catch { return []; }
}
export function setSessions(list: SavedSession[]) { if (typeof window !== 'undefined') localStorage.setItem(KEY, JSON.stringify(list)); }
export function addSession(partial: { title: string; content: string }): SavedSession {
  const now = new Date();
  const sess: SavedSession = {
    id: `${Date.now()}_${Math.random().toString(36).slice(2,8)}`,
    title: partial.title || `Session ${now.toISOString().slice(0,16).replace('T',' ')}`,
    createdAt: now.toISOString(),
    content: partial.content || ''
  };
  const list = getSessions(); list.unshift(sess); setSessions(list); return sess;
}
export function deleteSession(id: string) { setSessions(getSessions().filter(s => s.id !== id)); }
export function exportMarkdown(sess: SavedSession): string {
  const dt = new Date(sess.createdAt).toLocaleString();
  return `# ${sess.title}\n\n_Date:_ ${dt}\n\n---\n\n${sess.content}\n`;
}
export function download(filename: string, text: string, mime='text/markdown') {
  const blob = new Blob([text], { type: mime }); const url = URL.createObjectURL(blob);
  const a = document.createElement('a'); a.href = url; a.download = filename; a.style.display='none';
  document.body.appendChild(a); a.click(); document.body.removeChild(a); URL.revokeObjectURL(url);
}
