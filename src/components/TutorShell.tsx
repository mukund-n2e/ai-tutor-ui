'use client';
import SaveSessionButton from './SaveSessionButton';
import ChatSSE from './ChatSSE';
export default function TutorShell() {
  return (
    <main style={{maxWidth: 960, margin:'24px auto', padding:'0 16px'}}>
      <header style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:12}}>
        <h1 style={{margin:0, fontSize:18}}>AI Tutor</h1>
        <SaveSessionButton />
      </header>
      <div id="tutor-output" style={{border:'1px solid #e5e7eb', borderRadius:8, padding:12}}>
        <ChatSSE />
      </div>
    </main>
  );
}

