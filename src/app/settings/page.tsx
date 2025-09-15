import TopNav from '../../components/TopNav'
export const metadata = { title: 'Settings' }
export default function Page() {
  return (
    <main>
      <TopNav />
      <section style={{padding:'16px'}}>
        <h1 style={{margin:'0 0 12px 0'}}>Settings</h1>
        <p style={{maxWidth:680,lineHeight:1.6}}>Screen stub. Next: runtime flags (model, token caps), analytics opt-in, and export options.</p>
      </section>
    </main>
  )
}
