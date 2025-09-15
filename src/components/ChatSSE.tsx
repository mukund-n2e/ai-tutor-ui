'use client'
import React from 'react'

export default function ChatSSE() {
  const [input, setInput] = React.useState('')
  const [lines, setLines] = React.useState<string[]>([])
  const [streaming, setStreaming] = React.useState(false)
  const esRef = React.useRef<EventSource | null>(null)

  React.useEffect(() => {
    // Try to start a server session (best-effort; safe if no-op)
    fetch('/api/session/start', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }).catch(() => {})
    return () => { esRef.current?.close() }
  }, [])

  function send() {
    const q = input.trim()
    if (!q || streaming) return
    setInput('')
    setLines(prev => [...prev, `> ${q}`, '']) // reserve a slot for the streamed reply
    setStreaming(true)

    const es = new EventSource(`/api/tutor/stream?q=${encodeURIComponent(q)}`)
    esRef.current = es
    let acc = ''

    es.addEventListener('message', (evt) => {
      try {
        const data = JSON.parse((evt as MessageEvent).data)
        if (typeof data.delta === 'string') {
          acc += data.delta
          setLines(prev => {
            const copy = prev.slice()
            copy[copy.length - 1] = acc
            return copy
          })
        }
        if ((data.done as boolean) === true) {
          es.close()
          setStreaming(false)
        }
      } catch {
        // keepalive or non-JSON — ignore
      }
    })

    es.addEventListener('error', () => {
      es.close()
      setStreaming(false)
    })
  }

  return (
    <div style={{display:'grid', gridTemplateRows:'1fr auto', height:'calc(100vh - 100px)'}}>
      <div style={{padding:'12px', overflowY:'auto', whiteSpace:'pre-wrap', lineHeight:1.6, fontSize:16}}>
        {lines.map((l, i) => <div key={i} style={{margin:'8px 0'}}>{l}</div>)}
      </div>
      <form onSubmit={(e)=>{e.preventDefault(); send();}} style={{display:'flex', gap:8, padding:12, borderTop:'1px solid #eee'}}>
        <input
          value={input}
          onChange={e=>setInput(e.target.value)}
          placeholder="Ask the tutor…"
          autoFocus
          style={{flex:1, padding:'10px 12px', border:'1px solid #ddd', borderRadius:8}}
        />
        <button
          type="submit"
          disabled={streaming || !input.trim()}
          style={{padding:'10px 14px', border:'1px solid #111', borderRadius:8, background:'#111', color:'#fff'}}
        >
          {streaming ? 'Streaming…' : 'Send'}
        </button>
      </form>
    </div>
  )
}
