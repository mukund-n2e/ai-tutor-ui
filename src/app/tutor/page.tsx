import TopNav from '../../components/TopNav'
import dynamic from 'next/dynamic'

export const metadata = { title: 'AI Tutor' }
const ChatSSE = dynamic(() => import('../../components/ChatSSE'), { ssr: false })

export default function Page() {
  return (
    <main>
      <TopNav />
      <ChatSSE />
    </main>
  )
}
