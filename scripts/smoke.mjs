const base = process.env.SMOKE_URL || 'http://localhost:3000';

const fetchJson = async (p) => (await fetch(base + p)).json();
const fetchHead = async (p) => {
  const res = await fetch(base + p, { method: 'GET' });
  return { ok: res.ok, headers: res.headers, status: res.status };
};

(async () => {
  const health = await fetchJson('/api/health');
  if (!health?.ok) throw new Error('Health failed');

  const { headers: h1, ok: ok1 } = await fetchHead('/');
  if (!ok1) throw new Error('Landing failed');
  const csp = h1.get('content-security-policy') || '';
  if (!csp.includes("frame-ancestors 'none'")) throw new Error('CSP missing frame-ancestors none');

  const { headers: hs, status } = await fetchHead('/api/tutor/stream?courseTitle=probe&scope=probe&message=hello');
  if (status !== 200) throw new Error('Stream route not reachable');
  const ct = hs.get('content-type') || '';
  const cc = hs.get('cache-control') || '';
  if (!ct.includes('text/event-stream')) throw new Error('SSE content-type missing');
  if (!cc.includes('no-transform')) throw new Error('SSE cache-control missing no-transform');

  console.log('SMOKE OK');
})().catch((e) => { console.error('SMOKE FAIL:', e.message); process.exit(1); });
