export type AskArgs = { scope: string; courseTitle: string; message: string };

export async function askSSE({ scope, courseTitle, message }: AskArgs, onDelta: (t: string)=>void){
  return new Promise<void>((resolve) => {
    const url = `/api/tutor/stream?scope=${encodeURIComponent(scope)}&courseTitle=${encodeURIComponent(courseTitle)}&message=${encodeURIComponent(message)}`;
    const es = new EventSource(url);
    es.onmessage = (e) => { try { const { delta } = JSON.parse(e.data); if (delta) onDelta(delta); } catch {} };
    es.addEventListener('done', () => { es.close(); resolve(); });
    es.addEventListener('error', () => { es.close(); resolve(); });
  });
}

export async function askWS({ scope, courseTitle, message }: AskArgs, onDelta: (t: string)=>void){
  return new Promise<void>((resolve, reject) => {
    const wsUrl = process.env.NEXT_PUBLIC_WS_URL as string | undefined;
    if (!wsUrl) return reject(new Error('WS URL missing'));
    const ws = new WebSocket(wsUrl);
    ws.onopen = () => {
      ws.send(JSON.stringify({ action: 'msg', data: { scope, courseTitle, message } }));
    };
    ws.onmessage = (ev) => {
      try { const obj = JSON.parse(String(ev.data)); if (obj.delta) onDelta(obj.delta); if (obj.event === 'done') { ws.close(); resolve(); } } catch {}
    };
    ws.onerror = () => { ws.close(); resolve(); };
  });
}


