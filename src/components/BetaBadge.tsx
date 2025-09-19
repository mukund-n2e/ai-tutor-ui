
export default function BetaBadge() {
  return (
    <div data-ssr-beta="true" style={{
      position:'fixed', top:12, right:12, zIndex:1000,
      padding:'6px 10px', borderRadius:999,
      background:'#fff7ed', color:'#9a3412',
      border:'1px solid #fed7aa', fontSize:12, fontWeight:600,
      boxShadow:'0 1px 2px rgba(0,0,0,0.06)'
    }}>
      BETA
    </div>
  );
}
